
##' Create and inspect length measurements (in HL)
##'
##' @title Create and inspect length spectrum
##'
##' @param x DATRASraw object
##' @param cm.breaks x
##' @param by If NULL, most coarse accuracy is used (using DATRAS internal
##'     function getAccuracyCM)
##' @param length.percentile x
##' @param plot TRUE
##'
##' @return N at length matrix
##'
##' @export
checkLength <- function(x,
                        cm.breaks = seq(min(x[[3]]$LngtCm, na.rm = TRUE),
                                         max(x[[3]]$LngtCm, na.rm = TRUE) + by,
                                         by = by),
                        by = NULL,
                        length.percentile = 99.9999,
                        plot = TRUE) {

    ## import internal function from DATRAS
    getAccuracyCM <- getFromNamespace("getAccuracyCM", "DATRAS")

    if (is.null(by))
        by <- getAccuracyCM(x)

    stopifnot(class(x) == "DATRASraw")
    if (length(levels(x[[3]]$Species)) > 1)
        warning("Multiple species found - spectrum will contain all species")
    if (any(is.na(x[[2]]$DataType))) {
        warning(sum(is.na(x[[2]]$DataType)), " NA's found in DataType. These hauls will be removed")
        x <- subset(x, !is.na(DataType))
    }
    if (any(x[[2]]$DataType == "S"))
        warning("DataType 'S' found in length data. These hauls will be interpreted as DataType 'R' wrt. total numbers caught.")
    x[[3]]$sizeGroup <- cut(x[[3]]$LngtCm, breaks = cm.breaks,
                            right = FALSE)
    N <- xtabs(Count ~ haul.id + sizeGroup, data = x[[3]])
    N <- round(N)

    nout <- N[as.character(x[[2]]$haul.id), , drop = FALSE]
    attr(nout, "cm.breaks") <- cm.breaks

    nSum <- colSums(N, na.rm = TRUE)

    midL <- cm.breaks[-length(cm.breaks)] + by/2

    ## Mean length
    meanL <- weighted.mean(midL, unname(nSum))

    ## Median length
    all.lengths <- rep(midL, times = unname(nSum))
    medianL <- median(all.lengths)

    ## Minimum length (observed)
    minLObs <- min(x[[3]]$LngtCm, na.rm = TRUE)

    ## Maximum length (observed)
    maxLObs <- max(x[[3]]$LngtCm, na.rm = TRUE)

    ## Maximum length (empirical)
    maxLEmp <- NA
    aphia <- unique(x[[3]]$Valid_Aphia)
    if(all(!is.na(aphia)) && length(aphia) == 1){
        if (exists("speciesInfo")) {
            ind <- which(speciesInfo$WoRMS_AphiaID == aphia)
            if(!is.na(ind) && length(ind) == 1){
                maxLEmp <- speciesInfo$maxL[ind]
            }
        }
    }

    ## Percentile 99.9999% (default)
    percL <- quantile(all.lengths, probs = length.percentile/100)

    lVals <- data.frame(min = minLObs,
                        mean = meanL,
                        median = medianL,
                        maxObs = maxLObs,
                        maxEmp = maxLEmp,
                        perc = percL)

    print("Length statistics:")
    print(round(lVals,2))

    nAbove <- data.frame(maxLEmp = sum(nSum[midL > maxLEmp]),
                         percL = sum(nSum[midL > percL]))
    nAbove <- rbind(nAbove, nAbove / sum(nSum) * 100)
    rownames(nAbove) <- c("Numbers","Percent")

    print("Observations above:")
    print(round(nAbove,4))


    if(plot){
        opar <- par()
        on.exit(par(opar))
        par(mfrow = c(2,1), mar = c(2,4,1,1), oma = c(2,0,0,0))
        ## counts
        bar_x <- barplot(nSum, names.arg = midL,
                         xlab = "",
                         ylab = "Count")
        abline(v = map2bar(minLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
        abline(v = map2bar(meanL, midL, bar_x), col = 3, lwd = 2)
        abline(v = map2bar(medianL, midL, bar_x), col = 4, lty = 2, lwd = 2)
        abline(v = map2bar(maxLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
        abline(v = map2bar(maxLEmp, midL, bar_x), col = 4, lty = 1, lwd = 2)
        abline(v = map2bar(percL, midL, bar_x), col = 2, lty = 2, lwd = 2)
        legend("topright", legend = c("Min","Mean", "Median",
                                      "Max (observed)", "Max (empirical)",
                                      "Percentile (99.9999%)"),
               col = c(4,3,4,4,4,2), lwd = 2, lty = c(3,1,2,3,1,2),
               bg = "white")
        ## log counts
        logNSum <- log(nSum)
        logNSum[is.infinite(logNSum)] <- NA
        bar_x <- barplot(logNSum, names.arg = midL,
                         xlab = "Length (cm)",
                         ylab = "log(Count)")
        abline(v = map2bar(minLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
        abline(v = map2bar(meanL, midL, bar_x), col = 3, lwd = 2)
        abline(v = map2bar(medianL, midL, bar_x), col = 4, lty = 2, lwd = 2)
        abline(v = map2bar(maxLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
        abline(v = map2bar(maxLEmp, midL, bar_x), col = 4, lty = 1, lwd = 2)
        abline(v = map2bar(percL, midL, bar_x), col = 2, lty = 2, lwd = 2)
    }

    res <- list(N = nout,
                lPars = lVals,
                nAbove = nAbove)

    return(res)
}
