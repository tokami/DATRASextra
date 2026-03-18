
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
##' @seealso [check_lengths()]
##'
##' @examples
##'
##' ## Add numbers at length
##' dab <- add_numbers_at_length(dab)
##'
##' res <- check_weights(dab)
##'
##' ## Restrict to plausible values
##' res <- check_weights(dab, max_length = 100, max_weight = 10000)
##'
##' @export
check_weights <- function (x,
                           max_length = NULL,
                           max_weight = NULL,
                           plot = TRUE) {

  .check_class_datras(x)

  if (!.has_numbers_at_length(x)) stop("No numbers at length information found in HH. Did you run 'add_numbers_at_length(x)'?")

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

    opar <- par(no.readonly = TRUE)
    on.exit(par(opar), add = TRUE)
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
##' `empirical = TRUE`, uses length-weight parameters from the species_info table.
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE` (default), estimated weights are
##'   divided by haul duration in minutes.
##' @param max_length Optional numeric value giving the maximum length in
##'   centimetres to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param max_weight Optional numeric value giving the maximum individual
##'   weight in grams to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param plus_group Logical. If `TRUE` the midlength for the weight
##'   calculation of the last length bin is not using the upper limit of this
##'   length bin, which might be `Inf` or arbitrarily high and result in an
##'   unrealistically high weight for that length bin. Instead the lower limit
##'   plus half of the size of the second last length bin is used to define the
##'   mid length of the largest length bin.
##' @param empirical Logical. If `TRUE`, use empirical weight-at-length
##'   calculations instead of fitting a length-weight model to the `CA` table.
##'
##' @details
##'
##' \itemize{
##'   \item If `empirical = FALSE`, a linear model of the form
##'   \eqn{\log(IndWgt) ~ \log(LngtCm)} is fitted to positive individual weights
##'   in the `CA` table. Predicted weights are then assigned to length classes
##'   defined by `attr(x, "cm.breaks")`, multiplied by numbers-at-length, and
##'   optionally divided by haul duration.
##'
##'   \item If `empirical = TRUE`, weight is added using length-weight
##' parameters from the species_info table. }
##'
##'
##' @return A `datras_raw` object with estimated weight information added.
##'
##' @seealso [check_weights()], [add_total_weight_by_haul()]
##'
##' @examples
##'
##' ## Add numbers at length
##' dab <- add_numbers_at_length(dab)
##'
##' ## Add fitted weight-at-length estimates
##' x <- add_weight_at_length(dab)
##'
##' ## Exclude large values when fitting the length-weight model
##' x <- add_weight_at_length(dab, max_length = 100, max_weight = 10000)
##'
##' ## Use empirical weight-at-length instead
##' x <- add_weight_at_length(dab, empirical = TRUE)
##'
##' @export
add_weight_at_length <- function (x,
                                  per_minute = TRUE,
                                  max_length = NULL,
                                  max_weight = NULL,
                                  plus_group = FALSE,
                                  empirical = FALSE) {

  .check_class_datras(x)

  if (!.has_numbers_at_length(x)) stop("Adding weight at length information requires information about the numbers at length. Did you run 'add_numbers_at_length(x)'?")


  if (isTRUE(empirical)) {

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


  } else {

    x1 <- subset(x[["CA"]], IndWgt > 0)
    if (!is.null(max_length) && !is.na(max_length) && is.numeric(max_length)) {
      x1 <- x1[x1$LngtCm <= max_length,]
    }
    if (!is.null(max_weight) && !is.na(max_weight) && is.numeric(max_weight)) {
      x1 <- x1[x1$IndWgt <= max_weight,]
    }

    m <- lm(log(IndWgt) ~ log(LngtCm), data = x1)
    cm_breaks <- attr(x, "cm.breaks")
    nl <- length(cm_breaks)
    dls <- diff(cm_breaks)
    mid_lengths <- cm_breaks[-1] + dls / 2
    nml <- length(mid_lengths)

    if (is.infinite(cm_breaks[nl]) || isTRUE(plus_group)) {
      mid_lengths[nml] <- cm_breaks[nl-1] + dls[nml-1] / 2
    } else if (cm_breaks[nl] > 1.2 * max(x[["CA"]]$LngtCm, na.rm = TRUE)) {
      warning("The upper limit of the largest length bin is more than 20% larger than the largest length measurement in CA. The weight calculation based on the mid length uses this large upper limit, which might result in unrealistically high weights. Is the largest length bin a plus group? Then consider, setting plus_group = TRUE.")
    }


    tmp <- x[["CA"]][1:length(mid_lengths), ]
    tmp$LngtCm <- mid_lengths
    tmp$Wgt <- exp(predict(m, newdata = tmp))
    LW <- tmp$Wgt
    Wgt <- sweep(x[["HH"]]$N, 2, LW, "*")

    if (isTRUE(per_minute)) {
      Wgt <- Wgt/x[["HH"]]$HaulDur
    }

    Wgt <- round(Wgt, 3)

    x[["HH"]]$Wgt <- Wgt[as.character(x[["HH"]]$haul.id),,drop=FALSE]
  }

  return(x)
}



##' Add total haul biomass to `HH`
##'
##' Calculate total biomass by haul and add it to the `HH` component of a
##' `datras_raw` / `DATRASraw` object based on available information in the `CA`
##' data set. If `CA` data is not available, total haul biomass can be
##' calculated from empirical species-specific length-weight parameters.
##'
##' Optionally, the resulting length classes can be aggregated into coarser bins
##' via `length_cuts`.
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE` (default), estimated weights are
##'   divided by haul duration in minutes.
##' @param max_length Optional numeric value giving the maximum length in
##'   centimetres to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param max_weight Optional numeric value giving the maximum individual
##'   weight in grams to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param empirical Logical. If `TRUE`, use empirical weight-at-length
##'   calculations instead of fitting a length-weight model to the `CA` table.
##' @param length_cuts Optional numeric vector of break points for aggregating
##'   the original length classes into coarser bins after numbers-at-length have
##'   been calculated. Must be strictly increasing.
##'
##' @details
##'
##' If empirical = TRUE, the function requires that exactly one unique
##' `Valid_Aphia` value is present in `x[["HL"]]`, and that matching empirical
##' length-weight parameters are available in the internal `species_info` table.
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
##' Provide your own a and b parameters by overwriting the relevant fields in
##' the species_info table.
##'
##' @return A `datras_raw` object with haul-level biomass added to `HH`.
##'
##' @seealso [add_weight_at_length()]
##'
##' @examples
##'
##' ## Add numbers at length
##' dab <- add_numbers_at_length(dab)
##'
##' x <- add_total_weight_by_haul(dab)
##'
##' x <- add_total_weight_by_haul(dab, empirical = TRUE)
##'
##' @export
add_total_weight_by_haul <- function (x,
                                      per_minute = TRUE,
                                      max_length = NULL,
                                      max_weight = NULL,
                                      empirical = FALSE,
                                      length_cuts = NULL) {
  .check_class_datras(x)

  if (!.has_weight_at_length(x)) {
    x <- add_weight_at_length(x,
                              per_minute = per_minute,
                              max_length = max_length,
                              max_weight = max_weight,
                              empirical = empirical)
  }

  if (!is.null(length_cuts)) {

    stopifnot(is.numeric(length_cuts))
    stopifnot(length(length_cuts) > 1L)
    stopifnot(all(diff(length_cuts) > 0))

    old_breaks <- attr(x, "cm.breaks")
    x[["HH"]][["HaulWgt"]] <- .aggregate_length_bins(
      mat = x[["HH"]][["Wgt"]],
      old_breaks = old_breaks,
      new_breaks = length_cuts
    )

  } else {

    x[["HH"]][["HaulWgt"]] <- rowSums(x[["HH"]][["Wgt"]], na.rm = TRUE)

  }

  x
}



## Internal functions ------------------------------------------------------------

.has_weight_at_length <- function(x) {
  !is.null(x[["HH"]][["Wgt"]]) && is.matrix(x[["HH"]][["Wgt"]])
}
