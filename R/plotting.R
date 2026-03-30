
##' Plot the spatial distribution of hauls
##'
##' Plot the number of hauls by ICES rectangle on a longitude-latitude grid
##' using the internal `survey_info_full` data set.
##'
##' The function aggregates haul counts over spatial bins derived from ICES
##' statistical rectangles and displays them as a heat map. Optionally, a
##' coastline map is added if the suggested packages `maps` and `mapdata` are
##' available.
##'
##' @param plot_map Logical. If `TRUE` (default), add a coastline map in the
##'   background when the required map packages are installed.
##' @param xlim Optional numeric vector of length 2 giving the longitude limits
##'   of the plot.
##' @param ylim Optional numeric vector of length 2 giving the latitude limits
##'   of the plot.
##'
##' @details
##' Hauls are aggregated to a regular grid based on ICES rectangle midpoints.
##' The resulting frequencies are plotted with [image()] using a heat-map colour
##' scale.
##'
##' The map background is only drawn if both the `maps` and `mapdata` packages
##' are available.
##'
##' @return Invisibly returns `NULL`.
##'
##' @examples
##' \dontrun{
##' ## Plot all hauls
##' plot_hauls()
##'
##' ## Plot hauls in a restricted region
##' plot_hauls(xlim = c(-10, 15), ylim = c(50, 65))
##' }
##'
##' @export
plot_hauls <- function(plot_map = TRUE,
                       xlim = NULL,
                       ylim = NULL) {

  survey_info_full <- get("survey_info_full", envir = asNamespace("DATRASextra"))

  download_map <- FALSE
  scale <- 50
  col_land <- grDevices::adjustcolor(grey(0.9), 0.4)
  border_land <- grDevices::adjustcolor(grey(0.6), 0.4)
  land_ll <- get_land(download_map, scale = scale)

  sq <- unique(icesSquare(survey_info_full))
  pol <- icesSquare2coord(sq,"polygons")
  point <- icesSquare2coord(sq,"midpoint")
  range <- as.data.frame(lapply(do.call("rbind",pol),range))
  if(!is.null(xlim)) {
    range$lon[] <- xlim
  }
  if(!is.null(ylim)) {
    range$lat[] <- ylim
  }
  lon_breaks <- seq(min(point[,1]) - 0.5, max(point[,1]) + 0.5, by = 1)
  lat_breaks <- seq(min(point[,2]) - 0.25, max(point[,2]) + 0.25, by = 0.5)
  survey_info_full$lon_bin <- cut(survey_info_full$lon, breaks = lon_breaks,
                                  labels = seq(min(point[,1]),
                                               max(point[,1]), by = 1),
                                  include.lowest = TRUE)
  survey_info_full$lat_bin <- cut(survey_info_full$lat, breaks = lat_breaks,
                                  labels = seq(min(point[,2]),
                                               max(point[,2]), by = 0.5),
                                  include.lowest = TRUE)

  plot(range, type="n",
       las=1,
       xlab="Longitude",
       ylab="Latitude",
       asp = 1)

  freq <- aggregate(Hauls ~ lon_bin + lat_bin, data = survey_info_full, FUN = sum)
  grid <- expand.grid(
    lon_bin = levels(survey_info_full$lon_bin),
    lat_bin = levels(survey_info_full$lat_bin)
  )
  freq_full <- merge(grid, freq, by = c("lon_bin", "lat_bin"), all.x = TRUE)
  freq_full$Hauls[is.na(freq_full$Hauls)] <- 0
  tmp <- xtabs(Hauls ~ lon_bin + lat_bin, data = freq_full)

  image(as.numeric(rownames(tmp)),
        as.numeric(colnames(tmp)),
        tmp,
        breaks = seq(0.01, max(tmp), length.out = 13),
        col = hcl.colors(12, "YlOrRd", rev = TRUE),
        add = TRUE)

  if(plot_map){
    plot(sf::st_geometry(land_ll), add = TRUE,
         col = col_land, border = border_land)
  }
  box(lwd = 1.5)

  return(invisible(NULL))
}



##' Plot the spatial distribution of hauls for each survey
##'
##' Plot haul density by location separately for each survey using the internal
##' `survey_info_full` data set.
##'
##' The function aggregates haul counts over spatial bins derived from ICES
##' statistical rectangles and displays them as heat maps in a multi-panel
##' layout, with one panel per survey. Optionally, a coastline map is added if
##' the suggested packages `maps` and `mapdata` are available.
##'
##' @param plot_map Logical. If `TRUE` (default), add a coastline map in the
##'   background when the required map packages are installed.
##' @param fixed_scale Logical. If `TRUE` (default), use a common colour scale
##'   across surveys to make panels directly comparable. If `FALSE`, each survey
##'   gets its own scale based on its maximum haul density.
##' @param col A vector of colours used for the heat maps. Defaults to
##'   `hcl.colors(12, "YlOrRd", rev = TRUE)`.
##' @param xlim Optional numeric vector of length 2 giving the longitude limits
##'   of the plots.
##' @param ylim Optional numeric vector of length 2 giving the latitude limits
##'   of the plots.
##'
##' @details
##' Hauls are aggregated to a regular grid based on ICES rectangle midpoints.
##' For each survey, the resulting frequencies are plotted with [image()] using a
##' heat-map colour scale.
##'
##' If `fixed_scale = TRUE`, all panels use the same class breaks, allowing
##' direct comparison of haul intensity among surveys. If `FALSE`, class breaks
##' are determined separately for each survey.
##'
##' The map background is only drawn if both the `maps` and `mapdata` packages
##' are available.
##'
##' @return Invisibly returns `NULL`.
##'
##' @seealso [plot_hauls()], [plot_surveys()]
##'
##' @examples
##' \dontrun{
##' ## Plot haul density for all surveys
##' plot_hauls_by_survey()
##'
##' ## Use survey-specific colour scales
##' plot_hauls_by_survey(fixed_scale = FALSE)
##'
##' ## Restrict the plotted region
##' plot_hauls_by_survey(xlim = c(-10, 15), ylim = c(50, 65))
##' }
##'
##' @export
plot_hauls_by_survey <- function(plot_map = TRUE,
                                 fixed_scale = TRUE,
                                 col = hcl.colors(12, "YlOrRd", rev = TRUE),
                                 xlim = NULL,
                                 ylim = NULL) {

  survey_info_full <- get("survey_info_full", envir = asNamespace("DATRASextra"))

  download_map <- FALSE
  scale <- 50
  col_land <- grDevices::adjustcolor(grey(0.9), 0.4)
  border_land <- grDevices::adjustcolor(grey(0.6), 0.4)
  land_ll <- get_land(download_map, scale = scale)

  sq <- unique(icesSquare(survey_info_full))
  pol <- icesSquare2coord(sq,"polygons")
  point <- icesSquare2coord(sq,"midpoint")
  range <- as.data.frame(lapply(do.call("rbind",pol),range))
  if(!is.null(xlim)) {
    range$lon[] <- xlim
  }
  if(!is.null(ylim)) {
    range$lat[] <- ylim
  }
  lon_breaks <- seq(min(point[,1]) - 0.5, max(point[,1]) + 0.5, by = 1)
  lat_breaks <- seq(min(point[,2]) - 0.25, max(point[,2]) + 0.25, by = 0.5)
  survey_info_full$lon_bin <- cut(survey_info_full$lon, breaks = lon_breaks,
                                  labels = seq(min(point[,1]),
                                               max(point[,1]), by = 1),
                                  include.lowest = TRUE)
  survey_info_full$lat_bin <- cut(survey_info_full$lat, breaks = lat_breaks,
                                  labels = seq(min(point[,2]),
                                               max(point[,2]), by = 0.5),
                                  include.lowest = TRUE)

  surveys <- unique(survey_info_full$Survey)
  mfrow <- n2mfrow(length(surveys), asp = 2)
  par(mfrow = mfrow, mar = c(0.5,0.5,0.5,0.5),
      oma = c(4,4,1,1))

  for(i in 1:length(surveys)){

    subi <- subset(survey_info_full, Survey == surveys[i])

    xaxt <- ifelse(i %in% (prod(mfrow) - mfrow[2]+1):prod(mfrow), "s", "n")
    yaxt <- ifelse(i %in% seq(1, prod(mfrow), mfrow[2]), "s", "n")

    plot(range,
         type="n", las=1,
         xaxt = xaxt,
         yaxt = yaxt,
         asp = 1,
         xlab = "", ylab = "")

    freq <- aggregate(Hauls ~ lon_bin + lat_bin, data = subi, FUN = sum)
    grid <- expand.grid(
      lon_bin = levels(subi$lon_bin),
      lat_bin = levels(subi$lat_bin)
    )
    freq_full <- merge(grid, freq, by = c("lon_bin", "lat_bin"), all.x = TRUE)
    freq_full$Hauls[is.na(freq_full$Hauls)] <- 0
    tmp <- xtabs(Hauls ~ lon_bin + lat_bin, data = freq_full)

    if (fixed_scale) {
      breaks <- c(0.1,round(seq(5, 2500, length.out = length(col))))
    } else {
      breaks <- c(0.1,round(seq(5, max(tmp), length.out = length(col))))
    }

    image(as.numeric(rownames(tmp)),
          as.numeric(colnames(tmp)),
          tmp,
          breaks = breaks,
          col = col,
          add = TRUE)

    if(plot_map){
      plot(sf::st_geometry(land_ll), add = TRUE,
           col = col_land, border = border_land)
    }

    legend("topleft", legend = surveys[i],
           pch = NA, bg = "white")

    if (fixed_scale) {
      if (i == length(surveys)) {
        legend("bottomright",
               legend =
                 paste0("[",breaks[-length(breaks)],
                        "-",breaks[-1],")"),
               col = col, cex = 0.6,
               pch = 15, pt.cex = 1.5,
               bg = "white")
      }
    } else {
      legend("bottomright",
             legend =
               paste0("[",breaks[-length(breaks)],
                      "-",breaks[-1],")"),
             col = col, cex = 0.6,
             pch = 15, pt.cex = 1.5,
             bg = "white")
    }

    box(lwd = 1.5)

  }

  mtext("Longitude", 1, 2, outer = TRUE)
  mtext("Latitude", 2, 2, outer = TRUE)

  return(invisible(NULL))
}


##' Plot survey spatial coverage
##'
##' Plot the spatial footprint of surveys using the internal `survey_info_full`
##' data set.
##'
##' The function can either show each survey in a separate panel or overlay all
##' surveys in a single map. In overlay mode, the map shows how many surveys
##' sampled each spatial cell, optionally distinguishing survey quarters.
##'
##' @param plot_map Logical. If `TRUE` (default), add a coastline map in the
##'   background when the required map packages are installed.
##' @param fixed_axes Logical. If `TRUE` (default), use the same longitude and
##'   latitude limits for all panels when `overlay = FALSE`. If `FALSE`, each
##'   survey panel is scaled to its own spatial extent unless overridden by
##'   `xlim` or `ylim`.
##' @param overlay Logical. If `FALSE` (default), plot each survey separately.
##'   If `TRUE`, overlay all surveys in a single map and show the number of
##'   surveys represented in each spatial cell.
##' @param consider_quarter Logical. Only used when `overlay = TRUE`. If
##'   `TRUE`, survey-quarter combinations are treated as distinct survey units
##'   when counting overlap across space.
##' @param xlim Optional numeric vector of length 2 giving the longitude limits
##'   of the plot.
##' @param ylim Optional numeric vector of length 2 giving the latitude limits
##'   of the plot.
##'
##' @details
##' When `overlay = FALSE`, the function draws the ICES rectangles sampled by
##' each survey as filled polygons, with one panel per survey.
##'
##' When `overlay = TRUE`, the function aggregates survey occurrence to a regular
##' longitude-latitude grid derived from ICES rectangle midpoints and displays
##' the number of overlapping surveys using a heat map.
##'
##' If `consider_quarter = TRUE`, survey-quarter combinations are counted
##' separately in overlay mode, so the map reflects overlap among
##' survey-quarter units rather than surveys alone.
##'
##' The map background is only drawn if both the `maps` and `mapdata` packages
##' are available.
##'
##' @return Invisibly returns `NULL`.
##'
##' @seealso [plot_hauls()], [plot_hauls_by_survey()]
##'
##' @examples
##' \dontrun{
##' ## Plot each survey separately
##' plot_surveys()
##'
##' ## Overlay all surveys in one map
##' plot_surveys(overlay = TRUE)
##'
##' ## Overlay survey-quarter combinations
##' plot_surveys(overlay = TRUE, consider_quarter = TRUE)
##'
##' ## Allow each panel to use its own spatial extent
##' plot_surveys(fixed_axes = FALSE)
##' }
##'
##' @export
plot_surveys <- function(plot_map = TRUE,
                         fixed_axes = TRUE,
                         overlay = FALSE,
                         consider_quarter = FALSE,
                         xlim = NULL,
                         ylim = NULL) {

  survey_info_full <- get("survey_info_full", envir = asNamespace("DATRASextra"))

  download_map <- FALSE
  scale <- 50
  col_land <- grDevices::adjustcolor(grey(0.9), 0.4)
  border_land <- grDevices::adjustcolor(grey(0.6), 0.4)
  land_ll <- get_land(download_map, scale = scale)

  sq <- unique(icesSquare(survey_info_full))
  pol <- icesSquare2coord(sq,"polygons")
  point <- icesSquare2coord(sq,"midpoint")
  range <- as.data.frame(lapply(do.call("rbind",pol),range))
  if(!is.null(xlim)) {
    range$lon[] <- xlim
  }
  if(!is.null(ylim)) {
    range$lat[] <- ylim
  }

  surveys <- unique(survey_info_full$Survey)

  if (!overlay) {
    nsurv <- length(surveys)
  } else {
    nsurv <- 1
  }
  mfrow <- n2mfrow(nsurv, asp = 2)
  par(mfrow = mfrow, mar = c(0.5,0.5,0.5,0.5),
      oma = c(4,4,1,1))

  if (!overlay) {

    for(i in 1:nsurv){

      subi <- subset(survey_info_full, Survey == surveys[i])
      sqi <- unique(icesSquare(subi))
      poli <- icesSquare2coord(sqi, "polygons")
      if (!fixed_axes) {
        range <- as.data.frame(lapply(do.call("rbind",poli), range))
        if (!is.null(xlim)) {
          range$lon[] <- xlim
        }
        if (!is.null(ylim)) {
          range$lat[] <- ylim
        }
      }

      xaxt <- ifelse(i %in% (prod(mfrow) - mfrow[2]+1):prod(mfrow), "s", "n")
      yaxt <- ifelse(i %in% seq(1, prod(mfrow), mfrow[2]), "s", "n")

      plot(range,
           type="n", las=1,
           xaxt = xaxt,
           yaxt = yaxt,
           asp = 1,
           xlab = "", ylab = "")


      poli2 <- do.call("rbind",lapply(poli,function(x)rbind(x,NA)))
      polygon(poli2, col = adjustcolor(i, 0.8), border = adjustcolor("grey70",0.3))

      if(plot_map){
        plot(sf::st_geometry(land_ll), add = TRUE,
             col = col_land, border = border_land)
      }

      legend("topleft", legend = surveys[i],
             pch = NA, bg = "white")
      box(lwd = 1.5)
    }

  } else {

    lon_breaks <- seq(min(point[,1]) - 0.5, max(point[,1]) + 0.5, by = 1)
    lat_breaks <- seq(min(point[,2]) - 0.25, max(point[,2]) + 0.25, by = 0.5)
    survey_info_full$lon_bin <- cut(survey_info_full$lon, breaks = lon_breaks,
                                    labels = seq(min(point[,1]),
                                                 max(point[,1]), by = 1),
                                    include.lowest = TRUE)
    survey_info_full$lat_bin <- cut(survey_info_full$lat, breaks = lat_breaks,
                                    labels = seq(min(point[,2]),
                                                 max(point[,2]), by = 0.5),
                                    include.lowest = TRUE)

    plot(range,type="n",las=1,xlab="Longitude",ylab="Latitude")

    if (consider_quarter) {
      subi <- aggregate(list(Hauls = survey_info_full$Hauls),
                        by = list(Survey = paste0(survey_info_full$Survey,"-",
                                                  survey_info_full$Quarter),
                                  lon_bin = survey_info_full$lon_bin,
                                  lat_bin = survey_info_full$lat_bin), FUN = sum)
    } else {
      subi <- aggregate(list(Hauls = survey_info_full$Hauls),
                        by = list(survey_info_full$Survey,
                                  lon_bin = survey_info_full$lon_bin,
                                  lat_bin = survey_info_full$lat_bin), FUN = sum)
    }
    subi$dummy <- 1
    freq <- aggregate(dummy ~ lon_bin + lat_bin, data = subi, FUN = sum)
    grid <- expand.grid(
      lon_bin = levels(survey_info_full$lon_bin),
      lat_bin = levels(survey_info_full$lat_bin)
    )
    freq_full <- merge(grid, freq, by = c("lon_bin", "lat_bin"), all.x = TRUE)
    freq_full$dummy[is.na(freq_full$dummy)] <- 0
    tmp <- xtabs(dummy ~ lon_bin + lat_bin, data = freq_full)

    col <- hcl.colors(max(tmp)-1, "YlOrRd", rev = TRUE)
    breaks <- round(seq(1, max(tmp), length.out = length(col)+1))

    image(as.numeric(rownames(tmp)),
          as.numeric(colnames(tmp)),
          tmp,
          breaks = breaks,
          col = col,
          add = TRUE)

    if(plot_map){
      plot(sf::st_geometry(land_ll), add = TRUE,
           col = col_land, border = border_land)
    }
    labs <- breaks[-length(breaks)]
    labs[length(labs)] <- paste0(">",labs[length(labs)])
    legend("bottomright",
           legend = labs,
           col = col, cex = 0.6,
           pch = 15, pt.cex = 1.5,
           bg = "white")
    box(lwd = 1.5)

  }

  return(invisible(NULL))
}



#' Plot haul maps through space and time
#'
#' Visualise the spatial footprint of survey hauls by year using faceted maps.
#' Point sizes can optionally be scaled by a haul-level variable or by a
#' haul-level variable standardised by effort.
#'
#' The function expects a DATRAS-like object containing a haul table
#' \code{x[["HH"]]} with at least the columns \code{Year}, \code{lon}, and
#' \code{lat}.
#'
#' @param x A DATRAS-like object containing an \code{HH} data frame.
#' @param value_var Optional character string naming a haul-level variable in
#'   \code{x[["HH"]]} used to scale point sizes. If \code{NULL}, point sizes are
#'   constant unless \code{size_var} is provided.
#' @param effort_var Optional character string naming a haul-level effort
#'   variable in \code{x[["HH"]]}. If both \code{value_var} and
#'   \code{effort_var} are available, point sizes are scaled by
#'   \code{value_var / effort_var}.
#' @param years Optional numeric or character vector specifying which years to
#'   plot. Defaults to all available years.
#' @param plot_map Logical; if \code{TRUE}, add land polygons in the background.
#' @param fixed_axes Logical; if \code{TRUE}, all panels use the same
#'   \code{xlim} and \code{ylim}. If \code{FALSE}, each panel is scaled to the
#'   data shown in that year.
#' @param xlim Optional numeric vector of length 2 giving x-axis limits.
#' @param ylim Optional numeric vector of length 2 giving y-axis limits.
#' @param size_var Deprecated alias for \code{value_var}. If supplied, it
#'   overrides \code{value_var}.
#' @param cex Base point size used when no scaling variable is available.
#' @param cex_range Numeric vector of length 2 giving the minimum and maximum
#'   point size when scaling is applied.
#' @param col_points Colour used for haul locations.
#' @param pch Plotting symbol used for haul locations.
#' @param transform Character string specifying the transformation applied before
#'   scaling point sizes. One of \code{"sqrt"}, \code{"log1p"}, or
#'   \code{"identity"}.
#' @param verbose Logical; if \code{TRUE}, print which variable was used for
#'   point-size scaling.
#'
#' @return Invisibly returns a list with the plotted years, axis limits, panel
#'   layout, and the variable used for scaling.
#'
#' @details
#' If both \code{value_var} and \code{effort_var} are available, point sizes are
#' based on \code{value_var / effort_var}, which can be useful for visualising a
#' haul-level quantity standardised by effort. However, in standard DATRAS haul
#' tables, \code{HaulN} is typically a haul identifier rather than a catch
#' variable and is therefore generally not meaningful for this purpose.
#'
#' @examples
#' \dontrun{
#' ## Plot yearly haul maps
#' plot_haul_map(dat)
#'
#' ## Restrict to selected years
#' plot_haul_map(dat, years = 2010:2015)
#'
#' ## Scale point size by a haul-level variable
#' plot_haul_map(dat, value_var = "HaulDur")
#'
#' ## Scale point size by a haul-level quantity standardised by effort
#' plot_haul_map(dat, value_var = "TotalNo", effort_var = "SweptArea")
#' }
#'
#' @export
plot_haul_map <- function(x,
                          value_var = "HaulN",
                          effort_var = "SweptArea",
                          years = NULL,
                          plot_map = TRUE,
                          fixed_axes = TRUE,
                          xlim = NULL,
                          ylim = NULL,
                          size_var = NULL,
                          cex = 0.8,
                          cex_range = c(0.5, 2.5),
                          col_points = NULL,
                          pch = 16,
                          transform = c("sqrt", "log1p", "identity"),
                          show_size_legend = TRUE,
                          legend_n = 4,
                          legend_pos = "bottomright",
                          legend_title = NULL,
                          verbose = TRUE) {

  transform <- match.arg(transform)

  hh <- x[["HH"]]

  if (is.null(hh)) {
    stop("`x` must contain an 'HH' element.")
  }

  needed <- c("Year", "lon", "lat")
  miss <- setdiff(needed, names(hh))
  if (length(miss) > 0) {
    stop("Missing required columns in `x[['HH']]`: ",
         paste(miss, collapse = ", "))
  }

  ## Backward compatibility
  if (!is.null(size_var)) {
    value_var <- size_var
  }

  hh <- hh[stats::complete.cases(hh[, c("Year", "lon", "lat")]), , drop = FALSE]

  if (!is.null(years)) {
    hh <- hh[hh$Year %in% years, , drop = FALSE]
  }

  if (nrow(hh) == 0) {
    stop("No rows available for plotting after filtering.")
  }

  years <- sort(unique(hh$Year))
  nyears <- length(years)

  if (plot_map) {
    download_map <- FALSE
    scale_map <- 50
    col_land <- grDevices::adjustcolor(grey(0.9), 0.4)
    border_land <- grDevices::adjustcolor(grey(0.6), 0.4)
    land_ll <- get_land(download = download_map, scale = scale_map)
  }

  if (is.null(xlim)) xlim <- range(hh$lon, na.rm = TRUE)
  if (is.null(ylim)) ylim <- range(hh$lat, na.rm = TRUE)

  ## Determine scaling variable
  scale_values_raw <- NULL
  scale_label <- "constant"

  if (!is.null(value_var)) {
    if (!value_var %in% names(hh)) {
      warning("`value_var` not found in `x[['HH']]`: ", value_var,
              ". Using constant point size.")
      value_var <- NULL
    }
  }

  if (!is.null(value_var)) {
    vals <- hh[[value_var]]
    vals[!is.finite(vals)] <- NA_real_

    if (!is.null(effort_var) && effort_var %in% names(hh)) {
      eff <- hh[[effort_var]]
      eff[!is.finite(eff) | eff <= 0] <- NA_real_
      scale_values_raw <- vals / eff
      scale_label <- paste0(value_var, " / ", effort_var)
    } else {
      scale_values_raw <- vals
      scale_label <- value_var
    }

    scale_values_raw[!is.finite(scale_values_raw) | scale_values_raw < 0] <- NA_real_
  }

  ## Apply transformation
  scale_values <- scale_values_raw
  if (!is.null(scale_values)) {
    scale_values <- switch(
      transform,
      sqrt = sqrt(scale_values),
      log1p = log1p(scale_values),
      identity = scale_values
    )
  }

  ## Convert scaling variable to cex
  point_cex_all <- rep(cex, nrow(hh))
  scale_rng <- c(NA_real_, NA_real_)

  if (!is.null(scale_values) && any(is.finite(scale_values))) {
    scale_rng <- range(scale_values, na.rm = TRUE)
    if (diff(scale_rng) > 0) {
      point_cex_all <- cex_range[1] +
        (cex_range[2] - cex_range[1]) * (scale_values - scale_rng[1]) / diff(scale_rng)
      point_cex_all[!is.finite(point_cex_all)] <- cex
    }
  }

  if (isTRUE(verbose)) {
    message("Point-size scaling: ", scale_label)
  }

  panel_layout <- grDevices::n2mfrow(nyears, asp = 1.2)
  oldpar <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(oldpar))

  graphics::par(mfrow = panel_layout,
                mar = c(1.5, 1.5, 2, 1),
                oma = c(3, 3, 1, 1))

  if (is.null(col_points)) col_points <- .cols_datrasextra(length(years))
  if (length(col_points) < length(years)) {
    col_points <- rep(col_points, length.out = length(years))
  }

  ## Helper: map raw values to cex using the same transformation/scaling
  map_values_to_cex <- function(z_raw) {
    if (is.null(scale_values_raw) || !any(is.finite(scale_values))) {
      return(rep(cex, length(z_raw)))
    }

    z_tr <- switch(
      transform,
      sqrt = sqrt(z_raw),
      log1p = log1p(z_raw),
      identity = z_raw
    )

    if (!all(is.finite(scale_rng)) || diff(scale_rng) <= 0) {
      return(rep(cex, length(z_raw)))
    }

    out <- cex_range[1] +
      (cex_range[2] - cex_range[1]) * (z_tr - scale_rng[1]) / diff(scale_rng)

    out[!is.finite(out)] <- cex
    out
  }

  ## Precompute size legend
  legend_vals <- NULL
  legend_cex <- NULL

  if (show_size_legend && !is.null(scale_values_raw) && any(is.finite(scale_values_raw))) {
    raw_rng <- range(scale_values_raw, na.rm = TRUE)

    if (diff(raw_rng) > 0) {
      legend_vals <- pretty(raw_rng, n = legend_n)
      legend_vals <- legend_vals[legend_vals >= raw_rng[1] & legend_vals <= raw_rng[2]]

      ## make sure we keep at least 2 values
      if (length(legend_vals) < 2) {
        legend_vals <- seq(raw_rng[1], raw_rng[2], length.out = legend_n)
      }

      legend_cex <- map_values_to_cex(legend_vals)

      if (is.null(legend_title)) {
        legend_title <- scale_label
      }
    }
  }

  for (i in seq_along(years)) {
    ind <- hh$Year == years[i]
    subi <- hh[ind, , drop = FALSE]
    point_cex <- point_cex_all[ind]

    panel_xlim <- xlim
    panel_ylim <- ylim

    if (!fixed_axes) {
      panel_xlim <- range(subi$lon, na.rm = TRUE)
      panel_ylim <- range(subi$lat, na.rm = TRUE)
    }

    graphics::plot(NA,
                   xlim = panel_xlim,
                   ylim = panel_ylim,
                   xlab = "",
                   ylab = "",
                   xaxt = "n",
                   yaxt = "n",
                   asp = 1)

    if (plot_map) {
      graphics::plot(sf::st_geometry(land_ll),
                     add = TRUE,
                     col = col_land,
                     border = border_land)
    }

    graphics::points(subi$lon, subi$lat,
                     cex = point_cex,
                     col = col_points[i],
                     pch = pch)

    if (i %in% seq(1, prod(panel_layout), by = panel_layout[2])) {
      graphics::axis(2, las = 1)
    }
    if (i %in% (prod(panel_layout) - panel_layout[2] + 1):prod(panel_layout)) {
      graphics::axis(1)
    }

    ## Draw size legend once in the last panel
    if (i == length(years) &&
        show_size_legend &&
        !is.null(legend_vals) &&
        length(legend_vals) > 0) {

      graphics::legend(
        legend_pos,
        legend = formatC(legend_vals, format = "fg", digits = 3),
        pt.cex = legend_cex,
        pch = pch,
        col = "grey20",
        pt.bg = NA,
        title = legend_title,
        bg = "white",
        x.intersp = 1,
        y.intersp = 1.2
      )
    }

    graphics::box(lwd = 1.2)
    graphics::title(main = years[i], cex.main = 0.95)

  }

  graphics::mtext("Longitude", side = 1, outer = TRUE, line = 1.5)
  graphics::mtext("Latitude", side = 2, outer = TRUE, line = 1.5)

  invisible(list(
    years = years,
    xlim = xlim,
    ylim = ylim,
    layout = panel_layout,
    scale_label = scale_label,
    legend_values = legend_vals
  ))
}
