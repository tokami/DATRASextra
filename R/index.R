
## Main function ---------------------------------------------------------------

#' Design-based stratified mean abundance or biomass index
#'
#' Computes a design-based stratified mean index from a `datras_raw` object
#' using pre-computed per-haul totals (`HaulN` or `HaulWgt`) stored in `HH`.
#' When the value column is a matrix (e.g. numbers split into length groups by
#' [add_total_numbers_by_haul()]), a separate index and confidence interval are
#' returned for each column.
#'
#' @param x A `datras_raw` object whose `HH` table contains `value_var`.
#' @param value_var Name of the `HH` column containing per-haul values.
#'   Default `"HaulN"` (total numbers per haul, added by
#'   [add_total_numbers_by_haul()]). Use `"HaulWgt"` for a biomass index. The
#'   column may be a numeric vector (single group) or a matrix (one column per
#'   length group); in the latter case one index is computed per column.
#' @param strata_var Character vector naming one or more `HH` columns that
#'   define strata. Default `"StatRec"` (ICES statistical rectangles).
#' @param cpue_method Standardisation method applied to `value_var`:
#'   `"per_swept_area"` (per km^2 swept; requires `SweptArea` from
#'   [add_swept_area()]), `"per_hour"` (per hour; uses `HaulDur`), or `"count"`
#'   (no standardisation, raw totals per haul).
#' @param by Character vector of `HH` column names for which separate indices
#'   are computed (e.g. `"Year"`, `c("Year", "Quarter")`). Use `NULL` for a
#'   single overall index.
#' @param stratum_areas Optional data frame with columns matching `strata_var`
#'   and a numeric `Area` column. If `NULL` (default) all strata are weighted
#'   equally.
#' @param confidence_level Numeric; coverage probability for the confidence
#'   interval. Default `0.95`.
#'
#' @return A data frame with one row per `by`-group x length-group combination
#'   and columns: the `by` columns (if any), `group` (column name from the
#'   value matrix, or `value_var` when the column is a vector), `cpue_method`,
#'   `n_hauls`, `n_strata`, `index`, `se`, `cv`, `ci_lower`, `ci_upper`.
#'
#' @details
#' The function assumes [clean_datras()] has been applied beforehand and that
#' `value_var` is already present in `HH` (e.g. via
#' [add_total_numbers_by_haul()] or [add_weight_at_length()]). Hauls where
#' `value_var` is `NA` or non-finite after CPUE standardisation are excluded.
#'
#' The stratified index is:
#' \deqn{\hat{Y} = \frac{\sum_h A_h \bar{y}_h}{\sum_h A_h}}
#' with design-based variance
#' \deqn{\widehat{\mathrm{Var}}(\hat{Y}) =
#'   \frac{\sum_h A_h^2\, s_h^2 / n_h}{(\sum_h A_h)^2}}
#' summed over strata with \eqn{n_h \ge 2}. Strata with a single haul
#' contribute to the index but not to the variance; a warning is issued when
#' this occurs. Confidence intervals use a t-distribution with degrees of
#' freedom equal to the number of multi-haul strata minus one.
#'
#' @seealso [add_total_numbers_by_haul()], [add_swept_area()], [clean_datras()]
#' @examples
#' \dontrun{
#' data(dab)
#' dab <- add_swept_area(dab)
#' dab <- add_total_numbers_by_haul(dab)
#' calc_stratified_index(dab, cpue_method = "per_swept_area", by = "Year")
#'
#' # length-group indices
#' dab <- add_total_numbers_by_haul(dab, length_cuts = c(15, 25))
#' calc_stratified_index(dab, cpue_method = "per_swept_area", by = "Year")
#' }
#' @export
calc_stratified_index <- function(x,
                                  value_var = "HaulN",
                                  strata_var = "StatRec",
                                  cpue_method = c("per_swept_area", "per_hour", "count"),
                                  by = "Year",
                                  stratum_areas = NULL,
                                  confidence_level = 0.95) {
  .check_class_datras(x)
  cpue_method <- match.arg(cpue_method)

  if (!is.numeric(confidence_level) || length(confidence_level) != 1L ||
      confidence_level <= 0 || confidence_level >= 1)
    stop("`confidence_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)

  hh <- as.data.frame(x[["HH"]], stringsAsFactors = FALSE)

  ## --- validate columns ------------------------------------------------------
  if (!(value_var %in% names(hh)))
    stop("`value_var` column '", value_var, "' not found in HH. ",
         "Run `add_total_numbers_by_haul()` (for 'HaulN') or the appropriate ",
         "`add_*` function first.", call. = FALSE)

  miss_strata <- setdiff(strata_var, names(hh))
  if (length(miss_strata) > 0)
    stop("strata_var column(s) not found in HH: ",
         paste(miss_strata, collapse = ", "), call. = FALSE)

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

  if (!is.null(stratum_areas)) {
    if (!is.data.frame(stratum_areas))
      stop("`stratum_areas` must be a data frame.", call. = FALSE)
    miss_area_cols <- setdiff(c(strata_var, "Area"), names(stratum_areas))
    if (length(miss_area_cols) > 0)
      stop("`stratum_areas` must contain columns: ",
           paste(c(strata_var, "Area"), collapse = ", "), call. = FALSE)
  }

  ## --- unpack value column into a named list of vectors ----------------------
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

  ## --- build working HH subset -----------------------------------------------
  hh_cols <- unique(c("haul.id", strata_var, by, cpue_col))
  hh_sub <- hh[, hh_cols, drop = FALSE]
  hh_sub$.strata_key <- .make_composite_key(hh_sub, strata_var)

  ## --- stratum areas lookup --------------------------------------------------
  if (!is.null(stratum_areas)) {
    areas_df <- as.data.frame(stratum_areas, stringsAsFactors = FALSE)
    areas_df$.strata_key <- .make_composite_key(areas_df, strata_var)
    areas_lookup <- setNames(as.numeric(areas_df$Area), areas_df$.strata_key)
  } else {
    areas_lookup <- NULL
  }

  ## --- loop over value groups (columns of matrix) ----------------------------
  single_haul_warned <- FALSE
  results_list <- vector("list", length(val_list))

  for (vi in seq_along(val_list)) {
    grp_name <- names(val_list)[vi]
    hh_sub$cpue <- switch(cpue_method,
      per_swept_area = val_list[[vi]] / (hh_sub[[cpue_col]] * 1e-6),
      per_hour = val_list[[vi]] / (hh_sub[[cpue_col]] / 60),
      count = val_list[[vi]]
    )
    work <- hh_sub[is.finite(hh_sub$cpue), , drop = FALSE]
    if (nrow(work) == 0L) next

    ## split by `by` groups
    if (is.null(by) || length(by) == 0L) {
      by_groups <- list(ALL = work)
      by_vals_list <- list(list())
    } else {
      by_key <- .make_composite_key(work, by)
      by_groups <- split(work, by_key, drop = TRUE)
      by_vals_list <- lapply(by_groups, function(g) {
        row <- g[1L, by, drop = FALSE]
        for (col in names(row)) if (is.factor(row[[col]])) row[[col]] <- as.character(row[[col]])
        as.list(row)
      })
    }

    ## index per by-group
    group_rows <- vector("list", length(by_groups))
    for (gi in seq_along(by_groups)) {
      grp <- by_groups[[gi]]

      present_strata <- unique(grp$.strata_key)
      if (!is.null(areas_lookup)) {
        A_h <- areas_lookup[present_strata]
        unknown <- present_strata[is.na(A_h)]
        if (length(unknown) > 0) {
          warning(length(unknown), " strata not found in `stratum_areas` and excluded: ",
                  paste(unknown, collapse = ", "), call. = FALSE)
          grp <- grp[!(grp$.strata_key %in% unknown), , drop = FALSE]
          A_h <- A_h[!is.na(A_h)]
          present_strata <- names(A_h)
        }
      } else {
        A_h <- setNames(rep(1, length(present_strata)), present_strata)
      }
      if (nrow(grp) == 0L) next

      res <- .stratified_index_one(
        cpue = grp$cpue,
        strata = grp$.strata_key,
        areas = A_h,
        confidence_level = confidence_level
      )

      if (!single_haul_warned && res$n_strata_single_haul > 0L) {
        warning(res$n_strata_single_haul,
                " stratum/strata with only one haul excluded from variance ",
                "calculation (variance undefined).", call. = FALSE)
        single_haul_warned <- TRUE
      }

      group_rows[[gi]] <- c(
        by_vals_list[[gi]],
        list(group = grp_name,
             cpue_method = cpue_method,
             n_hauls = res$n_hauls,
             n_strata = res$n_strata,
             index = res$index,
             se = res$se,
             cv = res$cv,
             ci_lower = res$ci_lower,
             ci_upper = res$ci_upper)
      )
    }
    results_list[[vi]] <- Filter(Negate(is.null), group_rows)
  }

  ## --- assemble output -------------------------------------------------------
  all_rows <- Filter(Negate(is.null), do.call(c, results_list))
  if (length(all_rows) == 0L) {
    empty <- data.frame(group = character(0), cpue_method = character(0),
                        n_hauls = integer(0), n_strata = integer(0),
                        index = numeric(0), se = numeric(0), cv = numeric(0),
                        ci_lower = numeric(0), ci_upper = numeric(0),
                        stringsAsFactors = FALSE)
    if (!is.null(by) && length(by) > 0L) {
      by_empty <- setNames(replicate(length(by), character(0), simplify = FALSE), by)
      empty <- cbind(as.data.frame(by_empty, stringsAsFactors = FALSE), empty)
    }
    return(empty)
  }

  out <- do.call(rbind, lapply(all_rows, as.data.frame, stringsAsFactors = FALSE))
  rownames(out) <- NULL
  out <- .restore_numeric_cols(out, by)
  out
}


## Plotting --------------------------------------------------------------------

#' Plot a stratified abundance or biomass index
#'
#' Plots the output of [calc_stratified_index()] as a time-series. When the
#' index contains multiple length groups (from a matrix `HaulN`), all groups
#' are drawn in the same panel as separate coloured lines with a legend. An
#' optional `panel_var` can split the plot into panels (e.g. by survey).
#'
#' @param x Data frame returned by [calc_stratified_index()].
#' @param x_var Name of the column to use as the x-axis. Defaults to `"Year"`
#'   if present, otherwise the first non-result column.
#' @param panel_var Optional column name used to split the plot into panels
#'   (e.g. `"Survey"`). Default `NULL` (single panel).
#' @param ci Logical; draw per-group confidence-interval ribbons. Default
#'   `TRUE`.
#' @param ci_alpha Transparency of the CI ribbons (0-1). Default `0.2`.
#' @param log_scale Logical; log-transform the y-axis. Default `FALSE`.
#' @param fixed_ylim Logical; share a common y-axis range across panels.
#'   Default `TRUE`.
#' @param col Character vector of colours, one per unique `group` value.
#'   Defaults to the DATRASextra discrete palette.
#' @param lwd Line width. Default `2`.
#' @param pch Point symbol. Default `16`.
#' @param legend Logical; draw a legend for the group colours. Default `TRUE`;
#'   suppressed automatically when there is only one group.
#' @param legend_pos Legend position string passed to [graphics::legend()].
#'   Default `"topright"`.
#' @param layout Logical; when `TRUE` (default) and the plot has multiple
#'   panels, the function sets `par(mfrow)` automatically and restores it on
#'   exit. Set to `FALSE` to draw panels sequentially into the caller's current
#'   layout -- useful when combining with other plots via `par(mfrow = ...)`.
#' @param xlim,ylim Optional axis limits.
#' @param main Optional plot title.
#' @param xlab,ylab Axis labels. Auto-generated from `cpue_method` if `NULL`.
#' @param y_scale Rescaling of the y axis to keep the tick labels short.
#'   `"auto"` (default) divides the index by a power of 1000 chosen from the
#'   data and appends the factor to `ylab`; `"none"` plots the raw values; a
#'   number gives the exponent directly (e.g. `6` to plot in millions).
#'   Ignored when `log_scale = TRUE`. `ylim`, if supplied, is given in the
#'   original units.
#'
#' @return Invisibly returns `x`.
#' @seealso [calc_stratified_index()]
#' @examples
#' \dontrun{
#' data(dab)
#' dab <- add_swept_area(dab)
#' dab <- add_total_numbers_by_haul(dab, length_cuts = c(15, 25))
#' res <- calc_stratified_index(dab, by = "Year")
#' plot_index(res)
#' }
#' @export
plot_stratified_index <- function(x,
                                  x_var = NULL,
                                  panel_var = NULL,
                                  ci = TRUE,
                                  ci_alpha = 0.2,
                                  log_scale = FALSE,
                                  fixed_ylim = TRUE,
                                  col = NULL,
                                  lwd = 2,
                                  pch = 16,
                                  legend = TRUE,
                                  legend_pos = "topright",
                                  layout = TRUE,
                                  xlim = NULL,
                                  ylim = NULL,
                                  main = NULL,
                                  xlab = NULL,
                                  ylab = NULL,
                                  y_scale = "auto") {
  if (!is.data.frame(x))
    stop("`x` must be a data frame returned by `calc_stratified_index()`.", call. = FALSE)
  req <- c("group", "cpue_method", "index", "ci_lower", "ci_upper")
  miss <- setdiff(req, names(x))
  if (length(miss) > 0)
    stop("Missing columns in `x`: ", paste(miss, collapse = ", "), call. = FALSE)

  result_cols <- c("group", "cpue_method", "n_hauls", "n_strata",
                   "index", "se", "cv", "ci_lower", "ci_upper")

  ## --- detect x_var ----------------------------------------------------------
  if (is.null(x_var)) {
    if ("Year" %in% names(x)) {
      x_var <- "Year"
    } else {
      candidates <- setdiff(names(x), c(result_cols, panel_var))
      if (length(candidates) == 0)
        stop("Could not auto-detect x-axis variable. Set `x_var`.", call. = FALSE)
      x_var <- candidates[1]
      message("Using '", x_var, "' as x-axis variable.")
    }
  }
  if (!(x_var %in% names(x)))
    stop("`x_var` column '", x_var, "' not found.", call. = FALSE)

  ## --- warn about unhandled extra columns ------------------------------------
  extra <- setdiff(names(x), c(result_cols, x_var, panel_var, "group"))
  if (length(extra) > 0)
    message("Columns ignored in plot (consider filtering first): ",
            paste(extra, collapse = ", "))

  ## --- groups (coloured lines) -----------------------------------------------
  group_levels <- unique(as.character(x$group))
  n_groups <- length(group_levels)

  ## --- colours ---------------------------------------------------------------
  if (is.null(col)) {
    col <- .colours_datrasextra_discrete(n_groups)
  }
  col <- rep_len(col, n_groups)
  names(col) <- group_levels
  ci_cols <- grDevices::adjustcolor(col, alpha.f = ci_alpha)
  names(ci_cols) <- group_levels

  ## --- panels ----------------------------------------------------------------
  if (!is.null(panel_var) && panel_var %in% names(x)) {
    panel_levels <- unique(as.character(x[[panel_var]]))
  } else {
    panel_levels <- "ALL"
    panel_var <- NULL
  }
  n_panels <- length(panel_levels)

  ## --- y-axis scaling --------------------------------------------------------
  ## Stratified indices routinely run into the billions, and the resulting tick
  ## labels are wide enough to run into the axis label. Dividing by a power of
  ## 1000 and stating the factor in the axis label keeps both readable.
  y_pow <- if (isTRUE(log_scale) || identical(y_scale, "none")) {
    0L
  } else if (identical(y_scale, "auto")) {
    .auto_scale_exponent(c(x$index, x$ci_lower, x$ci_upper))
  } else if (is.numeric(y_scale) && length(y_scale) == 1L && is.finite(y_scale)) {
    as.integer(y_scale)
  } else {
    stop("`y_scale` must be \"auto\", \"none\", or a single number.", call. = FALSE)
  }

  if (y_pow != 0L) {
    fac <- 10^y_pow
    x$index <- x$index / fac
    x$ci_lower <- x$ci_lower / fac
    x$ci_upper <- x$ci_upper / fac
    if (!is.null(ylim)) ylim <- ylim / fac
  }

  ## --- axis labels -----------------------------------------------------------
  if (is.null(xlab)) xlab <- x_var
  if (is.null(ylab)) {
    cpue_str <- switch(x$cpue_method[1],
      per_swept_area = "per km\u00b2",
      per_hour = "per hour",
      "raw count"
    )
    ylab <- paste0("Index (", cpue_str, ")")
  }
  if (y_pow != 0L) ylab <- bquote(.(ylab) ~ "[" * 10^.(y_pow) * "]")

  ## --- shared y range (across all panels and groups) -------------------------
  shared_ylim <- ylim
  if (isTRUE(fixed_ylim) && is.null(shared_ylim)) {
    yvals <- c(x$ci_lower, x$ci_upper, x$index)
    yvals <- yvals[is.finite(yvals)]
    if (isTRUE(log_scale)) yvals <- yvals[yvals > 0]
    if (length(yvals) > 0) shared_ylim <- range(yvals)
  }

  ## --- layout ----------------------------------------------------------------
  if (n_panels > 1 && isTRUE(layout)) {
    old_par <- par(no.readonly = TRUE)
    on.exit(par(old_par), add = TRUE)
    par(mfrow = grDevices::n2mfrow(n_panels), mar = c(4.2, 4.8, 2, 1))
  } else {
    par(mar = c(4.2, 4.8, 2, 1))
  }

  ## --- draw panels -----------------------------------------------------------
  for (pi in seq_along(panel_levels)) {
    lv <- panel_levels[pi]
    panel_data <- if (!is.null(panel_var)) {
      x[as.character(x[[panel_var]]) == lv, , drop = FALSE]
    } else {
      x
    }

    ## y range for this panel
    ylim_use <- if (!is.null(shared_ylim)) {
      shared_ylim
    } else {
      yv <- c(panel_data$ci_lower, panel_data$ci_upper, panel_data$index)
      yv <- yv[is.finite(yv)]
      if (isTRUE(log_scale)) yv <- yv[yv > 0]
      if (length(yv) == 0) c(0, 1) else range(yv)
    }
    if (!isTRUE(log_scale)) ylim_use[1] <- min(ylim_use[1], 0)
    if (diff(ylim_use) == 0) ylim_use <- ylim_use + c(-1, 1)

    ## x range
    xall <- suppressWarnings(as.numeric(as.character(panel_data[[x_var]])))
    xlim_use <- if (!is.null(xlim)) xlim else range(xall, na.rm = TRUE) + c(-0.5, 0.5)

    panel_title <- if (!is.null(main)) {
      if (n_panels > 1) paste0(main, " \u2014 ", lv) else main
    } else if (n_panels > 1) {
      lv
    } else {
      ""
    }

    plot(NA,
         xlim = xlim_use,
         ylim = ylim_use,
         log = if (isTRUE(log_scale)) "y" else "",
         xlab = xlab,
         ylab = ylab,
         main = panel_title,
         las = 1)

    if (!isTRUE(log_scale)) abline(h = 0, lty = 2, col = "grey70")

    ## draw each group
    for (gi in seq_along(group_levels)) {
      grp <- group_levels[gi]
      sub <- panel_data[as.character(panel_data$group) == grp, , drop = FALSE]
      sub <- sub[order(suppressWarnings(as.numeric(sub[[x_var]]))), , drop = FALSE]
      xvals <- suppressWarnings(as.numeric(as.character(sub[[x_var]])))
      if (all(is.na(xvals))) xvals <- seq_len(nrow(sub))

      ## CI ribbon
      if (isTRUE(ci)) {
        ok <- is.finite(xvals) & is.finite(sub$ci_lower) & is.finite(sub$ci_upper)
        if (any(ok))
          polygon(c(xvals[ok], rev(xvals[ok])),
                  c(sub$ci_lower[ok], rev(sub$ci_upper[ok])),
                  col = ci_cols[grp], border = NA)
      }

      ## line + points
      ok <- is.finite(xvals) & is.finite(sub$index)
      if (any(ok)) {
        lines(xvals[ok], sub$index[ok], col = col[grp], lwd = lwd)
        points(xvals[ok], sub$index[ok], pch = pch, col = col[grp])
      }
    }

    ## legend (first panel only, or every panel if multi-panel)
    if (isTRUE(legend) && n_groups > 1L && (pi == 1L || n_panels > 1L))
      graphics::legend(legend_pos,
                       legend = group_levels,
                       col = col[group_levels],
                       lwd = lwd,
                       pch = pch,
                       bg = "white",
                       title = "Length group",
                       cex = 0.8)
  }

  invisible(x)
}


## Helpers ---------------------------------------------------------------------

.make_composite_key <- function(df, cols) {
  if (length(cols) == 1L) return(as.character(df[[cols]]))
  do.call(paste, c(lapply(cols, function(s) as.character(df[[s]])), list(sep = "\001")))
}

.stratified_index_one <- function(cpue, strata, areas, confidence_level) {
  spl <- split(cpue, strata)
  nms <- names(spl)
  y_h <- vapply(spl, mean, numeric(1))
  n_h <- vapply(spl, length, integer(1L))
  s2_h <- vapply(spl,
                 function(v) if (length(v) > 1L) var(v) else NA_real_,
                 numeric(1))
  A_h <- areas[nms]
  sum_A <- sum(A_h)

  index <- sum(A_h * y_h) / sum_A

  has_var <- n_h > 1L & !is.na(s2_h)
  Var <- if (any(has_var))
    sum(A_h[has_var]^2 * s2_h[has_var] / n_h[has_var]) / sum_A^2
  else
    NA_real_

  se <- if (is.finite(Var)) sqrt(Var) else NA_real_
  cv <- if (is.finite(se) && index > 0) se / index else NA_real_
  df_ <- max(1L, sum(has_var) - 1L)
  t_val <- qt((1 + confidence_level) / 2, df = df_)
  ci_lower <- if (is.finite(se)) max(0, index - t_val * se) else NA_real_
  ci_upper <- if (is.finite(se)) index + t_val * se else NA_real_

  list(n_hauls = length(cpue),
       n_strata = length(spl),
       n_strata_single_haul = sum(!has_var),
       index = index,
       se = se,
       cv = cv,
       ci_lower = ci_lower,
       ci_upper = ci_upper)
}
