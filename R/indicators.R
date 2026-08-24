
## Main function ---------------------------------------------------------------

#' Centre of gravity from survey data
#'
#' Computes the CPUE-weighted centre of gravity (CoG) from a `datras_raw`
#' object for each level of the `by` grouping (typically `"Year"`).
#'
#' @param x A `datras_raw` object. `HH` must contain `value_var`, `lat_var`,
#'   and `lon_var`.
#' @param value_var Name of the `HH` column used as CPUE weights. Default
#'   `"HaulN"` (added by [add_total_numbers_by_haul()]). May be a numeric
#'   vector or a matrix; in the latter case one set of indicators is computed
#'   per column.
#' @param cpue_method Standardisation applied to `value_var` before weighting:
#'   `"per_swept_area"` (per km^2; requires `SweptArea`), `"per_hour"` (per
#'   hour; uses `HaulDur`), or `"count"` (raw totals). Default
#'   `"per_swept_area"`.
#' @param by Character vector of `HH` columns used to define groups (e.g.
#'   `"Year"`, `c("Year","Quarter")`). Default `"Year"`.
#' @param lat_var,lon_var Names of the latitude and longitude columns in `HH`.
#'   Defaults `"lat"` and `"lon"` (added by [clean_datras()]).
#'
#' @return A data frame with one row per `by`-group x length-group and columns:
#'   the `by` columns, `group`, `cpue_method`, `n_hauls`, `cog_lat`, `cog_lon`.
#'
#' @details
#' The centre of gravity is the CPUE-weighted mean position:
#' \deqn{\text{CoG}_\text{lat} = \frac{\sum_i w_i \phi_i}{\sum_i w_i},\quad
#'       \text{CoG}_\text{lon} = \frac{\sum_i w_i \lambda_i}{\sum_i w_i}}
#' where \eqn{w_i} is the CPUE at haul \eqn{i}. Hauls with zero or missing
#' CPUE contribute to `n_hauls` but not to the weighted sums.
#'
#' @seealso [add_total_numbers_by_haul()], [add_swept_area()],
#'   [calc_stratified_index()], [plot_spatial_indicators()]
#' @examples
#' \dontrun{
#' data(dab)
#' dab <- add_swept_area(dab)
#' dab <- add_total_numbers_by_haul(dab)
#' calc_spatial_indicators(dab, by = "Year")
#'
#' ## length-group CoG
#' dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 15, Inf))
#' calc_spatial_indicators(dab, by = "Year")
#' }
#' @export
calc_spatial_indicators <- function(x,
                                    value_var = "HaulN",
                                    cpue_method = c("per_swept_area", "per_hour", "count"),
                                    by = "Year",
                                    lat_var = "lat",
                                    lon_var = "lon") {
  .check_class_datras(x)
  cpue_method <- match.arg(cpue_method)

  hh <- as.data.frame(x[["HH"]], stringsAsFactors = FALSE)

  ## --- validate columns -------------------------------------------------------
  if (!(value_var %in% names(hh)))
    stop("`value_var` column '", value_var, "' not found in HH. ",
         "Run `add_total_numbers_by_haul()` first.", call. = FALSE)
  if (!(lat_var %in% names(hh)))
    stop("`lat_var` column '", lat_var, "' not found in HH.", call. = FALSE)
  if (!(lon_var %in% names(hh)))
    stop("`lon_var` column '", lon_var, "' not found in HH.", call. = FALSE)

  if (!is.null(by)) {
    miss_by <- setdiff(by, names(hh))
    if (length(miss_by) > 0)
      stop("`by` column(s) not found in HH: ",
           paste(miss_by, collapse = ", "), call. = FALSE)
  }

  cpue_col <- switch(cpue_method,
    per_swept_area = "SweptArea",
    per_hour = "HaulDur",
    count = NULL
  )
  if (!is.null(cpue_col) && !(cpue_col %in% names(hh))) {
    if (identical(cpue_method, "per_swept_area"))
      stop("`cpue_method = 'per_swept_area'` requires `SweptArea` in HH. ",
           "Run `add_swept_area()` first.", call. = FALSE)
    stop("`cpue_method = 'per_hour'` requires `HaulDur` in HH.", call. = FALSE)
  }

  ## --- unpack value column ----------------------------------------------------
  raw_val <- hh[[value_var]]
  if (is.matrix(raw_val)) {
    grp_names <- colnames(raw_val)
    if (is.null(grp_names))
      grp_names <- paste0(value_var, "_", seq_len(ncol(raw_val)))
    val_list <- lapply(seq_len(ncol(raw_val)), function(j) raw_val[, j])
    names(val_list) <- grp_names
  } else {
    val_list <- list(as.numeric(raw_val))
    names(val_list) <- value_var
  }

  ## --- build working subset ---------------------------------------------------
  hh_cols <- unique(c(lat_var, lon_var, by, cpue_col))
  hh_sub <- hh[, hh_cols, drop = FALSE]

  lat_vals <- suppressWarnings(as.numeric(as.character(hh_sub[[lat_var]])))
  lon_vals <- suppressWarnings(as.numeric(as.character(hh_sub[[lon_var]])))

  ## --- by-group index ---------------------------------------------------------
  if (is.null(by) || length(by) == 0L) {
    by_groups_idx <- list(ALL = seq_len(nrow(hh_sub)))
    by_vals_list <- list(list())
  } else {
    by_key <- .make_composite_key(hh_sub, by)
    by_groups_idx <- split(seq_len(nrow(hh_sub)), by_key, drop = TRUE)
    by_vals_list <- lapply(by_groups_idx, function(idx) {
      as.list(hh_sub[idx[1L], by, drop = FALSE])
    })
  }

  ## --- loop over value groups -------------------------------------------------
  results_list <- vector("list", length(val_list))

  for (vi in seq_along(val_list)) {
    grp_name <- names(val_list)[vi]
    raw_cpue <- switch(cpue_method,
      per_swept_area = val_list[[vi]] /
        (suppressWarnings(as.numeric(as.character(hh_sub[[cpue_col]]))) * 1e-6),
      per_hour = val_list[[vi]] /
        (suppressWarnings(as.numeric(as.character(hh_sub[[cpue_col]]))) / 60),
      count = val_list[[vi]]
    )

    group_rows <- vector("list", length(by_groups_idx))
    for (gi in seq_along(by_groups_idx)) {
      idx <- by_groups_idx[[gi]]
      res <- .spatial_indicators_one(
        cpue = raw_cpue[idx],
        lat = lat_vals[idx],
        lon = lon_vals[idx]
      )

      group_rows[[gi]] <- c(
        by_vals_list[[gi]],
        list(group = grp_name,
             cpue_method = cpue_method,
             n_hauls = res$n_hauls,
             cog_lat = res$cog_lat,
             cog_lon = res$cog_lon)
      )
    }
    results_list[[vi]] <- group_rows
  }

  ## --- assemble output --------------------------------------------------------
  all_rows <- Filter(Negate(is.null), do.call(c, results_list))
  if (length(all_rows) == 0L) return(data.frame(stringsAsFactors = FALSE))
  out <- do.call(rbind, lapply(all_rows, as.data.frame, stringsAsFactors = FALSE))
  rownames(out) <- NULL
  out <- .restore_numeric_cols(out, by)
  out
}


## Plotting --------------------------------------------------------------------

#' Plot spatial indicators
#'
#' Plots the output of [calc_spatial_indicators()] as time-series panels, one
#' panel per indicator variable. When the input contains multiple length groups,
#' all groups are overlaid as coloured lines within each panel.
#'
#' @param x Data frame returned by [calc_spatial_indicators()].
#' @param vars Character vector of column names to plot. Defaults to all
#'   indicator columns detected in `x` (`cog_lat` and `cog_lon`).
#' @param x_var Name of the x-axis column. Defaults to `"Year"` if present,
#'   otherwise the first non-result column.
#' @param col Character vector of colours, one per unique `group`. Defaults to
#'   the DATRASextra discrete palette.
#' @param lwd Line width. Default `2`.
#' @param pch Integer vector of point symbols, one per unique `group`. If
#'   `NULL` (default), a built-in sequence of distinct symbols is used.
#' @param legend Logical; draw a legend for group colours. Default `TRUE`;
#'   suppressed automatically when there is only one group.
#' @param legend_pos Legend position string passed to [graphics::legend()].
#'   Default `"topright"`.
#' @param layout Logical; when `TRUE` (default) and there are multiple
#'   indicator panels, the function sets `par(mfrow)` automatically and
#'   restores it on exit. Set to `FALSE` to draw panels sequentially into the
#'   caller's current layout -- useful when combining with other plots via
#'   `par(mfrow = ...)`.
#' @param xlim Optional x-axis limits.
#' @param main Optional overall title prefix. If multiple panels are drawn, the
#'   indicator name is appended.
#'
#' @return Invisibly returns `x`.
#' @seealso [calc_spatial_indicators()]
#' @examples
#' \dontrun{
#' data(dab)
#' dab <- add_swept_area(dab)
#' dab <- add_total_numbers_by_haul(dab)
#' res <- calc_spatial_indicators(dab, by = "Year")
#' plot_spatial_indicators(res)
#' plot_spatial_indicators(res, vars = "cog_lat")
#' }
#' @export
plot_spatial_indicators <- function(x,
                                    vars = NULL,
                                    x_var = NULL,
                                    col = NULL,
                                    lwd = 2,
                                    pch = NULL,
                                    legend = TRUE,
                                    legend_pos = "topright",
                                    layout = TRUE,
                                    xlim = NULL,
                                    main = NULL) {
  if (!is.data.frame(x))
    stop("`x` must be a data frame returned by `calc_spatial_indicators()`.",
         call. = FALSE)

  ## --- detect x_var ----------------------------------------------------------
  meta_cols <- c("group", "cpue_method", "n_hauls", "cog_lat", "cog_lon")
  indicator_cols <- intersect(c("cog_lat", "cog_lon"), names(x))

  if (is.null(x_var)) {
    if ("Year" %in% names(x)) {
      x_var <- "Year"
    } else {
      candidates <- setdiff(names(x), meta_cols)
      if (length(candidates) == 0)
        stop("Could not auto-detect x-axis variable. Set `x_var`.", call. = FALSE)
      x_var <- candidates[1]
      message("Using '", x_var, "' as x-axis variable.")
    }
  }

  ## --- vars to plot ----------------------------------------------------------
  if (is.null(vars)) {
    vars <- indicator_cols
  } else {
    miss <- setdiff(vars, names(x))
    if (length(miss) > 0)
      stop("Column(s) not found in `x`: ", paste(miss, collapse = ", "),
           call. = FALSE)
  }
  if (length(vars) == 0)
    stop("No indicator variables to plot.", call. = FALSE)

  ## --- groups ----------------------------------------------------------------
  group_levels <- unique(as.character(x$group))
  n_groups <- length(group_levels)

  if (is.null(col))
    col <- .colours_datrasextra_discrete(n_groups)
  col <- rep_len(col, n_groups)
  names(col) <- group_levels

  pch_default <- c(16L, 17L, 15L, 18L, 1L, 2L, 0L, 5L)
  if (is.null(pch)) pch <- pch_default
  pch <- rep_len(pch, n_groups)
  names(pch) <- group_levels

  ## --- layout ----------------------------------------------------------------
  n_panels <- length(vars)
  if (n_panels > 1 && isTRUE(layout)) {
    old_par <- par(no.readonly = TRUE)
    on.exit(par(old_par), add = TRUE)
    par(mfrow = grDevices::n2mfrow(n_panels), mar = c(4.2, 4.8, 2, 1))
  } else {
    par(mar = c(4.2, 4.8, 2, 1))
  }

  ## --- y-axis label lookup ---------------------------------------------------
  ylab_map <- c(
    cog_lat = "CoG latitude (\u00b0N)",
    cog_lon = "CoG longitude (\u00b0E)"
  )

  ## --- x-axis type: numeric values get lines; categorical x gets points ------
  xall <- suppressWarnings(as.numeric(as.character(x[[x_var]])))
  x_is_numeric <- !any(is.na(xall) & !is.na(x[[x_var]]))
  if (x_is_numeric) {
    xlim_use <- if (!is.null(xlim)) xlim else range(xall, na.rm = TRUE) + c(-0.5, 0.5)
    x_levels <- NULL
  } else {
    x_levels <- if (is.factor(x[[x_var]])) levels(x[[x_var]]) else sort(unique(as.character(x[[x_var]])))
    xlim_use <- if (!is.null(xlim)) xlim else c(0.5, length(x_levels) + 0.5)
  }

  ## --- draw panels -----------------------------------------------------------
  for (pi in seq_along(vars)) {
    var <- vars[pi]

    yvals_all <- suppressWarnings(as.numeric(x[[var]]))
    yr <- range(yvals_all[is.finite(yvals_all)])
    if (!is.finite(yr[1])) yr <- c(0, 1)
    if (diff(yr) == 0) yr <- yr + c(-1, 1)
    pad <- diff(yr) * 0.05
    ylim_use <- yr + c(-pad, pad)

    ylab <- if (var %in% names(ylab_map)) ylab_map[[var]] else var

    panel_title <- if (!is.null(main)) {
      if (n_panels > 1) paste0(main, " \u2014 ", ylab) else main
    } else if (n_panels > 1) {
      ylab
    } else {
      ""
    }

    plot(NA,
         xlim = xlim_use,
         ylim = ylim_use,
         xlab = x_var,
         ylab = ylab,
         main = panel_title,
         las = 1,
         xaxt = if (x_is_numeric) "s" else "n")
    if (!x_is_numeric)
      axis(1, at = seq_along(x_levels), labels = x_levels)

    for (gi in seq_along(group_levels)) {
      grp <- group_levels[gi]
      sub <- x[as.character(x$group) == grp, , drop = FALSE]
      if (x_is_numeric) {
        xvals <- suppressWarnings(as.numeric(as.character(sub[[x_var]])))
        ord <- order(xvals)
        sub <- sub[ord, , drop = FALSE]
        xvals <- xvals[ord]
      } else {
        sub <- sub[order(match(as.character(sub[[x_var]]), x_levels)), ]
        xvals <- match(as.character(sub[[x_var]]), x_levels)
      }
      yvals <- suppressWarnings(as.numeric(sub[[var]]))
      ok <- is.finite(xvals) & is.finite(yvals)
      if (any(ok)) {
        if (x_is_numeric)
          lines(xvals[ok], yvals[ok], col = col[grp], lwd = lwd)
        points(xvals[ok], yvals[ok], pch = pch[grp], col = col[grp])
      }
    }

    if (isTRUE(legend) && n_groups > 1L && pi == 1L)
      graphics::legend(legend_pos,
                       legend = group_levels,
                       col = col[group_levels],
                       lwd = if (x_is_numeric) lwd else NA,
                       lty = if (x_is_numeric) 1L else 0L,
                       pch = pch[group_levels],
                       bg = "white",
                       title = "Length group",
                       cex = 0.8)
  }

  invisible(x)
}


## Helper ----------------------------------------------------------------------

.spatial_indicators_one <- function(cpue, lat, lon) {
  ok <- is.finite(cpue) & is.finite(lat) & is.finite(lon)
  cpue <- cpue[ok]
  lat <- lat[ok]
  lon <- lon[ok]
  n_hauls <- length(cpue)
  sum_w <- sum(cpue, na.rm = TRUE)
  if (sum_w == 0 || n_hauls == 0L)
    return(list(n_hauls = n_hauls, cog_lat = NA_real_, cog_lon = NA_real_))
  list(n_hauls = n_hauls,
       cog_lat = sum(cpue * lat) / sum_w,
       cog_lon = sum(cpue * lon) / sum_w)
}
