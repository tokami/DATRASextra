
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
##' If available, lookup length-weight parameters are also retrieved from
##' `species_info` for comparison.
##'
##' @return A list with four elements:
##' \itemize{
##'   \item `lPars`: a data frame with summary statistics for observed lengths,
##'   \item `wPars`: a data frame with summary statistics for observed weights,
##'   \item `parEst`: a data frame with estimated length-weight parameters `a`
##'   and `b`,
##'   \item `parEmp`: a data frame with lookup length-weight parameters `a`
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

  ## Lookup parameters
  aEmp <- bEmp <- NA
  aphia <- unique(x[["HL"]]$Valid_Aphia)
  if (!is.na(aphia) && length(aphia) == 1) {
    if (exists("species_info")) {
      ind <- which(species_info$WoRMS_AphiaID == aphia)
      if (!is.na(ind) && length(ind) == 1) {
        aEmp <- species_info$a[ind]
        bEmp <- species_info$b[ind]

        print("Lookup LW parameters in the species_info table:")
        print(paste0("a = ", round(aEmp,3), " b = ", round(bEmp,3)))
      }
    }
  }

  res <- list(lPars = lPars,
              wPars = wPars,
              parEst = data.frame(a = a, b = b),
              parEmp = data.frame(a = aEmp, b = bEmp))

  return(invisible(res))
}



##' Add weight-at-length estimates to a `datras_raw` object
##'
##' Estimate catch weight from length data and add the resulting weight fields to
##' a `datras_raw` / `DATRASraw` object.
##'
##' The function derives weight-at-length either from an lookup length-weight
##' relationship fitted to the `CA` table or, if `lw_source = "lookup"`, uses
##' length-weight parameters from the species_info table.
##'
##' @param x A `datras_raw` object.
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
##' @param lw_source Character string specifying the source of length-weight
##'   parameters. One of `"ca"` or `"lookup"`.
##' @param lookup_as_backup Logical. If `TRUE`, lookup parameters of the
##'   length-weight relationship (a, b) in the species_info table are used.
##'   Default: `FALSE`.
##' @param verbose Logical. If `TRUE` (default), progress messages are printed.
##'
##' @details
##'
##' \itemize{
##'   \item If `lw_source = "lookup"`, a linear model of the form
##'   \eqn{\log(IndWgt) ~ \log(LngtCm)} is fitted to positive individual weights
##'   in the `CA` table. Predicted weights are then assigned to length classes
##'   defined by `attr(x, "cm.breaks")`, multiplied by numbers-at-length, and
##'   optionally divided by haul duration.
##'
##'   \item If `lw_source = "lookup"`, weight is added using length-weight
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
##' ## Use lookup weight-at-length instead from the species_info table
##' x <- add_weight_at_length(dab, lw_source = "lookup")
##'
##' @export
add_weight_at_length <- function (x,
                                  max_length = NULL,
                                  max_weight = NULL,
                                  plus_group = FALSE,
                                  lw_source = c("lookup", "ca"),
                                  lookup_as_backup = FALSE,
                                  verbose = TRUE) {

  lw_source <- match.arg(lw_source)

  .check_class_datras(x)

  if (!.has_numbers_at_length(x)) stop("Adding weight at length information requires information about the numbers at length. Did you run 'add_numbers_at_length(x)'?")

  aphia <- unique(x[["HL"]]$Valid_Aphia)
  n_aphia <- length(aphia)

  ## if(length(aphia) > 1) stop("More than one Aphia ID in the data set. Not sure which a and b parameters in species_info to use. Please run this function for each species separately.")
  if(n_aphia == 0) stop("No Aphia ID found in d[['HL']].")

  if (verbose && n_aphia > 1) message("Multiple aphia IDs in data set (n = ", n_aphia, "). Caclulating weight at length for each and summing them all up.")

  x[["HH"]][["Wgt"]] <- x[["HH"]][["N"]]
  x[["HH"]][["Wgt"]][] <- 0

  warn_msgs <- character()

  if (lw_source == "lookup") {

    for (i in seq_len(n_aphia)) {

      if (verbose && n_aphia > 1) message("Running aphia: ", aphia[i])

      Wgt <- withCallingHandlers(
        .get_wgt_one_lookup(x, aphia[i], n_aphia, verbose),
        warning = function(w) {
          warn_msgs <<- c(warn_msgs, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      )

      if(is.null(Wgt)) {
        if (n_aphia == 1) {
          stop("Couldn't convert length into weight. Please check the lookup information in the species_info table or consider using the CA data set if available (lw_source = 'lookup').")
        } else {
          next()
        }
      }

      ind_hh <- match(rownames(Wgt), rownames(x[["HH"]]$Wgt))

      x[["HH"]]$Wgt[ind_hh,] <- x[["HH"]]$Wgt[ind_hh,] + Wgt

    }

  } else if (lw_source == "ca") {

    for (i in seq_len(n_aphia)) {

      if (verbose) message("Running aphia: ", aphia[i])

      Wgt <- withCallingHandlers(
        .get_wgt_one_ca(x, aphia[i], n_aphia,
                        max_length, max_weight,
                        plus_group,
                        verbose),
        warning = function(w) {
          warn_msgs <<- c(warn_msgs, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      )

      if (is.null(Wgt) && isTRUE(lookup_as_backup)) {
        if (isTRUE(verbose)) message("Using lookup info in species_info table.")
        Wgt <- withCallingHandlers(
          .get_wgt_one_lookup(x, aphia[i], n_aphia, verbose),
          warning = function(w) {
            warn_msgs <<- c(warn_msgs, conditionMessage(w))
            invokeRestart("muffleWarning")
          }
        )
      }

      if(is.null(Wgt)) {
        if (n_aphia == 1) {
          stop("Couldn't convert length into weight. Please check the CA data set or consider using lookup information in the species_info table (lw_source = 'lookup').")
        } else {
          next()
        }
      }

      ind_hh <- match(rownames(Wgt), rownames(x[["HH"]]$Wgt))

      x[["HH"]]$Wgt[ind_hh,] <- x[["HH"]]$Wgt[ind_hh,] + Wgt

    }

  } else stop("Don't know the lw_source. Only 'ca' or 'lookup' known.")

  unique_warns <- unique(warn_msgs)
  if (length(unique_warns) > 0) {
    warning(
      paste(
        "Unique warnings produced in loop:",
        paste(unique_warns, collapse = "\n- "),
        sep = "\n- "
      ),
      call. = FALSE
    )
  }

  return(x)
}



##' Add total haul biomass to `HH`
##'
##' Calculate total biomass by haul and add it to the `HH` component of a
##' `datras_raw` / `DATRASraw` object.
##'
##' Optionally, total biomass can be standardized by haul duration and returned
##' as biomass per minute. Length classes can also be aggregated into coarser
##' bins via `length_cuts`.
##'
##' @param x A `datras_raw` object.
##' @param per_minute Logical. If `TRUE`, add `HaulWgtPerMin`, calculated as
##'   `HaulWgt` divided by haul duration in minutes. If `FALSE`, only `HaulWgt`
##'   is added.
##' @param max_length Optional numeric value giving the maximum length in
##'   centimetres to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param max_weight Optional numeric value giving the maximum individual
##'   weight in grams to retain when fitting the length-weight relationship.
##'   Observations above this value are excluded.
##' @param lw_source Character string specifying the source of length-weight
##'   parameters. One of `"ca"` or `"lookup"`.
##' @param length_cuts Optional numeric vector of break points for aggregating
##'   the original length classes into coarser bins. Must be strictly
##'   increasing.
##'
##' @details
##' If weight-at-length information is not already present, the function first
##' calls [add_weight_at_length()] to create `x[["HH"]][["Wgt"]]`.
##'
##' Weight-at-length is calculated as:
##' \deqn{
##'   W = a \times L^b
##' }
##'
##' Total biomass for each haul is calculated by summing estimated
##' weight-at-length across length classes and is stored in
##' `x[["HH"]][["HaulWgt"]]`.
##'
##' If `length_cuts` is supplied, `HaulWgt` is a matrix with one column per
##' aggregated length bin. Otherwise, `HaulWgt` is a vector with one value per
##' haul.
##'
##' If `per_minute = TRUE`, the function also adds
##' `x[["HH"]][["HaulWgtPerMin"]]`, calculated by dividing `HaulWgt` by
##' `HaulDur`. If `HaulWgt` is a matrix, each row is divided by the corresponding
##' haul duration.
##'
##' @return A `datras_raw` object with `HaulWgt` added to `HH`. If
##'   `per_minute = TRUE`, `HaulWgtPerMin` is also added.
##'
##' @seealso [add_weight_at_length()]
##'
##' @examples
##' ## Add numbers at length
##' dab <- add_numbers_at_length(dab)
##'
##' ## Add total haul biomass
##' x <- add_total_weight_by_haul(dab)
##'
##' ## Add total haul biomass and biomass per minute
##' x <- add_total_weight_by_haul(dab, per_minute = TRUE)
##'
##' ## Use length-weight parameters from the species_info table
##' x <- add_total_weight_by_haul(dab, lw_source = "lookup")
##'
##' @export
add_total_weight_by_haul <- function (x,
                                      per_minute = FALSE,
                                      max_length = NULL,
                                      max_weight = NULL,
                                      lw_source = c("lookup", "ca"),
                                      length_cuts = NULL) {

  lw_source <- match.arg(lw_source)

  .check_class_datras(x)

  if (!.has_weight_at_length(x)) {
    x <- add_weight_at_length(x,
                              max_length = max_length,
                              max_weight = max_weight,
                              lw_source = lw_source)
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


  if (isTRUE(per_minute)) {
    if (inherits(x[["HH"]][["HaulWgt"]], "matrix")) {
      x[["HH"]][["HaulWgtPerMin"]] <- sweep(
        x[["HH"]][["HaulWgt"]],
        MARGIN = 1,
        STATS = x[["HH"]]$HaulDur,
        FUN = "/"
      )
    } else {
      x[["HH"]][["HaulWgtPerMin"]] <- x[["HH"]][["HaulWgt"]] / x[["HH"]]$HaulDur
    }
  }

  x
}



## Internal functions ------------------------------------------------------------

.has_weight_at_length <- function(x) {
  !is.null(x[["HH"]][["Wgt"]]) && is.matrix(x[["HH"]][["Wgt"]])
}


.get_wgt_one_lookup <- function(x, aphia, n_aphia,
                                   verbose = TRUE) {

  xsub <- subset(x, Valid_Aphia == aphia)

  ind <- match(aphia, species_info$WoRMS_AphiaID)

  if(length(ind) > 1) {
    txt <- "More than one matching Aphia ID found in species_info. Did you modify species_info? Please make sure to have unique Aphia IDs in species_info."
    if (n_aphia == 1) {
      stop(txt)
    } else {
      if (verbose) message(txt, " Skipping: ", aphia)
      return(NULL)
    }
  }

  if(length(ind) == 0) stop("Aphia ID could not be matched in species_info. Please make sure your species is in species_info.")

  a <- species_info$a[ind]
  b <- species_info$b[ind]

  if(is.na(a) || !is.numeric(a)) {
    txt <- "Matched a in species_info is NA or not numeric! Please check the value!"
    if (n_aphia == 1) {
      stop(txt)
    } else {
      if (verbose) message(txt, " Skipping: ", aphia)
      return(NULL)
    }
  }
  if(is.na(b) || !is.numeric(b)) {
    txt <- "Matched b in species_info is NA or not numeric! Please check the value!"
    if (n_aphia == 1) {
      stop(txt)
    } else {
      if (verbose) message(txt, " Skipping: ", aphia)
      return(NULL)
    }
  }

  cm_breaks = attr(x, "cm.breaks")
  nl <- length(cm_breaks)
  dls <- diff(cm_breaks)
  mid_lengths <- cm_breaks[-1] + dls / 2
  tmp <- x[["CA"]][1:length(mid_lengths), ]
  tmp$LngtCm <- mid_lengths
  tmp$Wgt <- a * tmp$LngtCm ^ b
  LW <- tmp$Wgt

  if (n_aphia > 1) {
    xsub <- add_numbers_at_length(xsub,
                                  cm_breaks = cm_breaks,
                                  by = cm_breaks[2] - cm_breaks[1])
  }

  Wgt <- sweep(xsub[["HH"]]$N, 2, LW, "*")

  round(Wgt, 3)
}


.get_wgt_one_ca <- function(x, aphia, n_aphia,
                            max_length, max_weight,
                            plus_group,
                            verbose = TRUE) {

  xsub <- subset(x, Valid_Aphia == aphia)

  if (is.null(xsub[["CA"]]) || nrow(xsub[["CA"]]) < 1) {
    if(isTRUE(verbose)) message("CA not available.")
    return(NULL)
  }

  x1 <- subset(xsub[["CA"]], IndWgt > 0)
  if (!is.null(max_length) && !is.na(max_length) && is.numeric(max_length)) {
    x1 <- x1[x1$LngtCm <= max_length,]
  }
  if (!is.null(max_weight) && !is.na(max_weight) && is.numeric(max_weight)) {
    x1 <- x1[x1$IndWgt <= max_weight,]
  }

  if (nrow(x1) < 3) {
    if(isTRUE(verbose)) message("Less than 3 observations in CA")
    return(NULL)
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

  if (n_aphia > 1) {
    xsub <- add_numbers_at_length(xsub,
                                  cm_breaks = cm_breaks,
                                  by = cm_breaks[2] -
                                    cm_breaks[1])
  }

  Wgt <- sweep(xsub[["HH"]]$N, 2, LW, "*")

  round(Wgt, 3)
}
