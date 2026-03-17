
## Main functions ----------------------------------------------------------------

##' Check and summarize individual weight information in a `datras_raw` object
##'
##' Inspect the length-weight information stored in the `CA` table of a
##' `datras_raw` / `DATRASraw` object.
##'
##' The function filters to positive individual weights, optionally excludes very
##' large lengths or weights, summarizes the observed length and weight
##' distributions, fits a log-log length-weight relationship, and optionally
##' plots the observed data together with the fitted curve.
##'
##' @param x A `datras_raw` object.
##' @param max_length Optional numeric value giving the maximum length in
##'   centimetres to retain for the analysis. Observations above this value are
##'   excluded.
##' @param max_weight Optional numeric value giving the maximum individual weight
##'   in grams to retain for the analysis. Observations above this value are
##'   excluded.
##' @param plot Logical. If `TRUE` (default), produce diagnostic plots of the
##'   observed length-weight relationship and marginal histograms of length and
##'   weight.
##'
##' @details
##' The function first calls [DATRAS::checkSpectrum()] and then works on the `CA`
##' table of the input object.
##'
##' A linear model of the form
##' \deqn{
##'   \log(IndWgt) = \alpha + b \log(LngtCm)
##' }
##' is fitted to the filtered observations, and the corresponding length-weight
##' parameters are returned as:
##' \deqn{
##'   a = \exp(\alpha)
##' }
##' and
##' \deqn{
##'   b
##' }
##'
##' If available, empirical length-weight parameters are also retrieved from
##' `species_info` for comparison.
##'
##' @return A list with four elements:
##' \itemize{
##'   \item `lPars`: a data frame with summary statistics for observed lengths,
##'   \item `wPars`: a data frame with summary statistics for observed weights,
##'   \item `parEst`: a data frame with estimated length-weight parameters `a`
##'   and `b`,
##'   \item `parEmp`: a data frame with empirical length-weight parameters `a`
##'   and `b`, if available.
##' }
##'
##' @seealso [check_length()], [DATRAS::checkSpectrum()]
##'
##' @examples
##' \dontrun{
##' res <- check_weight(x)
##'
##' ## Restrict to plausible values
##' res <- check_weight(x, max_length = 100, max_weight = 10000)
##' }
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
check_weight <- function (x,
                          max_length = NULL,
                          max_weight = NULL,
                          plot = TRUE) {

  .check_class_datras(x)

  DATRAS::checkSpectrum(x)

  x1 <- subset(x[["CA"]], IndWgt > 0)
  if (!is.null(max_length) && !is.na(max_length) && is.numeric(max_length)) {
    x1 <- x1[x1$LngtCm <= max_length,]
  }
  if (!is.null(max_weight) && !is.na(max_weight) && is.numeric(max_weight)) {
    x1 <- x1[x1$IndWgt <= max_weight,]
  }

  lPars <- data.frame(min = min(x1$LngtCm, na.rm = TRUE),
                      mean = mean(x1$LngtCm, na.rm = TRUE),
                      median = median(x1$LngtCm, na.rm = TRUE),
                      max = max(x1$LngtCm, na.rm = TRUE))

  print("Length statistics:")
  print(round(lPars,2))

  wPars <- data.frame(min = min(x1$IndWgt, na.rm = TRUE),
                      mean = mean(x1$IndWgt, na.rm = TRUE),
                      median = median(x1$IndWgt, na.rm = TRUE),
                      max = max(x1$IndWgt, na.rm = TRUE))

  print("Weight statistics:")
  print(round(wPars,2))

  m = lm(log(IndWgt) ~ log(LngtCm), data = x1)
  cm_breaks = attr(x, "cm.breaks")[-1] - 0.5
  tmp = x[["CA"]][1:length(cm_breaks), ]
  tmp$LngtCm = cm_breaks
  tmp$Wgt = exp(predict(m, newdata = tmp))

  if(plot) {

    opar <- par()
    on.exit(par(opar))
    layout(matrix(c(2,0,1,3), 2, 2, byrow = TRUE),
           widths = c(4,1), heights = c(1,4), respect = TRUE)
    par(mar = c(5, 4, 0.25, 0.25))
    plot(x1$LngtCm, x1$IndWgt,
         xlab = "Length [cm]", ylab = "Weight [g]")
    lines(tmp$LngtCm, tmp$Wgt, lwd = 3, col = 4)
    box(lwd = 1.5)
    par(mar = c(0.25, 4, 1, 0.25))
    xhist <- hist(x1$LngtCm, breaks = 30, plot = FALSE)
    barplot(xhist$counts, axes = TRUE, space = 0,
            ylim = c(0, 1.2 * max(xhist$counts)),
            xlab= "", ylab="Counts")
    box(lwd = 1.5)
    par(mar = c(5, 0.25, 0.25, 1))
    xhist <- hist(x1$IndWgt, breaks = 30, plot = FALSE)
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
  aphia <- unique(x[["HL"]]$Valid_Aphia)
  if (!is.na(aphia) && length(aphia) == 1) {
    if (exists("species_info")) {
      ind <- which(species_info$WoRMS_AphiaID == aphia)
      if (!is.na(ind) && length(ind) == 1) {
        aEmp <- species_info$a[ind]
        bEmp <- species_info$b[ind]

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




##' Add weight-at-length estimates to a `datras_raw` object
##'
##' Estimate catch weight from length data and add the resulting weight fields to
##' a `datras_raw` / `DATRASraw` object.
##'
##' The function derives weight-at-length either from an empirical
##' length-weight relationship fitted to the `CA` table or, if
##' `empirical = TRUE`, from the empirical helper functions
##' [add_weight_empirical()] and optionally [add_weight_by_haul_empirical()].
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE` (default), estimated weights are divided
##'   by haul duration in minutes.
##' @param max_length Optional numeric value giving the maximum length in
##'   centimetres to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param max_weight Optional numeric value giving the maximum individual weight
##'   in grams to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param empirical Logical. If `TRUE`, use empirical weight-at-length
##'   calculations via [add_weight_empirical()] instead of fitting a
##'   length-weight model to the `CA` table.
##' @param by_haul Logical. If `TRUE`, also add haul-level weight information
##'   using [add_weight_by_haul()] or [add_weight_by_haul_empirical()],
##'   depending on the value of `empirical`.
##'
##' @details
##' The function first calls [DATRAS::checkSpectrum()] and then proceeds in one
##' of two ways:
##'
##' \itemize{
##'   \item If `empirical = FALSE`, a linear model of the form
##'   \eqn{\log(IndWgt) ~ \log(LngtCm)} is fitted to positive individual weights
##'   in the `CA` table. Predicted weights are then assigned to length classes
##'   defined by `attr(x, "cm.breaks")`, multiplied by numbers-at-length, and
##'   optionally divided by haul duration.
##'
##'   \item If `empirical = TRUE`, weight is added using
##'   [add_weight_empirical()]. If `by_haul = TRUE`, haul-level weight is also
##'   added using [add_weight_by_haul_empirical()].
##' }
##'
##' When `by_haul = TRUE` and `empirical = FALSE`, haul-level weight is added
##' using [add_weight_by_haul()].
##'
##' @return A `datras_raw` object with estimated weight information added.
##'
##' @seealso [check_weight()], [add_weight_empirical()],
##'   [add_weight_by_haul()], [add_weight_by_haul_empirical()]
##'
##' @examples
##' \dontrun{
##' ## Add fitted weight-at-length estimates
##' x <- add_weight(x)
##'
##' ## Exclude large values when fitting the length-weight model
##' x <- add_weight(x, max_length = 100, max_weight = 10000)
##'
##' ## Use empirical weight-at-length instead
##' x <- add_weight(x, empirical = TRUE)
##'
##' ## Also add haul-level weight
##' x <- add_weight(x, by_haul = TRUE)
##' }
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
add_weight <- function (x,
                        per_minute = TRUE,
                        max_length = NULL,
                        max_weight = NULL,
                        empirical = FALSE,
                        by_haul = FALSE) {

  .check_class_datras(x)

  DATRAS::checkSpectrum(x)

  if (isTRUE(empirical)) {

    x <- add_weight_empirical(x, per_minute = per_minute)

    if (by_haul) {
      x <- add_weight_by_haul_empirical(x, per_minute = per_minute)
    }

  } else {

    x1 <- subset(x[["CA"]], IndWgt > 0)
    if (!is.null(max_length) && !is.na(max_length) && is.numeric(max_length)) {
      x1 <- x1[x1$LngtCm <= max_length,]
    }
    if (!is.null(max_weight) && !is.na(max_weight) && is.numeric(max_weight)) {
      x1 <- x1[x1$IndWgt <= max_weight,]
    }
    m = lm(log(IndWgt) ~ log(LngtCm), data = x1)
    cm_breaks = attr(x, "cm.breaks")[-1] - 0.5
    tmp = x[["CA"]][1:length(cm_breaks), ]
    tmp$LngtCm = cm_breaks
    tmp$Wgt = exp(predict(m, newdata = tmp))
    LW = tmp$Wgt
    Wgt <- sweep(x[["HH"]]$N, 2, LW, "*")

    if (isTRUE(per_minute)) {
      Wgt <- Wgt/x[["HH"]]$HaulDur
    }

    Wgt <- round(Wgt, 3)

    x[["HH"]]$Wgt <- Wgt[as.character(x[["HH"]]$haul.id),,drop=FALSE]

    if (by_haul) {
      x <- add_weight_by_haul(x, per_minute = per_minute)
    }
  }

  return(x)
}



##' Add empirical weight-at-length estimates to `HH`
##'
##' Calculate weight-at-length from empirical species-specific length-weight
##' parameters and add the resulting weights to the `HH` component of a
##' `datras_raw` / `DATRASraw` object.
##'
##' The function uses the Aphia ID in the `HL` table to look up the empirical
##' length-weight parameters `a` and `b` in `species_info`, predicts weight for
##' each length class defined by `attr(x, "cm.breaks")`, and multiplies these
##' by numbers-at-length stored in `HH$N`.
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE` (default), estimated weights are divided
##'   by haul duration in minutes.
##'
##' @details
##' The function requires that exactly one unique `Valid_Aphia` value is present
##' in `x[["HL"]]`, and that matching empirical length-weight parameters are
##' available in the internal `species_info` table.
##'
##' Weight-at-length is calculated as:
##' \deqn{
##'   W = a \times L^b
##' }
##'
##' where `L` is length in centimetres and `W` is weight in grams.
##'
##' The resulting length-specific weights are multiplied by the haul-specific
##' numbers-at-length matrix `HH$N`. If `per_minute = TRUE`, the resulting
##' weights are standardized by haul duration.
##'
##' @return A `datras_raw` object with an added `Wgt` field in `HH`.
##'
##' @seealso [add_weight()], [add_weight_by_haul_empirical()]
##'
##' @examples
##' \dontrun{
##' x <- add_weight_empirical(x)
##' x <- add_weight_empirical(x, per_minute = FALSE)
##' }
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
add_weight_empirical <- function (x,
                                  per_minute = TRUE) {

  .check_class_datras(x)

  DATRAS::checkSpectrum(x)

  aphia <- unique(x[["HL"]]$Valid_Aphia)
  if(length(aphia) > 1) stop("More than one Aphia ID in the data set. Not sure which a and b parameters in species_info to use. Please run this function for each species separately.")
  if(length(aphia) == 0) stop("No Aphia ID found in d[['HL']].")

  ## data("species_info")
  ind <- which(species_info$WoRMS_AphiaID == aphia)
  if(length(ind) > 1) stop("More than one matching Aphia ID found in species_info. Did you modify species_info? Please make sure to have unique Aphia IDs in species_info")
  if(length(ind) == 0) stop("Aphia ID could not be matched in species_info. Please make sure your species is in species_info.")

  a <- species_info$a[ind]
  b <- species_info$b[ind]

  if(is.na(a) || !is.numeric(a)) stop("Matched a in species_info is NA or not numeric! Please check the value!")
  if(is.na(b) || !is.numeric(b)) stop("Matched b in species_info is NA or not numeric! Please check the value!")

  cm_breaks = attr(x, "cm.breaks")[-1] - 0.5
  tmp = x[["CA"]][1:length(cm_breaks), ]
  tmp$LngtCm = cm_breaks
  tmp$Wgt = a * tmp$LngtCm ^ b
  LW = tmp$Wgt

  Wgt <- sweep(x[["HH"]]$N, 2, LW, "*")

  if (isTRUE(per_minute)) {
    Wgt <- Wgt/x[["HH"]]$HaulDur
  }

  Wgt <- round(Wgt, 3)

  x[["HH"]]$Wgt <- Wgt[as.character(x[["HH"]]$haul.id),,drop=FALSE]

  return(x)
}



##' Add total haul biomass to `HH`
##'
##' Calculate total biomass by haul and add it to the `HH` component of a
##' `datras_raw` / `DATRASraw` object using the underlying DATRAS method.
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE` (default), biomass is divided by haul
##'   duration in minutes.
##'
##' @details
##' This function is a thin wrapper around [DATRAS::addWeightByHaul()], applied
##' after checking that the input is a valid `datras_raw` object.
##'
##' @return A `datras_raw` object with haul-level biomass added to `HH`.
##'
##' @seealso [add_weight()], [add_weight_by_haul_empirical()]
##'
##' @examples
##' \dontrun{
##' x <- add_weight_by_haul(x)
##' x <- add_weight_by_haul(x, per_minute = FALSE)
##' }
##'
##' @importFrom DATRAS addWeightByHaul
##'
##' @export
add_weight_by_haul <- function (x,
                                per_minute = TRUE) {
  .check_class_datras(x)
  DATRAS::addWeightByHaul(d = x, t1min = per_minute)
}




##' Add empirical total haul biomass to `HH`
##'
##' Calculate total biomass by haul from empirical species-specific
##' length-weight parameters and add it to the `HH` component of a
##' `datras_raw` / `DATRASraw` object.
##'
##' The function uses the Aphia ID in the `HL` table to look up the empirical
##' length-weight parameters `a` and `b` in `species_info`, predicts weight for
##' each length class defined by `attr(x, "cm.breaks")`, and combines these
##' with haul-specific numbers-at-length stored in `HH$N` to compute total haul
##' biomass.
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE` (default), haul biomass is divided by
##'   haul duration in minutes.
##'
##' @details
##' The function requires that exactly one unique `Valid_Aphia` value is present
##' in `x[["HL"]]`, and that matching empirical length-weight parameters are
##' available in the internal `species_info` table.
##'
##' Weight-at-length is calculated as:
##' \deqn{
##'   W = a \times L^b
##' }
##'
##' Total biomass for each haul is then calculated by multiplying the haul-level
##' numbers-at-length by the predicted weight-at-length vector and summing across
##' length classes.
##'
##' @return A `datras_raw` object with an added `HaulWgt` field in `HH`.
##'
##' @seealso [add_weight()], [add_weight_empirical()], [add_weight_by_haul()]
##'
##' @examples
##' \dontrun{
##' x <- add_weight_by_haul_empirical(x)
##' x <- add_weight_by_haul_empirical(x, per_minute = FALSE)
##' }
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
add_weight_by_haul_empirical <- function (x,
                                          per_minute = TRUE) {

  .check_class_datras(x)

  DATRAS::checkSpectrum(x)

  aphia <- unique(x[["HL"]]$Valid_Aphia)
  if(length(aphia) > 1) stop("More than one Aphia ID in the data set. Not sure which a and b parameters in species_info to use. Please run this function for each species separately.")
  if(length(aphia) == 0) stop("No Aphia ID found in d[['HL']].")

  ## data("species_info")
  ind <- which(species_info$WoRMS_AphiaID == aphia)
  if(length(ind) > 1) stop("More than one matching Aphia ID found in species_info. Did you modify species_info? Please make sure to have unique Aphia IDs in species_info")
  if(length(ind) == 0) stop("Aphia ID could not be matched in species_info. Please make sure your species is in species_info.")

  a <- species_info$a[ind]
  b <- species_info$b[ind]

  if(is.na(a) || !is.numeric(a)) stop("Matched a in species_info is NA or not numeric! Please check the value!")
  if(is.na(b) || !is.numeric(b)) stop("Matched b in species_info is NA or not numeric! Please check the value!")

  cm_breaks = attr(x, "cm.breaks")[-1] - 0.5
  tmp = x[["CA"]][1:length(cm_breaks), ]
  tmp$LngtCm = cm_breaks
  tmp$Wgt = a * tmp$LngtCm ^ b

  LW = tmp$Wgt
  WgtByHaul <- function(i) {
    x[["HH"]]$N[i, ] %*% LW
  }
  x[["HH"]]$HaulWgt = unlist(lapply(1:nrow(x[["HH"]]), WgtByHaul))
  if (isTRUE(per_minute)) {
    x[["HH"]]$HaulWgt = x[["HH"]]$HaulWgt/x[["HH"]]$HaulDur
  }

  return(x)
}
