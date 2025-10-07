
##' Check weight information (in CA)
##'
##' @title Check weight information (in CA)
##'
##' @param d DATRASraw object
##'
##' @return Info
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
checkWeight <- function (d,
                         maxL = NULL,
                         maxW = NULL,
                         plot = TRUE) {

    DATRAS:::checkSpectrum(d)

    x <- subset(d[[1]], IndWgt > 0)
    if (!is.null(maxL) && !is.na(maxL) && is.numeric(maxL)) {
        x <- x[x$LngtCm <= maxL,]
    }
    if (!is.null(maxW) && !is.na(maxW) && is.numeric(maxW)) {
        x <- x[x$IndWgt <= maxW,]
    }

    lPars <- data.frame(min = min(x$LngtCm, na.rm = TRUE),
                        mean = mean(x$LngtCm, na.rm = TRUE),
                        median = median(x$LngtCm, na.rm = TRUE),
                        max = max(x$LngtCm, na.rm = TRUE))

    print("Length statistics:")
    print(round(lPars,2))

    wPars <- data.frame(min = min(x$IndWgt, na.rm = TRUE),
                        mean = mean(x$IndWgt, na.rm = TRUE),
                        median = median(x$IndWgt, na.rm = TRUE),
                        max = max(x$IndWgt, na.rm = TRUE))

    print("Weight statistics:")
    print(round(wPars,2))

    m = lm(log(IndWgt) ~ log(LngtCm), data = x)
    cm.breaks = attr(d, "cm.breaks")[-1] - 0.5
    tmp = d[[1]][1:length(cm.breaks), ]
    tmp$LngtCm = cm.breaks
    tmp$Wgt = exp(predict(m, newdata = tmp))

    if(plot) {

        opar <- par()
        on.exit(par(opar))
        layout(matrix(c(2,0,1,3), 2, 2, byrow = TRUE),
               widths = c(4,1), heights = c(1,4), respect = TRUE)
        par(mar = c(5, 4, 0.25, 0.25))
        plot(x$LngtCm, x$IndWgt,
             xlab = "Length [cm]", ylab = "Weight [g]")
        lines(tmp$LngtCm, tmp$Wgt, lwd = 3, col = 4)
        box(lwd = 1.5)
        par(mar = c(0.25, 4, 1, 0.25))
        xhist <- hist(x$LngtCm, breaks = 30, plot = FALSE)
        barplot(xhist$counts, axes = TRUE, space = 0,
                ylim = c(0, 1.2 * max(xhist$counts)),
                xlab= "", ylab="Counts")
        box(lwd = 1.5)
        par(mar = c(5, 0.25, 0.25, 1))
        xhist <- hist(x$IndWgt, breaks = 30, plot = FALSE)
        barplot(xhist$counts, axes = TRUE, space = 0, horiz=TRUE,
                xlim = c(0, 1.2 * max(xhist$counts)),
                xlab= "Counts", ylab="")
        box(lwd = 1.5)

    }

    coefs <- coefficients(m)

    a <- unname(exp(coefs[1]))
    b <- unname(coefs[2])

    print("Estimated LW parameters:")
    print(paste0("a = ", round(a,3), " b = ", round(b,3)))

    ## Empirical parameters
    aEmp <- bEmp <- NA
    aphia <- unique(d[[3]]$Valid_Aphia)
    if (!is.na(aphia) && length(aphia) == 1) {
        if (exists("speciesInfo")) {
            ind <- which(speciesInfo$WoRMS_AphiaID == aphia)
            if (!is.na(ind) && length(ind) == 1) {
                aEmp <- speciesInfo$a[ind]
                bEmp <- speciesInfo$b[ind]

                print("Empirical LW parameters:")
                print(paste0("a = ", round(aEmp,3), " b = ", round(bEmp,3)))
            }
        }
    }

    res <- list(lPars = lPars,
                wPars = wPars,
                parEst = data.frame(a = a, b = b),
                parEmp = data.frame(a = aEmp, b = bEmp))

    return(res)
}




##' Calculate weight by length classes and add to HH-records
##'
##' @title Calculate weight by length classes and add to HH-records
##' @param d DATRASraw object
##' @param to1min divide by haul duration in minutes? (defaults to TRUE)
##' @return DATRASraw object
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
addWeight <- function (d, to1min = TRUE,
                       maxL = NULL,
                       maxW = NULL) {
    DATRAS:::checkSpectrum(d)
    x <- subset(d[[1]], IndWgt > 0)
    if (!is.null(maxL) && !is.na(maxL) && is.numeric(maxL)) {
        x <- x[x$LngtCm <= maxL,]
    }
    if (!is.null(maxW) && !is.na(maxW) && is.numeric(maxW)) {
        x <- x[x$IndWgt <= maxW,]
    }
    m = lm(log(IndWgt) ~ log(LngtCm), data = x)
    cm.breaks = attr(d, "cm.breaks")[-1] - 0.5
    tmp = d[[1]][1:length(cm.breaks), ]
    tmp$LngtCm = cm.breaks
    tmp$Wgt = exp(predict(m, newdata = tmp))
    LW = tmp$Wgt
    Wgt <- sweep(d[[2]]$N, 2, LW, "*")

    if (to1min) {
        Wgt <- Wgt/d[[2]]$HaulDur
    }

    Wgt <- round(Wgt, 3)

    d[[2]]$Wgt <- Wgt[as.character(d[[2]]$haul.id),,drop=FALSE]

    return(d)
}

##' Calculate weight by length classes using empirical a and b, and add to HH-records
##'
##' @title Calculate weight by length classes using empirical a and b, and add
##'     to HH-records
##' @param d DATRASraw object
##' @param to1min divide by haul duration in minutes? (defaults to TRUE)
##' @return DATRASraw object
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
addWeightEmpirical <- function (d, to1min = TRUE) {
    DATRAS:::checkSpectrum(d)

    aphia <- unique(d[[3]]$Valid_Aphia)
    if(length(aphia) > 1) stop("More than one Aphia ID in the data set. Not sure which a and b parameters in speciesInfo to use. Please run this function for each species separately.")
    if(length(aphia) == 0) stop("No Aphia ID found in d[[3]].")

    ## data("speciesInfo")
    ind <- which(speciesInfo$WoRMS_AphiaID == aphia)
    if(length(ind) > 1) stop("More than one matching Aphia ID found in speciesInfo. Did you modify speciesInfo? Please make sure to have unique Aphia IDs in speciesInfo")
    if(length(ind) == 0) stop("Aphia ID could not be matched in speciesInfo. Please make sure your species is in speciesInfo.")

    a <- speciesInfo$a[ind]
    b <- speciesInfo$b[ind]

    if(is.na(a) || !is.numeric(a)) stop("Matched a in speciesInfo is NA or not numeric! Please check the value!")
    if(is.na(b) || !is.numeric(b)) stop("Matched b in speciesInfo is NA or not numeric! Please check the value!")

    cm.breaks = attr(d, "cm.breaks")[-1] - 0.5
    tmp = d[[1]][1:length(cm.breaks), ]
    tmp$LngtCm = cm.breaks
    tmp$Wgt = a * tmp$LngtCm ^ b
    LW = tmp$Wgt

    Wgt <- sweep(d[[2]]$N, 2, LW, "*")

    if (to1min) {
        Wgt <- Wgt/d[[2]]$HaulDur
    }

    Wgt <- round(Wgt, 3)

    d[[2]]$Wgt <- Wgt[as.character(d[[2]]$haul.id),,drop=FALSE]

    return(d)
}



##' Calculate total biomass by haul using empirical a and b, and add to HH-records
##'
##' @title Calculate total biomass by haul using a and b, and add to HH-records
##' @param d DATRASraw object
##' @param to1min divide by haul duration in minutes? (defaults to TRUE)
##' @return DATRASraw object
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
addWeightByHaulEmpirical <- function (d, to1min = TRUE) {
    DATRAS:::checkSpectrum(d)

    aphia <- unique(d[[3]]$Valid_Aphia)
    if(length(aphia) > 1) stop("More than one Aphia ID in the data set. Not sure which a and b parameters in speciesInfo to use. Please run this function for each species separately.")
    if(length(aphia) == 0) stop("No Aphia ID found in d[[3]].")

    ## data("speciesInfo")
    ind <- which(speciesInfo$WoRMS_AphiaID == aphia)
    if(length(ind) > 1) stop("More than one matching Aphia ID found in speciesInfo. Did you modify speciesInfo? Please make sure to have unique Aphia IDs in speciesInfo")
    if(length(ind) == 0) stop("Aphia ID could not be matched in speciesInfo. Please make sure your species is in speciesInfo.")

    a <- speciesInfo$a[ind]
    b <- speciesInfo$b[ind]

    if(is.na(a) || !is.numeric(a)) stop("Matched a in speciesInfo is NA or not numeric! Please check the value!")
    if(is.na(b) || !is.numeric(b)) stop("Matched b in speciesInfo is NA or not numeric! Please check the value!")

    cm.breaks = attr(d, "cm.breaks")[-1] - 0.5
    tmp = d[[1]][1:length(cm.breaks), ]
    tmp$LngtCm = cm.breaks
    tmp$Wgt = a * tmp$LngtCm ^ b

    LW = tmp$Wgt
    WgtByHaul <- function(i) {
        d[[2]]$N[i, ] %*% LW
    }
    d[[2]]$HaulWgt = unlist(lapply(1:nrow(d[[2]]), WgtByHaul))
    if (to1min)
        d[[2]]$HaulWgt = d[[2]]$HaulWgt/d[[2]]$HaulDur
    d
}
