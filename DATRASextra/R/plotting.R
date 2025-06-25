
##' @title Plot hauls
##'
##' @export
plotHauls <- function(plot.map = TRUE,
                      xlim = NULL, ylim = NULL){

    data("surveyInfoFull")

    ok <- requireNamespace("maps", quietly = TRUE) &&
        requireNamespace("mapdata", quietly = TRUE)

    sq <- unique(icesSquare(surveyInfoFull))
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
    surveyInfoFull$lon_bin <- cut(surveyInfoFull$lon, breaks = lon_breaks,
                                  labels = seq(min(point[,1]),
                                               max(point[,1]), by = 1),
                                  include.lowest = TRUE)
    surveyInfoFull$lat_bin <- cut(surveyInfoFull$lat, breaks = lat_breaks,
                                  labels = seq(min(point[,2]),
                                               max(point[,2]), by = 0.5),
                                  include.lowest = TRUE)

    plot(range,type="n",las=1,xlab="Longitude",ylab="Latitude")

    freq <- aggregate(Hauls ~ lon_bin + lat_bin, data = surveyInfoFull, FUN = sum)
    grid <- expand.grid(
        lon_bin = levels(surveyInfoFull$lon_bin),
        lat_bin = levels(surveyInfoFull$lat_bin)
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

    if(plot.map){
        if(ok) maps::map("mapdata::worldHires",add=TRUE,lwd=1,col="darkgrey",
                         fill=FALSE)
    }
    box(lwd = 1.5)

  return(invisible(NULL))
}



##' @title Plot hauls by survey
##'
##' @export
plotHaulsBySurvey <- function(plot.map = TRUE,
                              fixed.scale = TRUE,
                              col = hcl.colors(12, "YlOrRd", rev = TRUE),
                              xlim = NULL, ylim = NULL){

    data("surveyInfoFull")

    ok <- requireNamespace("maps", quietly = TRUE) &&
        requireNamespace("mapdata", quietly = TRUE)

    sq <- unique(icesSquare(surveyInfoFull))
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
    surveyInfoFull$lon_bin <- cut(surveyInfoFull$lon, breaks = lon_breaks,
                                  labels = seq(min(point[,1]),
                                               max(point[,1]), by = 1),
                                  include.lowest = TRUE)
    surveyInfoFull$lat_bin <- cut(surveyInfoFull$lat, breaks = lat_breaks,
                                  labels = seq(min(point[,2]),
                                               max(point[,2]), by = 0.5),
                                  include.lowest = TRUE)

    surveys <- unique(surveyInfoFull$Survey)
    mfrow <- n2mfrow(length(surveys), asp = 2)
    par(mfrow = mfrow, mar = c(0.5,0.5,0.5,0.5),
        oma = c(4,4,1,1))

    for(i in 1:length(surveys)){

        subi <- subset(surveyInfoFull, Survey == surveys[i])

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

        if (fixed.scale) {
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

        if(plot.map){
            if(ok) maps::map("mapdata::worldHires",add=TRUE,lwd=1,col="darkgrey",
                             fill=FALSE)
        }

        legend("topleft", legend = surveys[i],
               pch = NA, bg = "white")

        if (fixed.scale) {
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


##' @title Plot surveys
##'
##' @export
plotSurveys <- function(plot.map = TRUE,
                        fixed.axes = TRUE,
                        overlay = FALSE,
                        consider.quarter = FALSE,
                        xlim = NULL,
                        ylim = NULL){

    data("surveyInfoFull")

    ok <- requireNamespace("maps", quietly = TRUE) &&
        requireNamespace("mapdata", quietly = TRUE)

    sq <- unique(icesSquare(surveyInfoFull))
    pol <- icesSquare2coord(sq,"polygons")
    point <- icesSquare2coord(sq,"midpoint")
    range <- as.data.frame(lapply(do.call("rbind",pol),range))
    if(!is.null(xlim)) {
        range$lon[] <- xlim
    }
    if(!is.null(ylim)) {
        range$lat[] <- ylim
    }

    surveys <- unique(surveyInfoFull$Survey)

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

            subi <- subset(surveyInfoFull, Survey == surveys[i])
            sqi <- unique(icesSquare(subi))
            poli <- icesSquare2coord(sqi, "polygons")
            if (!fixed.axes) {
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

            if(plot.map){
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
        surveyInfoFull$lon_bin <- cut(surveyInfoFull$lon, breaks = lon_breaks,
                                      labels = seq(min(point[,1]),
                                                   max(point[,1]), by = 1),
                                      include.lowest = TRUE)
        surveyInfoFull$lat_bin <- cut(surveyInfoFull$lat, breaks = lat_breaks,
                                      labels = seq(min(point[,2]),
                                                   max(point[,2]), by = 0.5),
                                      include.lowest = TRUE)

        plot(range,type="n",las=1,xlab="Longitude",ylab="Latitude")

        if (consider.quarter) {
            subi <- aggregate(list(Hauls = surveyInfoFull$Hauls),
                              by = list(Survey = paste0(surveyInfoFull$Survey,"-",
                                                       surveyInfoFull$Quarter),
                                        lon_bin = surveyInfoFull$lon_bin,
                                        lat_bin = surveyInfoFull$lat_bin), FUN = sum)
        } else {
            subi <- aggregate(list(Hauls = surveyInfoFull$Hauls),
                              by = list(surveyInfoFull$Survey,
                                        lon_bin = surveyInfoFull$lon_bin,
                                        lat_bin = surveyInfoFull$lat_bin), FUN = sum)
        }
        subi$dummy <- 1
        freq <- aggregate(dummy ~ lon_bin + lat_bin, data = subi, FUN = sum)
        grid <- expand.grid(
            lon_bin = levels(surveyInfoFull$lon_bin),
            lat_bin = levels(surveyInfoFull$lat_bin)
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

        if(plot.map){
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
