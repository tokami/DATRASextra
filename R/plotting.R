
## Main functions ----------------------------------------------------------------

#' Unified DATRAS overview plotting
#'
#' Plots spatial overviews from DATRAS haul data using gridded image maps or
#' point maps, with optional grouping and faceting.
#'
#' @param x A DATRAS-like object containing `x[['HH']]`, or `NULL` to use
#'   `DATRASextra::survey_info_full_raw` (fallback `survey_info_full`).
#' @param mode Plot mode: `"grid"` or `"points"`. Default is `"points"`.
#' @param metric Grid metric: `"sum"`, `"mean"`, `"count_hauls"`,
#'   `"presence"`, or `"count_surveys"`.
#' @param spatial_basis Spatial basis used for coordinates: `"raw"` uses haul
#'   coordinates, `"statrec"` uses ICES rectangle midpoints from `StatRec`.
#' @param by_survey,by_gear,by_quarter,by_year,by_daynight Logical grouping
#'   toggles used to define panel groups.
#' @param multi_panels Logical. If `TRUE`, plot one group per panel.
#' @param value_var Optional haul-level variable to map to values.
#' @param offset_var Optional haul-level denominator variable.
#' @param transform Value transform: `"none"`, `"log1p"`, `"sqrt"`, `"log10"`.
#' @param fixed_scale Logical. Use common color scale across panels in grid mode.
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
#' @param legend_outside Logical. If `TRUE`, draw the legend outside the main
#'   plotting panel area. For multi-panel layouts, a free panel is used when
#'   available; otherwise a narrow right-side legend panel is created.
#' @param max_legend_items Maximum number of group legend entries.
#' @param max_grid_legend_levels Maximum number of levels shown in grid legends.
#' @param legend_ncol Number of columns in legend
#' @param legend_pos position of legend. Default: NULL.
#' @param legend_cex cex of legend. Default: NULL.
#' @param grid_group_strategy Strategy for grouped single-panel grid maps when
#'   multiple groups occur in the same cell: `"dominant"`, `"mixed"`, or
#'   `"error"`.
#' @param main Optional title for single-panel mode.
#'
#' @return Invisibly returns list with processed data and plotting metadata.
#' @export
plot_datras_overview <- function(
  x = NULL,
  mode = c("points", "grid"),
  metric = c("presence", "sum", "mean", "count_hauls", "count_surveys"),
  spatial_basis = c("raw", "statrec"),
  by_survey = FALSE,
  by_gear = FALSE,
  by_quarter = FALSE,
  by_year = FALSE,
  by_daynight = FALSE,
  multi_panels = FALSE,
  value_var = NULL,
  offset_var = NULL,
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
  legend_outside = FALSE,
  max_legend_items = 30,
  max_grid_legend_levels = 5,
  legend_ncol = 1,
  legend_pos = NULL,
  legend_cex = NULL,
  grid_group_strategy = c("dominant", "mixed", "error"),
  main = NULL
) {
  mode <- match.arg(mode)
  metric <- match.arg(metric)
  spatial_basis <- match.arg(spatial_basis)
  transform <- match.arg(transform)
  legend_mode <- match.arg(legend_mode)
  grid_group_strategy <- match.arg(grid_group_strategy)

  hh <- .as_hh_data(x)
  hh <- .prepare_spatial_basis(hh, spatial_basis = spatial_basis)
  x_col <- "lon"
  y_col <- "lat"
  if (nrow(hh) == 0) stop("No finite coordinate rows in HH.", call. = FALSE)

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
  hh$.group <- .build_group(hh, by_survey, by_gear, by_quarter, by_year, by_daynight)
  has_grouping <- any(c(by_survey, by_gear, by_quarter, by_year, by_daynight))
  active_dims <- .group_dims_active(by_survey, by_gear, by_quarter, by_year, by_daynight)

  group_cols <- NULL
  if (has_grouping) {
    lev <- levels(hh$.group)
    group_cols <- .colours_datrasextra_discrete(length(lev), rev = palette_rev)
    names(group_cols) <- lev
  }

  if (!is.null(xlim)) hh <- hh[hh[[x_col]] >= xlim[1] & hh[[x_col]] <= xlim[2], , drop = FALSE]
  if (!is.null(ylim)) hh <- hh[hh[[y_col]] >= ylim[1] & hh[[y_col]] <= ylim[2], , drop = FALSE]
  if (nrow(hh) == 0) stop("No rows left after applying xlim/ylim.", call. = FALSE)

  grid_info <- .make_grid(hh, x_col = x_col, y_col = y_col)
  hh <- grid_info$data
  if (is.null(xlim)) xlim <- grid_info$xlim
  if (is.null(ylim)) ylim <- grid_info$ylim

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
    ordered_panel_levels <- c(sapply(other_levels, function(g) paste0(g, ":::", value_col_names)))
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
    names(split_list) <- c(sapply(clean_other, function(g)
      if (nzchar(g)) paste0(g, ": ", value_col_names) else value_col_names))
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
      ag <- .aggregate_grid(d, metric = metric)
      v <- ag$z[is.finite(ag$z)]
      if (length(v) == 0) 0 else max(v)
    }, numeric(1))
    zlim <- c(0, max(max_vals, na.rm = TRUE))
  }

  global_points_value_range <- NULL
  if (!identical(mode, "grid") && isTRUE(multi_panels) && !is.null(value_var)) {
    gv <- hh$.value[is.finite(hh$.value)]
    if (length(gv) >= 2 && diff(range(gv)) > 0) global_points_value_range <- range(gv)
  }

  outside_active <- isTRUE(legend_outside) && isTRUE(legend) && !identical(legend_mode, "none")
  n_panels <- length(split_list)
  if (lc_multi_panels) {
    mf <- c(length(levels(hh$.group)), length(value_col_names))
  } else {
    mf <- if (n_panels > 1) grDevices::n2mfrow(n_panels) else c(1, 1)
  }
  panel_capacity <- prod(mf)
  use_empty_panel_for_legend <- outside_active && n_panels > 1 && panel_capacity > n_panels
  use_side_panel_for_legend <- outside_active && !use_empty_panel_for_legend

  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)

  if (use_side_panel_for_legend) {
    left_mat <- matrix(seq_len(panel_capacity), nrow = mf[1], ncol = mf[2], byrow = TRUE)
    legend_id <- panel_capacity + 1L
    lay <- cbind(left_mat, rep(legend_id, mf[1]))
    graphics::layout(lay, widths = c(rep(1, mf[2]), 0.9))
    par(mar = c(0.3, 0.3, 0.3, 0.3), oma = c(4.2, 4.2, 0.4, 0))
  } else {
    par(mfrow = mf, mar = c(0.3, 0.3, 0.3, 0.3), oma = c(4.2, 4.2, 0.4, 1))
  }

  panel_meta <- vector("list", length(split_list))
  names(panel_meta) <- names(split_list)

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
        panel_meta[[nm]] <- .plot_grid_group_panel(
          hh = d,
          group_cols = group_cols,
          strategy = grid_group_strategy,
          plot_map = plot_map,
          xlim = lim$x,
          ylim = lim$y,
          main = panel_title,
          panel_label = panel_label,
          show_x_axis = show_x_axis,
          show_y_axis = show_y_axis
        )
      } else {
        panel_meta[[nm]] <- .plot_grid_panel(
          hh = d,
          metric = metric,
          col = col,
          zlim = zlim,
          plot_map = plot_map,
          xlim = lim$x,
          ylim = lim$y,
          main = panel_title,
          panel_label = panel_label,
          show_x_axis = show_x_axis,
          show_y_axis = show_y_axis
        )
      }
    } else {
      val <- d$.value
      rng <- range(val, na.rm = TRUE)
      points_value_meta <- NULL
      if (has_grouping && !isTRUE(multi_panels)) {
        pcol <- grDevices::adjustcolor(group_cols[as.character(d$.group)], alpha.f = alpha)
        if (!is.null(value_var) && !identical(metric, "presence") && is.finite(rng[1]) && is.finite(rng[2]) && rng[1] != rng[2]) {
          scaled <- (val - rng[1]) / (rng[2] - rng[1])
          pcex <- size_range[1] + scaled * (size_range[2] - size_range[1])
          pcex[!is.finite(pcex)] <- cex
          points_value_meta <- list(size_range = size_range)
        } else {
          pcex <- rep(cex, nrow(d))
        }
      } else if (identical(metric, "presence") || !is.finite(rng[1]) || !is.finite(rng[2]) || rng[1] == rng[2]) {
        pcol <- rep(grDevices::adjustcolor(.colours_datrasextra_continuous(10, rev = palette_rev)[1], alpha.f = alpha), nrow(d))
        pcex <- rep(cex, nrow(d))
      } else {
        scale_rng <- if (!is.null(global_points_value_range)) global_points_value_range else rng
        brk <- seq(scale_rng[1], scale_rng[2], length.out = length(col) + 1)
        idx <- cut(val, breaks = brk, include.lowest = TRUE, labels = FALSE)
        idx[is.na(idx)] <- 1L
        pcol <- grDevices::adjustcolor(col[idx], alpha.f = alpha)
        scaled <- pmax(0, pmin(1, (val - scale_rng[1]) / (scale_rng[2] - scale_rng[1])))
        pcex <- size_range[1] + scaled * (size_range[2] - size_range[1])
        pcex[!is.finite(pcex)] <- cex
        points_value_meta <- list(col = col, size_range = size_range, scale_rng = scale_rng)
      }

      .plot_points_panel(
        hh = d,
        x_col = x_col,
        y_col = y_col,
        col_vec = pcol,
        cex_vec = pcex,
        pch = pch,
        plot_map = plot_map,
        xlim = lim$x,
        ylim = lim$y,
        main = panel_title,
        panel_label = panel_label,
        show_x_axis = show_x_axis,
        show_y_axis = show_y_axis
      )
      panel_meta[[nm]] <- list(value_range = rng, points_value_meta = points_value_meta)
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
          if (length(info$legend_labels) <= max_legend_items) {
            lg <- .format_group_legend(info$legend_labels, active_dims = active_dims)
            leg_payload <- list(legend = lg$labels, col = info$legend_cols, title = lg$title, cex = 0.7)
          }
        } else if (identical(metric, "presence")) {
          leg_payload <- list(legend = info$legend_labels, col = info$legend_cols, title = metric, cex = 0.8)
        } else {
          leg_labels <- info$legend_labels
          leg_cols <- info$legend_cols

          if (metric %in% c("count_hauls", "count_surveys") && length(leg_labels) > max_grid_legend_levels) {
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
        auto = (!isTRUE(multi_panels) && any(c(by_survey, by_gear, by_quarter, by_year, by_daynight))),
        global = (any(c(by_survey, by_gear, by_quarter, by_year, by_daynight)) &&
                    !(isTRUE(multi_panels) && !is.null(value_var))),
        per_panel = FALSE,
        FALSE
      )
      if (show_points_legend) {
        lev <- levels(hh$.group)
        if (length(lev) <= max_legend_items) {
          leg_cols <- if (!is.null(group_cols)) group_cols[lev] else rep("grey30", length(lev))
          lg <- .format_group_legend(lev, active_dims = active_dims)
          leg_payload <- list(legend = lg$labels, col = leg_cols, title = lg$title, cex = 0.7)
        }
      }
      if (!is.null(value_var)) {
        info <- panel_meta[[1]]
        if (!is.null(info$points_value_meta) && is.finite(info$value_range[1]) && is.finite(info$value_range[2])) {
          meta <- info$points_value_meta
          rng_leg <- if (!is.null(meta$scale_rng)) meta$scale_rng else info$value_range
          n_ref <- 5
          ref_vals <- seq(rng_leg[1], rng_leg[2], length.out = n_ref)
          ref_scaled <- (ref_vals - rng_leg[1]) / (rng_leg[2] - rng_leg[1])
          ref_cex <- meta$size_range[1] + ref_scaled * (meta$size_range[2] - meta$size_range[1])
          ref_labels <- format(signif(ref_vals, 3), trim = TRUE)
          leg_title <- if (!is.null(offset_var)) paste0(value_var, " / ", offset_var) else value_var
          if (!has_grouping || isTRUE(multi_panels)) {
            ref_idx <- pmax(1L, pmin(length(meta$col), round(1 + ref_scaled * (length(meta$col) - 1))))
            ref_cols <- grDevices::adjustcolor(meta$col[ref_idx], alpha.f = alpha)
            leg_payload <- list(legend = ref_labels, col = ref_cols, title = leg_title, cex = 0.7,
                                pt.cex = ref_cex, pch = pch)
          } else {
            size_leg_payload <- list(legend = ref_labels, col = rep("grey30", n_ref),
                                     title = leg_title, cex = 0.7, pt.cex = ref_cex, pch = pch)
          }
        }
      }
    }

    if (!is.null(leg_payload)) {
      if (outside_active) {
        if (use_empty_panel_for_legend) {
          plot.new()
        } else if (use_side_panel_for_legend) {
          plot.new()
        }
        if (!is.null(legend_cex)) leg_payload$cex <- legend_cex
        graphics::legend("center", legend = leg_payload$legend,
                         pch = if (!is.null(leg_payload$pch)) leg_payload$pch else 15,
                         pt.cex = if (!is.null(leg_payload$pt.cex)) leg_payload$pt.cex else 1,
                         col = leg_payload$col, cex = leg_payload$cex, bg = "white",
                         title = leg_payload$title, ncol = legend_ncol)
      } else {
        if (is.null(legend_pos)) {
          pos <- if (identical(mode, "grid")) "bottomright" else "topright"
        } else {
          pos <- legend_pos
        }
        if (!is.null(legend_cex)) leg_payload$cex <- legend_cex
        graphics::legend(pos, legend = leg_payload$legend,
                         pch = if (!is.null(leg_payload$pch)) leg_payload$pch else 15,
                         pt.cex = if (!is.null(leg_payload$pt.cex)) leg_payload$pt.cex else 1,
                         col = leg_payload$col, cex = leg_payload$cex, bg = "white",
                         title = leg_payload$title, ncol = legend_ncol)
      }
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

  invisible(list(
    data = hh,
    mode = mode,
    metric = metric,
    spatial_basis = spatial_basis,
    transform = transform,
    groups = levels(hh$.group),
    panels = names(split_list),
    x_col = x_col,
    y_col = y_col
  ))
}



## Internal functions ------------------------------------------------------------

.draw_land_layer <- function(plot_map, xlim, ylim) {
  if (!isTRUE(plot_map)) return(invisible(FALSE))

  col_land <- grDevices::adjustcolor(grey(0.9), 0.7)
  border_land <- grDevices::adjustcolor(grey(0.6), 0.5)

  if (exists("get_land", mode = "function") && requireNamespace("sf", quietly = TRUE)) {
    land_ll <- tryCatch(get_land(download_map = FALSE, scale = 50),
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


.make_grid <- function(hh, x_col = "lon", y_col = "lat") {
  lon <- suppressWarnings(as.numeric(hh[[x_col]]))
  lat <- suppressWarnings(as.numeric(hh[[y_col]]))

  lon0 <- floor(min(lon, na.rm = TRUE))
  lon1 <- ceiling(max(lon, na.rm = TRUE))
  lat0 <- floor(min(lat, na.rm = TRUE) * 2) / 2
  lat1 <- ceiling(max(lat, na.rm = TRUE) * 2) / 2

  lon_breaks <- seq(lon0 - 0.5, lon1 + 0.5, by = 1)
  lat_breaks <- seq(lat0 - 0.25, lat1 + 0.25, by = 0.5)

  hh$lon_bin <- cut(hh[[x_col]], breaks = lon_breaks, labels = seq(lon0, lon1, by = 1), include.lowest = TRUE)
  hh$lat_bin <- cut(hh[[y_col]], breaks = lat_breaks, labels = seq(lat0, lat1, by = 0.5), include.lowest = TRUE)

  list(data = hh, xlim = c(lon0 - 0.5, lon1 + 0.5), ylim = c(lat0 - 0.25, lat1 + 0.25))
}


.aggregate_grid <- function(hh, metric) {
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

.plot_grid_panel <- function(hh, metric, col, zlim, plot_map, xlim, ylim, main = NULL, panel_label = NULL, show_x_axis = TRUE, show_y_axis = TRUE, palette_rev = TRUE) {
  agg <- .aggregate_grid(hh, metric = metric)
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
    xlab = "",
    ylab = "",
    asp = 1,
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
  } else if (metric %in% c("count_hauls", "count_surveys")) {
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
    legend_labels <- paste0("[", round(breaks[-length(breaks)], 2), ", ", round(breaks[-1], 2), ")")
    legend_cols <- use_col
  }

  image(xvals, yvals, mat, add = TRUE, col = use_col, breaks = breaks)
  .draw_land_layer(plot_map = plot_map, xlim = xlim, ylim = ylim)
  if (!is.null(panel_label) && nzchar(panel_label)) {
    graphics::legend("topleft", legend = panel_label, pch = NA, bg = "white",
                     x.intersp = -0.3)
  }
  box(lwd = 1.2)
  invisible(list(maxz = maxz, breaks = breaks, use_col = use_col, legend_labels = legend_labels, legend_cols = legend_cols))
}


.plot_grid_group_panel <- function(hh, group_cols, strategy = c("dominant", "mixed", "error"), plot_map, xlim, ylim, main = NULL, panel_label = NULL, show_x_axis = TRUE, show_y_axis = TRUE) {
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
    xlab = "",
    ylab = "",
    asp = 1,
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
  .draw_land_layer(plot_map = plot_map, xlim = xlim, ylim = ylim)
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

.plot_points_panel <- function(hh, x_col, y_col, col_vec, cex_vec, pch, plot_map, xlim, ylim, main = NULL, panel_label = NULL, show_x_axis = TRUE, show_y_axis = TRUE) {
  plot(
    NA,
    xlim = xlim,
    ylim = ylim,
    xlab = "",
    ylab = "",
    asp = 1,
    las = 1,
    xaxt = if (isTRUE(show_x_axis)) "s" else "n",
    yaxt = if (isTRUE(show_y_axis)) "s" else "n",
    main = main
  )
  .draw_land_layer(plot_map = plot_map, xlim = xlim, ylim = ylim)
  points(hh[[x_col]], hh[[y_col]], pch = pch, cex = cex_vec, col = col_vec)
  if (!is.null(panel_label) && nzchar(panel_label)) {
    graphics::legend("topleft", legend = panel_label, pch = NA, bg = "white",
                     x.intersp = -0.3)
  }
  box(lwd = 1.2)
}
