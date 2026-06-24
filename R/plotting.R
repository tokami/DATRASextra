
## Main functions ----------------------------------------------------------------

#' Unified DATRAS overview plotting
#'
#' Plots spatial overviews from DATRAS haul data using gridded image maps or
#' point maps, with optional grouping and faceting.
#'
#' @param x A DATRAS-like object containing `x[['HH']]`, or `NULL` to use
#'   `DATRASextra::survey_info_full_raw` (fallback `survey_info_full`).
#' @param mode Plot mode: `"grid"` or `"points"`. Default is `"points"`.
#' @param grid_resolution Numeric vector `c(lon_step, lat_step)` in degrees
#'   controlling the bin width for `mode = "grid"`. Default `c(1, 0.5)` gives
#'   the original 1 x 0.5 degree grid. Finer values such as `c(0.5, 0.25)` add
#'   spatial detail; coarser values (e.g. `c(2, 1)`) reduce clutter for very
#'   dense data. Has no effect in `mode = "points"`.
#' @param metric Grid metric: `"sum"`, `"mean"`, `"count_hauls"`,
#'   `"presence"`, `"count_surveys"`, or `"species_richness"`. The
#'   `"species_richness"` option counts unique species (via `Valid_Aphia`) per
#'   haul in points mode and per grid cell (pooled across hauls) in grid mode;
#'   it requires `x` to contain an `HL` table with `haul.id` and `Valid_Aphia`
#'   columns.
#' @param spatial_basis Spatial basis used for coordinates: `"raw"` uses haul
#'   coordinates, `"statrec"` uses ICES rectangle midpoints from `StatRec`.
#' @param by_survey,by_gear,by_quarter,by_year,by_daynight Logical grouping
#'   toggles used to define panel groups.
#' @param multi_panels Logical. If `TRUE`, plot one group per panel.
#' @param panel_layout Arrangement of panels when `multi_panels = TRUE`. `"auto"`
#'   (default) uses [grDevices::n2mfrow()] to choose a roughly square layout;
#'   `"horizontal"` places all panels in a single row; `"vertical"` places them
#'   in a single column. For matrix-valued `value_var` (length-class panels
#'   crossed with groups), `"horizontal"` transposes the row/column assignment.
#' @param value_var Optional haul-level variable to map to values.
#' @param offset_var Optional haul-level denominator variable.
#' @param positive_only Logical. If `TRUE`, only hauls with a strictly positive
#'   value are plotted. When `value_var` is supplied, positivity is determined
#'   from that variable (after dividing by `offset_var` if supplied). When
#'   `value_var` is `NULL`, the function falls back to total `HaulN` or
#'   `HaulWgt` from `HH` (whichever is found first); a warning is issued if
#'   neither is available. Default `FALSE`.
#' @param transform Value transform: `"none"`, `"log1p"`, `"sqrt"`, `"log10"`.
#' @param fixed_scale Logical. If `TRUE` (default), a common value scale is used
#'   across groups or panels: in grid mode the colour scale is shared across
#'   panels; in points mode point sizes are scaled relative to the global value
#'   range. If `FALSE`, each group (single-panel grouped mode) or each panel
#'   (multi-panel mode) is scaled independently, so point sizes reflect relative
#'   abundance within the group or panel rather than in absolute terms.
#' @param fixed_axes Logical. Use common map extent across panels.
#' @param plot_map Logical. Add land map layer.
#' @param xlim,ylim Optional map limits.
#' @param col Optional color palette.
#' @param palette_rev Logical. Reverse default palette direction.
#' @param alpha Point alpha in points mode.
#' @param pch Point symbol.
#' @param cex Base point size.
#' @param size_range Point size range when value-based scaling is used.
#' @param legend Logical. Draw legends.
#' @param legend_mode Legend behavior: `"auto"`, `"none"`, `"global"`, or
#'   `"per_panel"`.
#' @param max_grid_legend_levels Maximum number of levels shown in grid legends.
#' @param legend_ncol Number of columns in legend
#' @param legend_pos position of legend. Default: NULL.
#' @param legend_cex cex of legend. Default: NULL.
#' @param grid_group_strategy Strategy for grouped single-panel grid maps when
#'   multiple groups occur in the same cell: `"dominant"`, `"mixed"`, or
#'   `"error"`.
#' @param main Optional title for single-panel mode.
#' @param asp Aspect ratio passed to [graphics::plot()]. `"auto"` (default)
#'   uses the latitude-corrected value `1 / cos(mean(ylim) * pi / 180)`, which
#'   gives equal physical distances per degree of longitude and latitude at the
#'   mean latitude. Pass `1` for a simpler equal-degrees ratio, or `NULL` to
#'   leave the aspect ratio determined by the device dimensions (current
#'   behaviour of base `plot()`). Fixing `asp` prevents the map from distorting
#'   when figure margins or device dimensions change.
#' @param years Optional integer vector of years to include. If `NULL`
#'   (default), all years in the data are plotted.
#' @param add Logical. If `FALSE` (default), the function configures its own
#'   graphics device via [graphics::par()] (`mfrow`, `mar`, `oma`) and restores
#'   the previous settings on exit. If `TRUE`, no `par()` changes are made: the
#'   plot is drawn into whatever panel or layout is already active, allowing the
#'   function to be embedded in figures created with `par(mfrow = ...)` or
#'   [graphics::layout()]. When `add = TRUE`, the caller is responsible for
#'   setting appropriate margins.
#'
#' @return Invisibly returns list with processed data and plotting metadata.
#' @export
plot_datras_overview <- function(x = NULL,
                                 mode = c("points", "grid"),
                                 grid_resolution = c(1, 0.5),
                                 metric = c("presence", "sum", "mean", "count_hauls", "count_surveys", "species_richness"),
                                 spatial_basis = c("raw", "statrec"),
                                 by_survey = FALSE,
                                 by_gear = FALSE,
                                 by_quarter = FALSE,
                                 by_year = FALSE,
                                 by_daynight = FALSE,
                                 multi_panels = FALSE,
                                 panel_layout = c("auto", "horizontal", "vertical"),
                                 value_var = NULL,
                                 offset_var = NULL,
                                 positive_only = FALSE,
                                 transform = c("none", "log1p", "sqrt", "log10"),
                                 fixed_scale = TRUE,
                                 fixed_axes = TRUE,
                                 plot_map = TRUE,
                                 xlim = NULL,
                                 ylim = NULL,
                                 col = NULL,
                                 palette_rev = FALSE,
                                 alpha = 0.8,
                                 pch = 16,
                                 cex = 0.8,
                                 size_range = c(0.7, 2.2),
                                 legend = TRUE,
                                 legend_mode = c("auto", "none", "global", "per_panel"),
                                 max_grid_legend_levels = 5,
                                 legend_ncol = 1,
                                 legend_pos = NULL,
                                 legend_cex = NULL,
                                 grid_group_strategy = c("dominant", "mixed", "error"),
                                 main = NULL,
                                 years = NULL,
                                 asp = "auto",
                                 add = FALSE) {
  mode <- match.arg(mode)
  metric <- match.arg(metric)
  spatial_basis <- match.arg(spatial_basis)
  transform <- match.arg(transform)
  legend_mode <- match.arg(legend_mode)
  panel_layout <- match.arg(panel_layout)
  grid_group_strategy <- match.arg(grid_group_strategy)
  if (!is.numeric(grid_resolution) || length(grid_resolution) != 2 || any(grid_resolution <= 0))
    stop("`grid_resolution` must be a positive numeric vector of length 2.", call. = FALSE)
  if (identical(mode, "points") && metric %in% c("count_hauls", "count_surveys"))
    message("`metric = '", metric, "'` counts observations per grid cell and has no ",
            "per-point meaning in points mode (every haul contributes a count of 1). ",
            "Use `mode = 'grid'` to visualise ", metric, " spatially.")

  hh <- .as_hh_data(x)
  map_scale <- if (is.null(x)) 110L else 50L
  hh <- .prepare_spatial_basis(hh, spatial_basis = spatial_basis)
  x_col <- "lon"
  y_col <- "lat"
  if (!is.null(years)) {
    if ("Year" %in% names(hh)) {
      hh <- hh[hh$Year %in% years, , drop = FALSE]
    } else {
      warning("`years` supplied but no `Year` column found in HH; ignoring.", call. = FALSE)
    }
  }
  if (nrow(hh) == 0) stop("No finite coordinate rows in HH.", call. = FALSE)
  if (identical(mode, "points") && nrow(hh) > 50000)
    message("Plotting ", nrow(hh), " hauls as individual points may be slow. ",
            "Consider mode = 'grid' with e.g. grid_resolution = c(0.5, 0.25).")

  hl <- NULL
  if (identical(metric, "species_richness")) {
    if (is.null(x) || !is.list(x) || is.null(x[["HL"]]))
      stop("`metric = 'species_richness'` requires `x` to be a datras_raw object with an `HL` table.", call. = FALSE)
    hl <- as.data.frame(x[["HL"]], stringsAsFactors = FALSE)
    if (!all(c("haul.id", "Valid_Aphia") %in% names(hl)))
      stop("`HL` must contain `haul.id` and `Valid_Aphia` columns for `metric = 'species_richness'`.", call. = FALSE)
    haul_rich <- tapply(hl$Valid_Aphia, hl$haul.id,
                        function(v) length(unique(v[!is.na(v)])))
    hh$species_richness <- as.integer(haul_rich[match(hh$haul.id, names(haul_rich))])
    hh$species_richness[is.na(hh$species_richness)] <- 0L
    value_var <- "species_richness"
  }

  value_col_names <- NULL
  lc_multi_panels <- FALSE
  if (!is.null(value_var) && value_var %in% names(hh)) {
    raw_col <- hh[[value_var]]
    if (is.matrix(raw_col) && ncol(raw_col) > 1) {
      value_col_names <- colnames(raw_col)
      if (is.null(value_col_names)) value_col_names <- paste0("[", seq_len(ncol(raw_col)), "]")
      hh_list <- lapply(seq_along(value_col_names), function(j) {
        h <- hh
        h[[value_var]] <- raw_col[, j]
        h$.lc_group <- value_col_names[j]
        h
      })
      hh <- do.call(rbind, hh_list)
      hh$.lc_group <- factor(hh$.lc_group, levels = value_col_names)
      lc_multi_panels <- TRUE
    }
  }

  hh$.value <- .compute_value(hh, value_var = value_var, offset_var = offset_var, transform = transform)
  if (isTRUE(positive_only)) {
    if (!is.null(value_var)) {
      hh <- hh[!is.na(hh$.value) & hh$.value > 0, , drop = FALSE]
    } else {
      ## Without value_var, .value is all-1s and the filter would keep everything.
      ## Use HaulN or HaulWgt totals if available (as.data.frame expands matrix
      ## columns so we match both "HaulN" and "HaulN.(0-20]" style names).
      hn_cols <- grep("^HaulN$|^HaulN\\.", names(hh), value = TRUE, perl = TRUE)
      hw_cols <- grep("^HaulWgt$|^HaulWgt\\.", names(hh), value = TRUE, perl = TRUE)
      if (length(hn_cols) > 0) {
        haul_total <- rowSums(hh[, hn_cols, drop = FALSE], na.rm = TRUE)
        hh <- hh[!is.na(haul_total) & haul_total > 0, , drop = FALSE]
      } else if (length(hw_cols) > 0) {
        haul_total <- rowSums(hh[, hw_cols, drop = FALSE], na.rm = TRUE)
        hh <- hh[!is.na(haul_total) & haul_total > 0, , drop = FALSE]
      } else {
        warning("`positive_only = TRUE` has no effect: specify `value_var` or add HaulN/HaulWgt to HH first.",
                call. = FALSE)
      }
    }
  }
  hh$.group <- .build_group(hh, by_survey, by_gear, by_quarter, by_year, by_daynight)
  has_grouping <- any(c(by_survey, by_gear, by_quarter, by_year, by_daynight))
  active_dims <- .group_dims_active(by_survey, by_gear, by_quarter, by_year, by_daynight)

  group_cols <- NULL
  if (has_grouping) {
    lev <- levels(hh$.group)
    if (is.null(col)) {
      group_cols <- .colours_datrasextra_discrete(length(lev), rev = palette_rev)
    } else {
      group_cols <- col
    }
    names(group_cols) <- lev
  }

  if (!is.null(xlim)) hh <- hh[hh[[x_col]] >= xlim[1] & hh[[x_col]] <= xlim[2], , drop = FALSE]
  if (!is.null(ylim)) hh <- hh[hh[[y_col]] >= ylim[1] & hh[[y_col]] <= ylim[2], , drop = FALSE]
  if (nrow(hh) == 0) stop("No rows left after applying xlim/ylim.", call. = FALSE)

  grid_info <- .make_grid(hh, x_col = x_col, y_col = y_col,
                         grid_resolution = grid_resolution)
  hh <- grid_info$data
  if (is.null(xlim)) xlim <- grid_info$xlim
  if (is.null(ylim)) ylim <- grid_info$ylim

  if (identical(asp, "auto")) {
    asp <- 1 / cos(mean(ylim) * pi / 180)
  }

  user_col <- col  ## remember whether the user supplied a colour before auto-fill
  if (is.null(col)) {
    if (metric %in% c("sum", "mean")) {
      col <- .colours_datrasextra_continuous(12, rev = palette_rev)
    } else {
      col <- .colours_datrasextra_discrete(9, rev = palette_rev)
    }
  }

  if (lc_multi_panels) {
    multi_panels <- TRUE
    other_levels <- levels(hh$.group)
    n_lc <- length(value_col_names)
    n_grp <- length(other_levels)
    # "horizontal" with multiple groups: LCs vary across rows, groups across columns
    lc_horiz <- identical(panel_layout, "horizontal") && n_grp > 1L
    if (lc_horiz) {
      ordered_panel_levels <- c(sapply(value_col_names, function(lc) paste0(other_levels, ":::", lc)))
    } else {
      ordered_panel_levels <- c(sapply(other_levels, function(g) paste0(g, ":::", value_col_names)))
    }
    hh$.panel_group <- factor(
      paste0(as.character(hh$.group), ":::", as.character(hh$.lc_group)),
      levels = ordered_panel_levels)
    split_list <- split(hh, hh$.panel_group, drop = FALSE)
    clean_other <- if (!has_grouping) {
      rep("", length(other_levels))
    } else {
      sapply(other_levels, function(g) {
        parts <- strsplit(g, " | ", fixed = TRUE)[[1]]
        paste(sapply(strsplit(parts, "="), function(x) paste(x[-1], collapse = "=")), collapse = " | ")
      })
    }
    if (lc_horiz) {
      names(split_list) <- c(sapply(value_col_names, function(lc)
        sapply(clean_other, function(g) if (nzchar(g)) paste0(g, ": ", lc) else lc)))
    } else {
      names(split_list) <- c(sapply(clean_other, function(g)
        if (nzchar(g)) paste0(g, ": ", value_col_names) else value_col_names))
    }
  } else if (isTRUE(multi_panels)) {
    split_list <- split(hh, hh$.group, drop = TRUE)
    if (length(split_list) > 1) {
      names(split_list) <- sapply(strsplit(names(split_list), "\\|"), function(x) paste(sapply(strsplit(x, "="), "[[", 2), collapse = "| "))
    }
  } else {
    split_list <- list(All = hh)
  }

  if (!isTRUE(fixed_axes) && isTRUE(multi_panels)) {
    panel_limits <- lapply(split_list, function(d) list(x = range(d[[x_col]], na.rm = TRUE), y = range(d[[y_col]], na.rm = TRUE)))
  } else {
    panel_limits <- lapply(split_list, function(d) list(x = xlim, y = ylim))
  }

  zlim <- NULL
  if (identical(mode, "grid") && isTRUE(fixed_scale) && length(split_list) > 1) {
    max_vals <- vapply(split_list, function(d) {
      ag <- .aggregate_grid(d, metric = metric, hl = hl)
      v <- ag$z[is.finite(ag$z)]
      if (length(v) == 0) 0 else max(v)
    }, numeric(1))
    zlim <- c(0, max(max_vals, na.rm = TRUE))
  }

  global_points_value_range <- NULL
  if (!identical(mode, "grid") && isTRUE(multi_panels) && !is.null(value_var) && isTRUE(fixed_scale)) {
    gv <- hh$.value[is.finite(hh$.value)]
    if (length(gv) >= 2 && diff(range(gv)) > 0) global_points_value_range <- range(gv)
  }

  n_panels <- length(split_list)
  if (lc_multi_panels) {
    mf <- if (lc_horiz) c(n_lc, n_grp) else c(n_grp, n_lc)
  } else if (n_panels > 1) {
    mf <- switch(panel_layout,
      horizontal = c(1L, n_panels),
      vertical   = c(n_panels, 1L),
      grDevices::n2mfrow(n_panels)
    )
  } else {
    mf <- c(1L, 1L)
  }

  land_layer <- .fetch_land_layer(plot_map = plot_map, map_scale = map_scale)

  if (!isTRUE(add)) {
    old_par <- par(no.readonly = TRUE)
    on.exit(par(old_par), add = TRUE)
    par(mfrow = mf, mar = c(0.3, 0.3, 0.3, 0.3), oma = c(4.2, 4.2, 0.4, 1))
  }

  panel_meta <- vector("list", length(split_list))
  names(panel_meta) <- names(split_list)

  draw_per_panel_legend <- isTRUE(legend) && !identical(legend_mode, "none") && (
    identical(legend_mode, "per_panel") ||
    (identical(legend_mode, "auto") && !isTRUE(fixed_scale) && isTRUE(multi_panels))
  )

  panel_names <- names(split_list)
  for (i in seq_along(panel_names)) {
    nm <- panel_names[i]
    d <- split_list[[nm]]
    lim <- panel_limits[[nm]]
    if (isTRUE(multi_panels) && isTRUE(fixed_axes)) {
      row_i <- ((i - 1) %/% mf[2]) + 1
      col_i <- ((i - 1) %% mf[2]) + 1
      show_x_axis <- row_i == mf[1]
      show_y_axis <- col_i == 1
    } else {
      show_x_axis <- TRUE
      show_y_axis <- TRUE
    }
    panel_title <- if (isTRUE(multi_panels)) NULL else main
    panel_label <- if (isTRUE(multi_panels)) nm else NULL

    if (identical(mode, "grid")) {
      if (has_grouping && !isTRUE(multi_panels)) {
        panel_meta[[nm]] <- .plot_grid_group_panel(hh = d,
                                                   group_cols = group_cols,
                                                   strategy = grid_group_strategy,
                                                   plot_map = plot_map,
                                                   xlim = lim$x,
                                                   ylim = lim$y,
                                                   asp = asp,
                                                   main = panel_title,
                                                   panel_label = panel_label,
                                                   show_x_axis = show_x_axis,
                                                   show_y_axis = show_y_axis,
                                                   map_scale = map_scale,
                                                   land_layer = land_layer)
      } else {
        panel_meta[[nm]] <- .plot_grid_panel(hh = d,
                                             metric = metric,
                                             col = col,
                                             zlim = zlim,
                                             plot_map = plot_map,
                                             xlim = lim$x,
                                             ylim = lim$y,
                                             asp = asp,
                                             main = panel_title,
                                             panel_label = panel_label,
                                             show_x_axis = show_x_axis,
                                             show_y_axis = show_y_axis,
                                             map_scale = map_scale,
                                             hl = hl,
                                             palette_rev = palette_rev,
                                             transform = transform,
                                             land_layer = land_layer)
      }
    } else {
      val <- d$.value
      rng <- range(val, na.rm = TRUE)
      points_value_meta <- NULL
      if (!is.null(value_var) && !identical(metric, "presence") &&
          is.finite(rng[1]) && is.finite(rng[2]) && rng[1] != rng[2]) {
        scale_rng <- if (!is.null(global_points_value_range)) global_points_value_range else rng
        brk <- seq(scale_rng[1], scale_rng[2], length.out = length(col) + 1)
        idx <- cut(val, breaks = brk, include.lowest = TRUE, labels = FALSE)
        idx[is.na(idx)] <- 1L
        pcol <- grDevices::adjustcolor(col[idx], alpha.f = alpha)
        scaled <- pmax(0, pmin(1, (val - scale_rng[1]) / (scale_rng[2] - scale_rng[1])))
        pcex <- size_range[1] + scaled * (size_range[2] - size_range[1])
        pcex[!is.finite(pcex)] <- cex
        points_value_meta <- list(col = col, size_range = size_range, scale_rng = scale_rng)
      } else if (has_grouping) {
        pcol <- grDevices::adjustcolor(group_cols[as.character(d$.group)], alpha.f = alpha)
        pcex <- cex
      } else {
        pt_col <- if (!is.null(user_col)) col[1] else .colours_datrasextra_continuous(10, rev = palette_rev)[1]
        pcol <- grDevices::adjustcolor(pt_col, alpha.f = alpha)
        pcex <- cex
      }

      .plot_points_panel(hh = d,
                         x_col = x_col,
                         y_col = y_col,
                         col_vec = pcol,
                         cex_vec = pcex,
                         pch = pch,
                         plot_map = plot_map,
                         xlim = lim$x,
                         ylim = lim$y,
                         asp = asp,
                         main = panel_title,
                         panel_label = panel_label,
                         show_x_axis = show_x_axis,
                         show_y_axis = show_y_axis,
                         map_scale = map_scale,
                         land_layer = land_layer)
      panel_meta[[nm]] <- list(value_range = rng, points_value_meta = points_value_meta)
    }

    if (draw_per_panel_legend) {
      pp_pos <- if (is.null(legend_pos)) {
        if (identical(mode, "grid")) "bottomright" else "topright"
      } else {
        legend_pos
      }
      pp_leg <- NULL
      if (identical(mode, "grid") && !(has_grouping && !isTRUE(multi_panels))) {
        info <- panel_meta[[nm]]
        if (!is.null(info$breaks)) {
          ll <- info$legend_labels
          lc <- info$legend_cols
          if (identical(metric, "presence")) {
            pp_leg <- list(legend = ll, col = lc, title = metric, cex = 0.8)
          } else {
            if (metric %in% c("count_hauls", "count_surveys", "species_richness") && length(ll) > max_grid_legend_levels) {
              vals <- suppressWarnings(as.numeric(ll))
              vals <- vals[is.finite(vals)]
              if (length(vals) > 0) {
                b <- unique(round(seq(min(vals), max(vals), length.out = max_grid_legend_levels + 1)))
                if (length(b) >= 2) {
                  ll <- paste0("[", b[-length(b)], ", ", b[-1], "]")
                  idx <- round(seq(1, length(lc), length.out = length(ll)))
                  lc <- lc[idx]
                }
              }
            }
            pp_leg <- list(legend = ll, col = lc, title = metric, cex = 0.7)
          }
          if (!is.null(legend_cex)) pp_leg$cex <- legend_cex
        }
      } else if (!identical(mode, "grid")) {
        info <- panel_meta[[nm]]
        if (!is.null(value_var) && !is.null(info$points_value_meta) &&
            is.finite(info$value_range[1]) && is.finite(info$value_range[2])) {
          meta <- info$points_value_meta
          rng_leg <- if (!is.null(meta$scale_rng)) meta$scale_rng else info$value_range
          n_ref <- 5
          ref_vals <- seq(rng_leg[1], rng_leg[2], length.out = n_ref)
          ref_scaled <- (ref_vals - rng_leg[1]) / (rng_leg[2] - rng_leg[1])
          ref_cex <- meta$size_range[1] + ref_scaled * (meta$size_range[2] - meta$size_range[1])
          ref_labels <- format(signif(.back_transform(ref_vals, transform), 3), trim = TRUE)
          leg_title <- if (!is.null(offset_var)) paste0(value_var, " / ", offset_var) else value_var
          if (!is.null(meta$col)) {
            ref_idx <- pmax(1L, pmin(length(meta$col), round(1 + ref_scaled * (length(meta$col) - 1))))
            ref_cols <- grDevices::adjustcolor(meta$col[ref_idx], alpha.f = alpha)
            pp_leg <- list(legend = ref_labels, col = ref_cols, title = leg_title, cex = 0.7,
                           pt.cex = ref_cex, pch = pch)
            if (!is.null(legend_cex)) pp_leg$cex <- legend_cex
          }
        } else if (has_grouping && is.null(value_var)) {
          grp_lev <- as.character(unique(d$.group))
          pp_cols <- if (!is.null(group_cols)) group_cols[grp_lev] else rep("grey30", length(grp_lev))
          pp_lg <- .format_group_legend(grp_lev, active_dims = active_dims)
          pp_leg <- list(legend = pp_lg$labels, col = pp_cols, title = pp_lg$title, cex = 0.7)
          if (!is.null(legend_cex)) pp_leg$cex <- legend_cex
        }
      }
      if (!is.null(pp_leg)) {
        graphics::legend(pp_pos, legend = pp_leg$legend,
                         pch = if (!is.null(pp_leg$pch)) pp_leg$pch else 15,
                         pt.cex = if (!is.null(pp_leg$pt.cex)) pp_leg$pt.cex else 1,
                         col = pp_leg$col, cex = pp_leg$cex, bg = "white",
                         title = pp_leg$title, ncol = legend_ncol)
      }
    }
  }

  if (length(split_list) > 1) {
    mtext("Longitude", side = 1, line = 2.5, outer = TRUE)
    mtext("Latitude", side = 2, line = 2.5, outer = TRUE)
  } else {
    ## title(xlab = "Longitude", ylab = "Latitude")
    mtext("Longitude", side = 1, line = 2.5, outer = FALSE)
    mtext("Latitude", side = 2, line = 2.5, outer = FALSE)
  }

  if (isTRUE(legend) && !identical(legend_mode, "none")) {
    leg_payload <- NULL
    size_leg_payload <- NULL
    if (identical(mode, "grid")) {
      show_grid_legend <- switch(
        legend_mode,
        auto = (!isTRUE(multi_panels) || isTRUE(fixed_scale)),
        global = TRUE,
        per_panel = FALSE,
        FALSE
      )
      info <- panel_meta[[1]]
      if (show_grid_legend && !is.null(info$breaks)) {
        if (has_grouping && !isTRUE(multi_panels)) {
          lg <- .format_group_legend(info$legend_labels, active_dims = active_dims)
          leg_payload <- list(legend = lg$labels, col = info$legend_cols, title = lg$title, cex = 0.7)
        } else if (identical(metric, "presence")) {
          leg_payload <- list(legend = info$legend_labels, col = info$legend_cols, title = metric, cex = 0.8)
        } else {
          leg_labels <- info$legend_labels
          leg_cols <- info$legend_cols

          if (metric %in% c("count_hauls", "count_surveys", "species_richness") && length(leg_labels) > max_grid_legend_levels) {
            vals <- suppressWarnings(as.numeric(leg_labels))
            vals <- vals[is.finite(vals)]
            if (length(vals) > 0) {
              b <- unique(round(seq(min(vals), max(vals), length.out = max_grid_legend_levels + 1)))
              if (length(b) >= 2) {
                leg_labels <- paste0("[", b[-length(b)], ", ", b[-1], "]")
                idx <- round(seq(1, length(info$legend_cols), length.out = length(leg_labels)))
                leg_cols <- info$legend_cols[idx]
              }
            }
          }
          leg_payload <- list(legend = leg_labels, col = leg_cols, title = metric, cex = 0.7)
        }
      }
    } else {
      show_points_legend <- switch(
        legend_mode,
        auto = (!isTRUE(multi_panels) && any(c(by_survey, by_gear, by_quarter, by_year, by_daynight)) &&
                  is.null(value_var)),
        global = (any(c(by_survey, by_gear, by_quarter, by_year, by_daynight)) && is.null(value_var)),
        per_panel = FALSE,
        FALSE
      )
      if (show_points_legend) {
        lev <- levels(hh$.group)
        leg_cols <- if (!is.null(group_cols)) group_cols[lev] else rep("grey30", length(lev))
        lg <- .format_group_legend(lev, active_dims = active_dims)
        leg_payload <- list(legend = lg$labels, col = leg_cols, title = lg$title, cex = 0.7)
      }
      if (!is.null(value_var) && !draw_per_panel_legend) {
        info <- panel_meta[[1]]
        if (!is.null(info$points_value_meta) && is.finite(info$value_range[1]) && is.finite(info$value_range[2])) {
          meta <- info$points_value_meta
          rng_leg <- if (!is.null(meta$scale_rng)) meta$scale_rng else info$value_range
          n_ref <- 5
          ref_vals <- seq(rng_leg[1], rng_leg[2], length.out = n_ref)
          ref_scaled <- (ref_vals - rng_leg[1]) / (rng_leg[2] - rng_leg[1])
          ref_cex <- meta$size_range[1] + ref_scaled * (meta$size_range[2] - meta$size_range[1])
          ref_labels <- format(signif(.back_transform(ref_vals, transform), 3), trim = TRUE)
          leg_title <- if (!is.null(offset_var)) paste0(value_var, " / ", offset_var) else value_var
          if (!is.null(meta$col)) {
            ref_idx <- pmax(1L, pmin(length(meta$col), round(1 + ref_scaled * (length(meta$col) - 1))))
            ref_cols <- grDevices::adjustcolor(meta$col[ref_idx], alpha.f = alpha)
            leg_payload <- list(legend = ref_labels, col = ref_cols, title = leg_title, cex = 0.7,
                                pt.cex = ref_cex, pch = pch)
          }
        }
      }
    }

    if (!is.null(leg_payload)) {
      pos <- if (is.null(legend_pos)) {
        if (identical(mode, "grid")) "bottomright" else "topright"
      } else {
        legend_pos
      }
      if (!is.null(legend_cex)) leg_payload$cex <- legend_cex
      graphics::legend(pos, legend = leg_payload$legend,
                       pch = if (!is.null(leg_payload$pch)) leg_payload$pch else 15,
                       pt.cex = if (!is.null(leg_payload$pt.cex)) leg_payload$pt.cex else 1,
                       col = leg_payload$col, cex = leg_payload$cex, bg = "white",
                       title = leg_payload$title, ncol = legend_ncol)
    }

    if (!is.null(size_leg_payload)) {
      if (!is.null(legend_cex)) size_leg_payload$cex <- legend_cex
      graphics::legend("bottomright", legend = size_leg_payload$legend,
                       pch = size_leg_payload$pch,
                       pt.cex = size_leg_payload$pt.cex,
                       col = size_leg_payload$col,
                       cex = size_leg_payload$cex,
                       bg = "white",
                       title = size_leg_payload$title)
    }
  }

  invisible(list(data = hh,
                 mode = mode,
                 metric = metric,
                 spatial_basis = spatial_basis,
                 transform = transform,
                 groups = levels(hh$.group),
                 panels = names(split_list),
                 x_col = x_col,
                 y_col = y_col))
}



##' Plot catch distribution by length class
##'
##' Aggregates numbers-at-length (`N`) and/or weight-at-length (`Wgt`) across
##' hauls and plots the resulting length distribution as a bar chart. The
##' function is intended to help identify meaningful length groups. Optional
##' cut points can be overlaid as dashed vertical lines, and bars are coloured
##' according to the resulting length intervals.
##'
##' The `N` and/or `Wgt` matrices must be present in `x[["HH"]]`, depending on
##' the selected value of `what`. Use [add_numbers_at_length()] and/or
##' [add_weight_at_length()] to add these matrices before plotting.
##'
##' If `what = "both"` but only one of `N` or `Wgt` is available, the function
##' falls back to plotting the available quantity and issues a message.
##'
##' @param x A `datras_raw` object with `N` and/or `Wgt` matrices in `HH`.
##' @param what Character; which quantity to plot. One of `"N"`, `"Wgt"`,
##'   `"both"`, or `"legend"`. The latter draws only the length-group legend.
##' @param agg Character; how to aggregate across hauls. Either `"sum"` or
##'   `"mean"`.
##' @param log_scale Logical; if `TRUE`, plot log-transformed aggregated values.
##'   Zero values are shown as missing.
##' @param length_cuts Optional numeric vector of break points in cm. If supplied,
##'   dashed vertical lines are drawn at these cut points and bars are coloured
##'   by length interval.
##' @param col Optional colour vector. If `length_cuts` is supplied, colours are
##'   recycled to match the number of resulting intervals, i.e.
##'   `length(length_cuts) + 1`. If `length_cuts` is not supplied, the first
##'   colour is used for all bars.
##' @param main Optional plot title.
##' @param do_legend Logical; if `TRUE`, draw a legend for the length intervals
##'   when `length_cuts` is supplied.
##' @param legend_ncol Integer; number of columns to use in the legend.
##'
##' @return Invisibly returns a `data.frame` with column `midL` and one or both
##'   of `N` and `Wgt`, depending on `what`. If `what = "legend"`, nothing useful
##'   is returned.
##'
##' @examples
##' \dontrun{
##' x <- add_numbers_at_length(dab)
##' x <- add_weight_at_length(x)
##'
##' ## Basic numbers distribution
##' plot_length_distribution(x)
##'
##' ## Both panels, log scale
##' plot_length_distribution(x, what = "both", log_scale = TRUE)
##'
##' ## Overlay proposed length groups
##' plot_length_distribution(x, length_cuts = c(15, 25))
##'
##' ## Plot without legend
##' plot_length_distribution(x, length_cuts = c(15, 25), do_legend = FALSE)
##'
##' ## Draw only the length-group legend
##' plot_length_distribution(x, what = "legend",
##'                          length_cuts = c(15, 25),
##'                          legend_ncol = 3)
##' }
##'
##' @export
plot_length_distribution <- function(x,
                                     what = c("N", "Wgt", "both", "legend"),
                                     agg = c("sum", "mean"),
                                     log_scale = FALSE,
                                     length_cuts = NULL,
                                     col = NULL,
                                     main = NULL,
                                     do_legend = TRUE,
                                     legend_ncol = 1L) {

  what <- match.arg(what)
  agg  <- match.arg(agg)

  .check_class_datras(x)

  N   <- x[["HH"]][["N"]]
  Wgt <- x[["HH"]][["Wgt"]]
  has_N   <- !is.null(N)   && is.matrix(N)
  has_Wgt <- !is.null(Wgt) && is.matrix(Wgt)

  ## graceful fallback when one matrix is absent
  if (identical(what, "both")) {
    if (!has_N && !has_Wgt)
      stop("Neither N nor Wgt found in HH. Run add_numbers_at_length() and/or add_weight_at_length() first.")
    if (!has_N)  { message("N not found; plotting Wgt only.");  what <- "Wgt" }
    if (!has_Wgt){ message("Wgt not found; plotting N only."); what <- "N" }
  }
  if (identical(what, "N")   && !has_N)
    stop("No N matrix in HH. Run add_numbers_at_length() first.")
  if (identical(what, "Wgt") && !has_Wgt)
    stop("No Wgt matrix in HH. Run add_weight_at_length() first.")

  ## midpoints from cm.breaks attribute; fall back to parsing column names
  cm_breaks <- attr(x, "cm.breaks")
  if (!is.null(cm_breaks) && length(cm_breaks) >= 2L) {
    mids <- cm_breaks[-length(cm_breaks)] + diff(cm_breaks) / 2
  } else {
    mids <- .parse_interval_mids(colnames(if (has_N) N else Wgt))
  }

  agg_fun  <- if (identical(agg, "sum")) colSums else colMeans
  ylab_N   <- if (identical(agg, "sum")) "Total numbers"      else "Mean numbers per haul"
  ylab_Wgt <- if (identical(agg, "sum")) "Total weight (g)" else "Mean weight per haul (g)"

  ## group colours for length_cuts
  cuts <- sort(length_cuts)
  n_grp <- length(cuts) + 1L
  grp_col <- if (!is.null(col)) {
    rep_len(col, n_grp)
  } else if (!is.null(cuts)) {
    .colours_datrasextra_discrete(n_grp)
  } else {
    .colours_datrasextra_discrete(6L)[5L]  # single default: teal
  }

  if (!is.null(cuts)) {
    bar_grp <- findInterval(mids, cuts) + 1L
    cut_labels <- c(
      paste0("< ", cuts[1L]),
      if (length(cuts) > 1L) paste0(cuts[-length(cuts)], " - ", cuts[-1L]),
      paste0(">= ", cuts[length(cuts)])
    )
  }

  ## x-axis tick positions: thin for many bins so labels don't overlap
  n_bars <- length(mids)
  step   <- if (n_bars > 40L) 10L else if (n_bars > 20L) 5L else 1L
  show   <- seq(1L, n_bars, by = step)

  .one_panel <- function(mat, ylab, xlab = "Length (cm)", main = NULL,
                         do_legend = TRUE, legend_only = FALSE) {
    y <- agg_fun(mat, na.rm = TRUE)
    if (isTRUE(log_scale)) {
      y <- log(y)
      y[!is.finite(y)] <- NA_real_
      ylab <- paste0("log(", ylab, ")")
    }

    bar_fill <- if (!is.null(cuts)) grp_col[bar_grp] else grp_col[1L]

    if (isFALSE(legend_only)) {
      bar_x <- barplot(
        y,
        names.arg = rep("", n_bars),
        col       = bar_fill,
        border    = NA,
        ylab      = "",
        xlab      = "",
        las       = 1L
      )
      axis(1L, at = bar_x[show], labels = as.character(mids[show]), tick = TRUE)
      mtext(ylab, 2, 4.5)
      mtext(main, 3, 1, font = 2)
      mtext(xlab, 1, 2.5)
      legend_pos <- "topright"
      legend_cex <- 0.85
    } else {
      plot.new()
      legend_pos <- "center"
      legend_cex <- 1.2
    }

    if (!is.null(cuts)) {

      abline(v = .map2bar(cuts, mids, bar_x), col = "grey20", lty = 2L, lwd = 1.5)

      if (isTRUE(do_legend)) {
        legend(legend_pos, legend = cut_labels,
               fill = grp_col,
               border = NA,
               cex = legend_cex, bg = "white", ncol = legend_ncol)
      }
    }

    invisible(y)
  }

  opar <- par(no.readonly = TRUE)
  on.exit(par(opar), add = TRUE)

  mar <- c(2, 6, 1, 1)
  oma <- c(2.5, 0, 1.5, 0)
  if (identical(what, "legend")) {
    .one_panel(N, legend_only = TRUE)
  } else if (identical(what, "both")) {
    par(mfrow = c(2L, 1L), mar = mar, oma = oma)
    y_N   <- .one_panel(N,   ylab_N, xlab = "", main = main, do_legend = do_legend)
    y_Wgt <- .one_panel(Wgt, ylab_Wgt, main = NULL, do_legend = FALSE)
    invisible(data.frame(midL = mids, N = unname(y_N), Wgt = unname(y_Wgt)))
  } else if (identical(what, "N")) {
    par(mar = mar, oma = oma)
    y <- .one_panel(N, ylab_N, main = main, do_legend = do_legend)
    invisible(data.frame(midL = mids, N = unname(y)))
  } else {
    par(mar = mar, oma = oma)
    y <- .one_panel(Wgt, ylab_Wgt, main = main, do_legend = do_legend)
    invisible(data.frame(midL = mids, Wgt = unname(y)))
  }
}


##' Plot species composition by length group
##'
##' Shows the contribution of each species in `x[["HL"]]` to total numbers
##' and/or total weight by length group. Length groups are taken from the
##' column names of `x[["HH"]][["HaulN"]]` or `x[["HH"]][["HaulWgt"]]`.
##' If these objects have only one column, or are plain vectors, a single
##' length group representing all lengths is used.
##'
##' Numbers are aggregated from `HL$Count`. Weights are estimated from `HL`
##' using length-weight parameters from the internal `species_info` table.
##' Species without available length-weight parameters contribute zero weight
##' and trigger a warning.
##'
##' If `what = "both"` but only one of `HaulN` or `HaulWgt` is available, the
##' function falls back to plotting the available quantity and issues a message.
##'
##' @param x A `datras_raw` object. `HH` must contain `HaulN` and/or `HaulWgt`,
##'   as produced by [add_total_numbers_by_haul()] and/or
##'   [add_total_weight_by_haul()].
##' @param what Character; which quantity to plot. One of `"N"`, `"Wgt"`,
##'   `"both"`, or `"legend"`. The latter draws only the species legend.
##' @param beside Logical; passed to [graphics::barplot()]. If `FALSE`, species
##'   are stacked within each length group. If `TRUE`, species are shown side by
##'   side within each length group.
##' @param col Optional colour vector, recycled to the number of displayed
##'   species after collapsing rare species to `"Other"`.
##' @param main Optional plot title.
##' @param max_species Integer; maximum number of species to show individually.
##'   Additional species, ranked by total count, are collapsed into `"Other"`.
##' @param do_legend Logical; if `TRUE`, draw the species legend.
##' @param legend_ncol Integer; number of columns to use in the legend.
##'
##' @return Invisibly returns a named list with elements `N` and `Wgt`. Each
##'   element is a matrix of aggregated values with rows representing species
##'   and columns representing length groups. `Wgt` is `NULL` unless
##'   `what = "Wgt"` or `what = "both"`.
##'
##' @examples
##' \dontrun{
##' dat <- add_numbers_at_length(mini)
##' dat <- add_weight_at_length(dat)
##' dat <- add_total_numbers_by_haul(dat, length_cuts = c(0, 20, 35, Inf))
##' dat <- add_total_weight_by_haul(dat, length_cuts = c(0, 20, 35, Inf))
##'
##' ## Numbers only
##' plot_species_composition(dat)
##'
##' ## Numbers and weight panels
##' plot_species_composition(dat, what = "both")
##'
##' ## Stacked bars instead of side-by-side bars
##' plot_species_composition(dat, beside = FALSE)
##'
##' ## Suppress legend
##' plot_species_composition(dat, do_legend = FALSE)
##'
##' ## Draw legend only
##' plot_species_composition(dat, what = "legend", legend_ncol = 2)
##' }
##'
##' @export
plot_species_composition <- function(x,
                                     what = c("N", "Wgt", "both", "legend"),
                                     beside = TRUE,
                                     col = NULL,
                                     main = NULL,
                                     max_species = 8L,
                                     do_legend = TRUE,
                                     legend_ncol = 1L) {

  what <- match.arg(what)
  .check_class_datras(x)

  hl    <- x[["HL"]]
  haulN <- x[["HH"]][["HaulN"]]
  haulW <- x[["HH"]][["HaulWgt"]]

  has_N <- !is.null(haulN)
  has_W <- !is.null(haulW)

  if (identical(what, "both")) {
    if (!has_N && !has_W)
      stop("Neither HaulN nor HaulWgt found. Run add_total_numbers_by_haul() and/or add_total_weight_by_haul() first.")
    if (!has_N)  { message("HaulN not found; plotting Wgt only."); what <- "Wgt" }
    if (!has_W)  { message("HaulWgt not found; plotting N only."); what <- "N" }
  }
  if (identical(what, "N")   && !has_N)
    stop("HaulN not found in HH. Run add_total_numbers_by_haul() first.")
  if (identical(what, "Wgt") && !has_W)
    stop("HaulWgt not found in HH. Run add_total_weight_by_haul() first.")

  if (is.null(hl) || nrow(hl) == 0L)
    stop("HL table is empty; cannot compute species contributions.")
  if (!"Count" %in% names(hl))
    stop("HL must contain a 'Count' column.")

  ## length groups from the column names of HaulN / HaulWgt
  ref <- if (has_N) haulN else haulW
  if (is.matrix(ref) && !is.null(colnames(ref))) {
    groups <- colnames(ref)
    breaks <- .breaks_from_colnames(groups)
  } else {
    groups <- "All lengths"
    breaks <- c(-Inf, Inf)
  }
  n_grp <- length(groups)

  ## assign each HL row to a length group
  grp_idx <- as.integer(
    cut(hl$LngtCm, breaks = breaks, right = TRUE, include.lowest = TRUE, labels = FALSE)
  )

  ## species present in HL
  aphias <- sort(unique(hl$Valid_Aphia[!is.na(hl$Valid_Aphia)]))
  if (length(aphias) == 0L)
    stop("No valid species (Valid_Aphia) found in HL.")

  sp_labels <- .get_species_labels(hl, aphias)

  ## species x group matrices
  sp_N <- .species_group_counts(hl, aphias, grp_idx, n_grp)
  colnames(sp_N) <- groups

  if (what %in% c("Wgt", "both")) {
    sp_W <- .species_group_wgt(hl, aphias, grp_idx, n_grp)
    colnames(sp_W) <- groups
  }

  ## order species by descending total count; collapse tail to "Other"
  ord <- order(rowSums(sp_N), decreasing = TRUE)
  max_species <- as.integer(max_species)

  .collate <- function(mat) {
    n <- nrow(mat)
    if (is.numeric(max_species) && !is.na(max_species) && n > max_species) {
      keep  <- ord[seq_len(max_species)]
      other <- ord[(max_species + 1L):n]
      rbind(mat[keep, , drop = FALSE],
            Other = colSums(mat[other, , drop = FALSE], na.rm = TRUE))
    } else {
      mat[ord, , drop = FALSE]
    }
  }

  sp_N_plot <- .collate(sp_N)
  if (what %in% c("Wgt", "both")) sp_W_plot <- .collate(sp_W)

  ## readable row labels
  n_rows <- nrow(sp_N_plot)
  rn     <- rownames(sp_N_plot)
  has_other <- "Other" %in% rn
  aphia_rows <- rn[rn != "Other"]
  row_labels <- c(unname(sp_labels[aphia_rows]),
                  if (has_other) "Other")
  rownames(sp_N_plot) <- row_labels
  if (what %in% c("Wgt", "both")) rownames(sp_W_plot) <- row_labels

  ## colours (first species = bottom of stack)
  bar_col <- if (!is.null(col)) rep_len(col, n_rows) else .colours_datrasextra_discrete(n_rows)
  names(bar_col) <- row_labels

  opar <- par(no.readonly = TRUE)
  on.exit(par(opar), add = TRUE)

  ## for beside = TRUE the bottom margin must accommodate group labels
  bot_mar <- if (isTRUE(beside) && n_grp > 1L) 5 else 3

  .one_panel <- function(mat, ylab, xlab = "Length group", main = NULL,
                         do_legend = TRUE, legend_only = FALSE) {
    if (isFALSE(legend_only)) {
      barplot(mat,
              beside = beside,
              col    = bar_col,
              border = "black",
              ylab   = "",
              xlab   = "",
              las    = 1L)
      mtext(ylab, 2, 4.5)
      mtext(xlab, 1, 2.5)
      mtext(main, 3, 1, font = 2)
      legend_pos <- "topright"
      legend_cex <- 0.85
    } else {
      plot.new()
      legend_pos <- "center"
      legend_cex <- 1.2
    }
    ## stacked: reverse legend so top-of-stack species appears first
    leg_order <- if (isTRUE(beside)) seq_along(row_labels) else rev(seq_along(row_labels))
    if (isTRUE(do_legend)) {
      legend(legend_pos,
             legend = row_labels[leg_order],
             fill   = bar_col[leg_order],
             border = "black",
             bg = "white",
             cex    = legend_cex,
             ncol   = legend_ncol)
    }
  }

  mar <- c(2, 6, 1, 1)
  oma <- c(2.5, 0, 1.5, 0)
  if (identical(what, "legend")) {
    .one_panel(sp_N_plot, legend_only = TRUE)
  } else if (identical(what, "both")) {
    par(mfrow = c(2L, 1L), mar = mar, oma = oma)
    .one_panel(sp_N_plot, "Total numbers", xlab = "", main = main, do_legend = do_legend)
    .one_panel(sp_W_plot, "Total weight (g)", do_legend = FALSE, main = NULL)
  } else if (identical(what, "N")) {
    par(mar = mar, oma = oma)
    .one_panel(sp_N_plot, "Total numbers", main = main, do_legend = do_legend)
  } else {
    par(mar = mar, oma = oma)
    .one_panel(sp_W_plot, "Total weight (g)", main = main, do_legend = do_legend)
  }

  invisible(list(
    N   = sp_N_plot,
    Wgt = if (what %in% c("Wgt", "both")) sp_W_plot else NULL
  ))
}


## Internal functions ------------------------------------------------------------

## Map length cut points (in cm) to barplot x-coordinates.
.map2bar <- function(cuts, mids, bar_x) {
  n    <- length(mids)
  step <- if (n >= 2L) (bar_x[n] - bar_x[1L]) / (n - 1L) else 1.0
  vapply(cuts, function(cut) {
    idx_lo <- which(mids <= cut)
    idx_hi <- which(mids > cut)
    if (length(idx_lo) == 0L) return(bar_x[1L] - step / 2)
    if (length(idx_hi) == 0L) return(bar_x[n] + step / 2)
    (bar_x[max(idx_lo)] + bar_x[min(idx_hi)]) / 2
  }, numeric(1L))
}


## Parse (lo-hi] column names (from add_total_numbers_by_haul) to a sorted numeric break vector.
.breaks_from_colnames <- function(cn) {
  stripped <- sub("^.", "", sub(".$", "", cn))   # strip leading ( and trailing ]
  parts    <- strsplit(stripped, "-")
  lo <- vapply(parts, function(p) suppressWarnings(as.numeric(p[1L])),          numeric(1L))
  hi <- vapply(parts, function(p) suppressWarnings(as.numeric(p[length(p)])),   numeric(1L))
  sort(unique(c(lo, hi)))
}


## Return a named character vector mapping AphiaID -> display name.
.get_species_labels <- function(hl, aphias) {
  nm <- intersect(c("Species", "SpeciesName", "Latin_Name", "SpecVal"), names(hl))
  if (length(nm) > 0L) {
    lkp  <- hl[!duplicated(hl$Valid_Aphia), c("Valid_Aphia", nm[1L])]
    nms  <- as.character(lkp[[nm[1L]]][match(as.character(aphias), as.character(lkp$Valid_Aphia))])
    miss <- is.na(nms) | !nzchar(nms)
    nms[miss] <- paste0("AphiaID ", aphias[miss])
    return(setNames(nms, as.character(aphias)))
  }
  si <- tryCatch(get("species_info", envir = asNamespace("DATRASextra")), error = function(e) NULL)
  if (!is.null(si) && all(c("WoRMS_AphiaID", "Species") %in% names(si))) {
    nms  <- si$Species[match(aphias, si$WoRMS_AphiaID)]
    miss <- is.na(nms)
    nms[miss] <- paste0("AphiaID ", aphias[miss])
    return(setNames(nms, as.character(aphias)))
  }
  setNames(paste0("AphiaID ", aphias), as.character(aphias))
}


## Aggregate HL$Count by species x length group -> matrix[aphias, groups].
.species_group_counts <- function(hl, aphias, grp_idx, n_grp) {
  mat <- matrix(0.0, nrow = length(aphias), ncol = n_grp,
                dimnames = list(as.character(aphias), NULL))
  ok  <- !is.na(grp_idx) & !is.na(hl$Valid_Aphia) & !is.na(hl$Count)
  for (j in seq_len(n_grp)) {
    sel <- ok & grp_idx == j
    if (!any(sel)) next
    sub <- hl[sel, ]
    agg <- tapply(sub$Count, as.character(sub$Valid_Aphia), sum, na.rm = TRUE)
    idx <- match(names(agg), rownames(mat))
    hit <- !is.na(idx)
    mat[idx[hit], j] <- agg[hit]
  }
  mat
}


## Aggregate estimated weight (a*L^b*Count) by species x length group.
.species_group_wgt <- function(hl, aphias, grp_idx, n_grp) {
  mat <- matrix(0.0, nrow = length(aphias), ncol = n_grp,
                dimnames = list(as.character(aphias), NULL))
  si <- tryCatch(get("species_info", envir = asNamespace("DATRASextra")), error = function(e) NULL)
  if (is.null(si) || !all(c("WoRMS_AphiaID", "a", "b") %in% names(si))) {
    warning("species_info not available; weight contributions cannot be computed.", call. = FALSE)
    return(mat)
  }
  si_idx  <- match(hl$Valid_Aphia, si$WoRMS_AphiaID)
  a_vec   <- si$a[si_idx]
  b_vec   <- si$b[si_idx]
  no_par  <- unique(hl$Valid_Aphia[is.na(a_vec) | is.na(b_vec)])
  if (length(no_par) > 0L)
    warning("No LW parameters for AphiaID(s) ",
            paste(no_par, collapse = ", "), "; contributing 0 g.", call. = FALSE)
  wgt_row <- a_vec * (hl$LngtCm ^ b_vec) * hl$Count
  wgt_row[!is.finite(wgt_row)] <- 0.0
  ok <- !is.na(grp_idx) & !is.na(hl$Valid_Aphia)
  for (j in seq_len(n_grp)) {
    sel <- ok & grp_idx == j
    if (!any(sel)) next
    agg <- tapply(wgt_row[sel], as.character(hl$Valid_Aphia[sel]), sum, na.rm = TRUE)
    idx <- match(names(agg), rownames(mat))
    hit <- !is.na(idx)
    mat[idx[hit], j] <- agg[hit]
  }
  mat
}


.draw_land_layer <- function(plot_map, xlim, ylim, map_scale = 50, land_layer = NULL) {
  if (!isTRUE(plot_map)) return(invisible(FALSE))

  col_land <- grDevices::adjustcolor(grey(0.97), 1)
  border_land <- grDevices::adjustcolor(grey(0.9), 1)

  if (!is.null(land_layer) && requireNamespace("sf", quietly = TRUE)) {
    try(plot(sf::st_geometry(land_layer), add = TRUE,
             col = col_land, border = border_land), silent = TRUE)
    return(invisible(TRUE))
  }

  if (exists("get_land", mode = "function") && requireNamespace("sf", quietly = TRUE)) {
    land_ll <- tryCatch(get_land(download_map = FALSE, scale = map_scale),
                        error = function(e) NULL)
    if (!is.null(land_ll)) {
      try(plot(sf::st_geometry(land_ll), add = TRUE,
               col = col_land, border = border_land), silent = TRUE)
      return(invisible(TRUE))
    }
  }

  if (requireNamespace("maps", quietly = TRUE)) {
    maps::map("world", add = TRUE, fill = TRUE,
              col = col_land, border = border_land, xlim = xlim, ylim = ylim)
    return(invisible(TRUE))
  }

  invisible(FALSE)
}


.fetch_land_layer <- function(plot_map, map_scale = 50) {
  if (!isTRUE(plot_map)) return(NULL)
  if (!exists("get_land", mode = "function") || !requireNamespace("sf", quietly = TRUE))
    return(NULL)
  land <- tryCatch(get_land(download_map = FALSE, scale = map_scale),
                   error = function(e) NULL)
  if (is.null(land)) return(NULL)
  land
}


.as_hh_data <- function(x = NULL) {
  if (is.null(x)) {

    hh <- get("survey_info_full_raw", envir = asNamespace("DATRASextra"))

    if (is.null(hh)) {
      stop("Could not load `survey_info_full_raw` from DATRASextra.", call. = FALSE)
    }
    return(as.data.frame(hh, stringsAsFactors = FALSE))
  }

  if (is.list(x) && !is.null(x[["HH"]])) {
    return(as.data.frame(x[["HH"]], stringsAsFactors = FALSE))
  }

  stop("`x` must be NULL or a DATRAS-like list with `x[['HH']]`.", call. = FALSE)
}


.resolve_xy_cols <- function(hh) {
  if (all(c("lon", "lat") %in% names(hh))) return(c("lon", "lat"))
  if (all(c("ShootLong", "ShootLat") %in% names(hh))) return(c("ShootLong", "ShootLat"))
  stop("HH must contain either lon/lat or ShootLong/ShootLat columns.", call. = FALSE)
}

.prepare_spatial_basis <- function(hh, spatial_basis = c("raw", "statrec")) {
  spatial_basis <- match.arg(spatial_basis)
  if (identical(spatial_basis, "raw")) {
    xy <- .resolve_xy_cols(hh)
    hh$lon <- suppressWarnings(as.numeric(hh[[xy[1]]]))
    hh$lat <- suppressWarnings(as.numeric(hh[[xy[2]]]))
    hh <- hh[is.finite(hh$lon) & is.finite(hh$lat), , drop = FALSE]
    return(hh)
  }

  if (!("StatRec" %in% names(hh))) {
    stop("`spatial_basis = 'statrec'` requires HH column `StatRec`.", call. = FALSE)
  }

  coord_fun <- NULL
  if (exists("icesSquare2coord", mode = "function")) {
    coord_fun <- get("icesSquare2coord", mode = "function")
  } else if (requireNamespace("DATRAS", quietly = TRUE) && exists("icesSquare2coord", envir = asNamespace("DATRAS"), inherits = FALSE)) {
    coord_fun <- get("icesSquare2coord", envir = asNamespace("DATRAS"), inherits = FALSE)
  }
  if (is.null(coord_fun)) {
    stop("`spatial_basis = 'statrec'` requires `icesSquare2coord` (install/load package DATRAS).", call. = FALSE)
  }

  hh$StatRec <- trimws(as.character(hh$StatRec))
  bad_code <- is.na(hh$StatRec) | !nzchar(hh$StatRec) | hh$StatRec == "-9"
  hh <- hh[!bad_code, , drop = FALSE]

  sq <- unique(hh$StatRec)
  mid_list <- lapply(sq, function(code) {
    one <- tryCatch(coord_fun(code, "midpoint"), error = function(e) NULL)
    if (is.null(one)) return(NULL)
    df <- as.data.frame(one, stringsAsFactors = FALSE)
    df$StatRec <- code
    df
  })
  mid_list <- Filter(Negate(is.null), mid_list)
  if (length(mid_list) == 0) {
    stop("Failed to convert any StatRec values to midpoint coordinates.", call. = FALSE)
  }
  mid <- do.call(rbind, mid_list)
  dropped <- setdiff(sq, mid$StatRec)
  if (length(dropped) > 0) {
    warning(sprintf("Dropped %s invalid StatRec code(s) during midpoint conversion.", length(dropped)), call. = FALSE)
  }
  hh <- hh[, !(names(hh) %in% c("lon", "lat")), drop = FALSE]
  hh <- merge(hh, mid[, c("StatRec", "lon", "lat")], by = "StatRec", all.x = TRUE)
  hh <- hh[is.finite(hh$lon) & is.finite(hh$lat), , drop = FALSE]
  hh
}


.compute_value <- function(hh, value_var = NULL, offset_var = NULL, transform = "none") {
  if (is.null(value_var)) {
    val <- if ("Hauls" %in% names(hh)) suppressWarnings(as.numeric(hh$Hauls)) else rep(1, nrow(hh))
  } else {
    if (!(value_var %in% names(hh))) stop("`value_var` not found in HH: ", value_var, call. = FALSE)
    val <- suppressWarnings(as.numeric(hh[[value_var]]))
  }

  if (!is.null(offset_var)) {
    if (!(offset_var %in% names(hh))) stop("`offset_var` not found in HH: ", offset_var, call. = FALSE)
    off <- suppressWarnings(as.numeric(hh[[offset_var]]))
    bad <- !is.finite(off) | off == 0
    val[bad] <- NA_real_
    val[!bad] <- val[!bad] / off[!bad]
  }

  out <- val
  if (identical(transform, "log1p")) out <- log1p(out)
  if (identical(transform, "sqrt")) out <- sqrt(out)
  if (identical(transform, "log10")) out <- log10(out)
  out[!is.finite(out)] <- NA_real_
  out
}

.back_transform <- function(x, transform) {
  switch(transform,
    log1p = expm1(x),
    sqrt = x^2,
    log10 = 10^x,
    x
  )
}


.build_group <- function(hh, by_survey, by_gear, by_quarter, by_year, by_daynight) {
  dims <- character(0)
  if (isTRUE(by_survey)) dims <- c(dims, "Survey")
  if (isTRUE(by_gear)) dims <- c(dims, "Gear")
  if (isTRUE(by_quarter)) dims <- c(dims, "Quarter")
  if (isTRUE(by_year)) dims <- c(dims, "Year")
  if (isTRUE(by_daynight)) dims <- c(dims, "DayNight")

  if (length(dims) == 0) return(factor(rep("All", nrow(hh))))
  miss <- setdiff(dims, names(hh))
  if (length(miss) > 0) stop("Grouping columns missing in HH: ", paste(miss, collapse = ", "), call. = FALSE)

  cols <- lapply(dims, function(d) {
    v <- trimws(as.character(hh[[d]]))
    v[is.na(v) | !nzchar(v)] <- "NA"
    if (identical(d, "Quarter")) v <- paste0("Q", v)
    paste0(d, "=", v)
  })
  factor(do.call(paste, c(cols, list(sep = " | "))))
}


.group_dims_active <- function(by_survey, by_gear, by_quarter, by_year, by_daynight) {
  dims <- character(0)
  if (isTRUE(by_survey)) dims <- c(dims, "Survey")
  if (isTRUE(by_gear)) dims <- c(dims, "Gear")
  if (isTRUE(by_quarter)) dims <- c(dims, "Quarter")
  if (isTRUE(by_year)) dims <- c(dims, "Year")
  if (isTRUE(by_daynight)) dims <- c(dims, "DayNight")
  dims
}


.format_group_legend <- function(group_levels, active_dims) {
  if (length(active_dims) == 1) {
    dim <- active_dims[1]
    prefix <- paste0(dim, "=")
    labels <- sub(paste0("^", prefix), "", group_levels)
    title_map <- c(
      Survey = "Surveys",
      Gear = "Gears",
      Quarter = "Quarters",
      Year = "Years",
      DayNight = "Day/Night"
    )
    ttl <- unname(title_map[dim])
    if (is.na(ttl) || !nzchar(ttl)) ttl <- "Groups"
    return(list(title = ttl, labels = labels))
  }

  labels <- gsub("(Survey|Gear|Quarter|Year|DayNight)=", "", group_levels)
  list(title = "Groups", labels = labels)
}


.make_grid <- function(hh, x_col = "lon", y_col = "lat", grid_resolution = c(1, 0.5)) {
  lon <- suppressWarnings(as.numeric(hh[[x_col]]))
  lat <- suppressWarnings(as.numeric(hh[[y_col]]))

  lon_step <- grid_resolution[1]
  lat_step <- grid_resolution[2]

  lon0 <- floor(min(lon, na.rm = TRUE) / lon_step) * lon_step
  lon1 <- ceiling(max(lon, na.rm = TRUE) / lon_step) * lon_step
  lat0 <- floor(min(lat, na.rm = TRUE) / lat_step) * lat_step
  lat1 <- ceiling(max(lat, na.rm = TRUE) / lat_step) * lat_step

  lon_breaks <- seq(lon0 - lon_step / 2, lon1 + lon_step / 2, by = lon_step)
  lat_breaks <- seq(lat0 - lat_step / 2, lat1 + lat_step / 2, by = lat_step)

  hh$lon_bin <- cut(hh[[x_col]], breaks = lon_breaks,
                    labels = seq(lon0, lon1, by = lon_step), include.lowest = TRUE)
  hh$lat_bin <- cut(hh[[y_col]], breaks = lat_breaks,
                    labels = seq(lat0, lat1, by = lat_step), include.lowest = TRUE)

  list(data = hh,
       xlim = c(lon0 - lon_step / 2, lon1 + lon_step / 2),
       ylim = c(lat0 - lat_step / 2, lat1 + lat_step / 2))
}


.aggregate_grid <- function(hh, metric, hl = NULL) {
  if (identical(metric, "sum")) {
    out <- aggregate(hh$.value, by = list(lon_bin = hh$lon_bin, lat_bin = hh$lat_bin), FUN = function(z) sum(z, na.rm = TRUE))
    names(out)[3] <- "z"
  } else if (identical(metric, "mean")) {
    out <- aggregate(hh$.value, by = list(lon_bin = hh$lon_bin, lat_bin = hh$lat_bin), FUN = function(z) mean(z, na.rm = TRUE))
    names(out)[3] <- "z"
  } else if (identical(metric, "count_hauls")) {
    out <- aggregate(rep(1, nrow(hh)), by = list(lon_bin = hh$lon_bin, lat_bin = hh$lat_bin), FUN = length)
    names(out)[3] <- "z"
  } else if (identical(metric, "presence")) {
    out <- aggregate(rep(1, nrow(hh)), by = list(lon_bin = hh$lon_bin, lat_bin = hh$lat_bin), FUN = function(z) 1)
    names(out)[3] <- "z"
  } else if (identical(metric, "count_surveys")) {
    if (!("Survey" %in% names(hh))) stop("`metric = 'count_surveys'` requires HH column `Survey`.", call. = FALSE)
    key <- paste(hh$lon_bin, hh$lat_bin)
    spl <- split(hh$Survey, key)
    z <- vapply(spl, function(v) length(unique(v)), integer(1))
    parts <- strsplit(names(z), " ", fixed = TRUE)
    out <- data.frame(
      lon_bin = factor(vapply(parts, `[`, character(1), 1), levels = levels(hh$lon_bin)),
      lat_bin = factor(vapply(parts, `[`, character(1), 2), levels = levels(hh$lat_bin)),
      z = as.numeric(z),
      stringsAsFactors = FALSE
    )
  } else if (identical(metric, "species_richness")) {
    if (is.null(hl))
      stop("`metric = 'species_richness'` requires `hl` to be passed to `.aggregate_grid()`.", call. = FALSE)
    haul_ids <- unique(hh$haul.id)
    hl_sub <- hl[hl$haul.id %in% haul_ids, c("haul.id", "Valid_Aphia"), drop = FALSE]
    hl_binned <- merge(hh[, c("haul.id", "lon_bin", "lat_bin"), drop = FALSE],
                       hl_sub, by = "haul.id", all.x = FALSE)
    cell_key <- paste(hl_binned$lon_bin, hl_binned$lat_bin)
    cell_rich <- vapply(split(hl_binned$Valid_Aphia, cell_key),
                        function(v) length(unique(v[!is.na(v)])), integer(1))
    parts <- strsplit(names(cell_rich), " ", fixed = TRUE)
    out <- data.frame(
      lon_bin = factor(vapply(parts, `[`, character(1), 1), levels = levels(hh$lon_bin)),
      lat_bin = factor(vapply(parts, `[`, character(1), 2), levels = levels(hh$lat_bin)),
      z = as.numeric(cell_rich),
      stringsAsFactors = FALSE
    )
  } else {
    stop("Unsupported metric: ", metric, call. = FALSE)
  }

  template <- expand.grid(
    lon_bin = levels(hh$lon_bin),
    lat_bin = levels(hh$lat_bin),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  template$lon_bin <- factor(template$lon_bin, levels = levels(hh$lon_bin))
  template$lat_bin <- factor(template$lat_bin, levels = levels(hh$lat_bin))

  out <- merge(template, out, by = c("lon_bin", "lat_bin"), all.x = TRUE)
  out
}

.plot_grid_panel <- function(hh, metric, col, zlim, plot_map, xlim, ylim, asp = NULL, main = NULL, panel_label = NULL, show_x_axis = TRUE, show_y_axis = TRUE, palette_rev = FALSE, map_scale = 50, hl = NULL, transform = "none", land_layer = NULL) {
  agg <- .aggregate_grid(hh, metric = metric, hl = hl)
  mat <- xtabs(z ~ lon_bin + lat_bin, data = agg)

  xvals <- as.numeric(rownames(mat))
  yvals <- as.numeric(colnames(mat))
  ox <- order(xvals)
  oy <- order(yvals)
  mat <- mat[ox, oy, drop = FALSE]
  xvals <- xvals[ox]
  yvals <- yvals[oy]

  plot(
    NA,
    xlim = xlim,
    ylim = ylim,
    asp = asp,
    xlab = "",
    ylab = "",
    las = 1,
    xaxt = if (isTRUE(show_x_axis)) "s" else "n",
    yaxt = if (isTRUE(show_y_axis)) "s" else "n",
    main = main
  )

  finite_vals <- as.numeric(mat[is.finite(mat)])
  maxz <- if (length(finite_vals) > 0) max(finite_vals) else 0

  if (identical(metric, "presence")) {
    breaks <- c(0.5, 1.5)
    use_col <- col[1]
    legend_labels <- "sampled cells"
    legend_cols <- use_col[1]
  } else if (metric %in% c("count_hauls", "count_surveys", "species_richness")) {
    uniq <- sort(unique(finite_vals))
    if (length(uniq) == 0) uniq <- 0
    breaks <- c(uniq - 0.5, max(uniq) + 0.5)
    use_col <- .colours_datrasextra_discrete(length(uniq), rev = palette_rev)
    legend_labels <- as.character(uniq)
    legend_cols <- use_col
  } else {
    if (is.null(zlim)) zlim <- c(0, maxz)
    if (zlim[2] <= zlim[1]) zlim[2] <- zlim[1] + 1
    nb <- min(7, length(col))
    breaks <- seq(zlim[1], zlim[2], length.out = nb + 1)
    use_col <- col[seq_len(nb)]
    disp <- .back_transform(breaks, transform)
    legend_labels <- paste0("[", format(signif(disp[-length(disp)], 3), trim = TRUE), ", ",
                            format(signif(disp[-1], 3), trim = TRUE), ")")
    legend_cols <- use_col
  }

  image(xvals, yvals, mat, add = TRUE, col = use_col, breaks = breaks)
  .draw_land_layer(plot_map = plot_map, xlim = xlim, ylim = ylim, map_scale = map_scale,
                   land_layer = land_layer)
  if (!is.null(panel_label) && nzchar(panel_label)) {
    graphics::legend("topleft", legend = panel_label, pch = NA, bg = "white",
                     x.intersp = -0.3)
  }
  box(lwd = 1.2)
  invisible(list(maxz = maxz, breaks = breaks, use_col = use_col, legend_labels = legend_labels, legend_cols = legend_cols))
}


.plot_grid_group_panel <- function(hh, group_cols, strategy = c("dominant", "mixed", "error"), plot_map, xlim, ylim, asp = NULL, main = NULL, panel_label = NULL, show_x_axis = TRUE, show_y_axis = TRUE, map_scale = 50, land_layer = NULL) {
  strategy <- match.arg(strategy)

  counts <- aggregate(rep(1, nrow(hh)), by = list(lon_bin = hh$lon_bin, lat_bin = hh$lat_bin, group = hh$.group), FUN = length)
  names(counts)[4] <- "n"
  split_cells <- split(counts, interaction(counts$lon_bin, counts$lat_bin, drop = TRUE))

  pick <- lapply(split_cells, function(df) {
    mx <- max(df$n)
    top <- df[df$n == mx, , drop = FALSE]
    if (nrow(top) == 1) {
      data.frame(lon_bin = top$lon_bin[1], lat_bin = top$lat_bin[1], group = as.character(top$group[1]), stringsAsFactors = FALSE)
    } else {
      if (identical(strategy, "error")) {
        stop("Ambiguous grouped grid cells found (multiple groups per cell). Use `grid_group_strategy = 'dominant'` or `'mixed'`, or `multi_panels = TRUE`.", call. = FALSE)
      }
      if (identical(strategy, "mixed")) {
        data.frame(lon_bin = top$lon_bin[1], lat_bin = top$lat_bin[1], group = "Mixed", stringsAsFactors = FALSE)
      } else {
        g <- sort(as.character(top$group))[1]
        data.frame(lon_bin = top$lon_bin[1], lat_bin = top$lat_bin[1], group = g, stringsAsFactors = FALSE)
      }
    }
  })

  chosen <- do.call(rbind, pick)
  g_levels <- names(group_cols)
  if (identical(strategy, "mixed") && any(chosen$group == "Mixed")) {
    g_levels <- c(g_levels, "Mixed")
    group_cols <- c(group_cols, Mixed = "#8C8C8C")
  }

  chosen$group <- factor(chosen$group, levels = g_levels)
  chosen$gnum <- as.numeric(chosen$group)

  template <- expand.grid(
    lon_bin = levels(hh$lon_bin),
    lat_bin = levels(hh$lat_bin),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  template$lon_bin <- factor(template$lon_bin, levels = levels(hh$lon_bin))
  template$lat_bin <- factor(template$lat_bin, levels = levels(hh$lat_bin))

  agg <- merge(template, chosen[, c("lon_bin", "lat_bin", "gnum")], by = c("lon_bin", "lat_bin"), all.x = TRUE)
  mat <- xtabs(gnum ~ lon_bin + lat_bin, data = agg)
  xvals <- as.numeric(rownames(mat))
  yvals <- as.numeric(colnames(mat))
  ox <- order(xvals)
  oy <- order(yvals)
  mat <- mat[ox, oy, drop = FALSE]
  xvals <- xvals[ox]
  yvals <- yvals[oy]

  plot(
    NA,
    xlim = xlim,
    ylim = ylim,
    asp = asp,
    xlab = "",
    ylab = "",
    las = 1,
    xaxt = if (isTRUE(show_x_axis)) "s" else "n",
    yaxt = if (isTRUE(show_y_axis)) "s" else "n",
    main = main
  )
  image(
    xvals,
    yvals,
    mat,
    add = TRUE,
    col = unname(group_cols[g_levels]),
    breaks = seq(0.5, length(g_levels) + 0.5, by = 1)
  )
  .draw_land_layer(plot_map = plot_map, xlim = xlim, ylim = ylim, map_scale = map_scale,
                   land_layer = land_layer)
  if (!is.null(panel_label) && nzchar(panel_label)) {
    graphics::legend("topleft", legend = panel_label, pch = NA, bg = "white",
                     x.intersp = -0.3)
  }
  box(lwd = 1.2)

  list(
    breaks = seq(0.5, length(g_levels) + 0.5, by = 1),
    use_col = unname(group_cols[g_levels]),
    legend_labels = g_levels,
    legend_cols = unname(group_cols[g_levels])
  )
}

.plot_points_panel <- function(hh, x_col, y_col, col_vec, cex_vec, pch, plot_map, xlim, ylim, asp = NULL, main = NULL, panel_label = NULL, show_x_axis = TRUE, show_y_axis = TRUE, map_scale = 50, land_layer = NULL) {
  plot(
    NA,
    xlim = xlim,
    ylim = ylim,
    asp = asp,
    xlab = "",
    ylab = "",
    las = 1,
    xaxt = if (isTRUE(show_x_axis)) "s" else "n",
    yaxt = if (isTRUE(show_y_axis)) "s" else "n",
    main = main
  )
  .draw_land_layer(plot_map = plot_map, xlim = xlim, ylim = ylim, map_scale = map_scale,
                   land_layer = land_layer)
  points(hh[[x_col]], hh[[y_col]], pch = pch, cex = cex_vec, col = col_vec)
  if (!is.null(panel_label) && nzchar(panel_label)) {
    graphics::legend("topleft", legend = panel_label, pch = NA, bg = "white",
                     x.intersp = -0.3)
  }
  box(lwd = 1.2)
}
