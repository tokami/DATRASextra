
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

  ok <- requireNamespace("maps", quietly = TRUE) &&
    requireNamespace("mapdata", quietly = TRUE)

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

  plot(range,type="n",las=1,xlab="Longitude",ylab="Latitude")

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
    if(ok) maps::map("mapdata::worldHires",add=TRUE,lwd=1,col="darkgrey",
                     fill=FALSE)
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

  ok <- requireNamespace("maps", quietly = TRUE) &&
    requireNamespace("mapdata", quietly = TRUE)

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
      if(ok) maps::map("mapdata::worldHires",add=TRUE,lwd=1,col="darkgrey",
                       fill=FALSE)
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

  ok <- requireNamespace("maps", quietly = TRUE) &&
    requireNamespace("mapdata", quietly = TRUE)

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
           xlab = "", ylab = "")


      poli2 <- do.call("rbind",lapply(poli,function(x)rbind(x,NA)))
      polygon(poli2, col = adjustcolor(i, 0.4), border = adjustcolor("grey70",0.3))

      if(plot_map){
        if(ok) maps::map("mapdata::worldHires",add=TRUE,lwd=1,col="darkgrey",
                         fill=FALSE)
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
      if(ok) maps::map("mapdata::worldHires",add=TRUE,lwd=1,col="darkgrey",
                       fill=FALSE)
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
