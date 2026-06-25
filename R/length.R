
## Main functions ----------------------------------------------------------------

##' Check and summarize length distributions in a `datras_raw` object
##'
##' Create haul-by-length counts from the `HL` table of a `datras_raw` /
##' `DATRASraw` object and inspect the resulting length distribution.
##'
##' The function bins fish lengths into user-defined or automatically derived
##' length classes, constructs a haul-by-length count matrix, computes summary
##' statistics of the overall length distribution, and optionally plots the
##' observed spectrum on both raw and log scales.
##'
##' @param x A `datras_raw` object.
##' @param cm_breaks Numeric vector of break points for length classes in
##'   centimetres. If supplied, these are used directly to bin `LngtCm`.
##' @param by Optional bin width in centimetres. If `cm_breaks` is not supplied,
##'   the bin width is determined from this argument or, if `NULL`, from the
##'   `get_accuracy_cm()` function.
##' @param length_percentile Numeric percentile used to summarize the upper tail
##'   of the observed length distribution. Defaults to `99.9999`.
##' @param plot Logical. If `TRUE` (default), plot the length spectrum on raw
##'   and log count scales.
##'
##' @details
##' Lengths are grouped into classes using [cut()] and counts are aggregated by
##' haul and length class.
##'
##' In addition to the haul-by-length matrix, the function calculates summary
##' statistics for the pooled length distribution, including:
##' \itemize{
##'   \item observed minimum length,
##'   \item weighted mean length,
##'   \item median length,
##'   \item observed maximum length,
##'   \item empirical maximum length from `species_info`, if available,
##'   \item a user-defined upper percentile of the length distribution.
##' }
##'
##' The function also reports the number and percentage of observations above the
##' empirical maximum length and above the selected percentile threshold.
##'
##' If multiple species are present in the `HL` table, the combined spectrum
##' across all species is used and a warning is issued.
##'
##' @return The input `datras_raw` object returned invisibly, with a
##' `"length_check"` attribute attached. That attribute is a list with three
##' elements:
##' \itemize{
##'   \item `N`: a haul-by-length count matrix,
##'   \item `lPars`: a data frame of summary statistics for the length
##'   distribution,
##'   \item `nAbove`: a data frame with the number and percentage of observations
##'   above selected upper-length thresholds.
##' }
##'
##' @seealso [check_weights()]
##'
##' @examples
##' \dontrun{
##' x <- check_lengths(x)
##' attr(x, "length_check")$lPars
##'
##' ## Use custom length bins
##' x <- check_lengths(x, cm_breaks = seq(0, 100, by = 1))
##'
##' ## Use an automatically generated spectrum with 0.5 cm bins
##' x <- check_lengths(x, by = 0.5)
##' }
##'
##' @export
check_lengths <- function(x,
                         cm_breaks = NULL,
                         by = get_accuracy_cm(x),
                         length_percentile = 99.9999,
                         plot = TRUE) {

  .check_class_datras(x)

  if (is.null(cm_breaks)) {
    cm_breaks <- .default_cm_breaks(x, by = by)
  }

  if (length(levels(x[["HL"]]$Species)) > 1)
    warning("Multiple species found - spectrum will contain all species")
  if (any(is.na(x[["HH"]]$DataType))) {
    warning(sum(is.na(x[["HH"]]$DataType)), " NA's found in DataType. These hauls will be removed")
    x <- subset(x, !is.na(DataType))
  }
  if (any(x[["HH"]]$DataType == "S"))
    warning("DataType 'S' found in length data. These hauls will be interpreted as DataType 'R' wrt. total numbers caught.")
  x[["HL"]]$sizeGroup <- cut(x[["HL"]]$LngtCm, breaks = cm_breaks,
                             right = FALSE)
  N <- xtabs(Count ~ haul.id + sizeGroup, data = x[["HL"]])
  N <- round(N)

  nout <- N[as.character(x[["HH"]]$haul.id), , drop = FALSE]
  attr(nout, "cm.breaks") <- cm_breaks

  nSum <- colSums(N, na.rm = TRUE)

  midL <- cm_breaks[-length(cm_breaks)] + by/2

  ## Mean length
  meanL <- weighted.mean(midL, unname(nSum))

  ## Median length
  all.lengths <- rep(midL, times = unname(nSum))
  medianL <- median(all.lengths)

  ## Minimum length (observed)
  minLObs <- min(x[["HL"]]$LngtCm, na.rm = TRUE)

  ## Maximum length (observed)
  maxLObs <- max(x[["HL"]]$LngtCm, na.rm = TRUE)

  ## Maximum length (empirical)
  maxLEmp <- NA
  aphia <- unique(x[["HL"]]$Valid_Aphia)
  if(all(!is.na(aphia)) && length(aphia) == 1){
    if (exists("species_info")) {
      ind <- which(species_info$WoRMS_AphiaID == aphia)
      if(!is.na(ind) && length(ind) == 1){
        maxLEmp <- species_info$maxL[ind]
      }
    }
  }

  ## Percentile 99.9999% (default)
  percL <- quantile(all.lengths, probs = length_percentile/100)

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

    opar <- par(no.readonly = TRUE)
    on.exit(par(opar), add = TRUE)
    par(mfrow = c(2,1), mar = c(2,4,1,1), oma = c(2,0,0,0))
    ## counts
    bar_x <- barplot(nSum, names.arg = midL,
                     xlab = "",
                     ylab = "Count")
    abline(v = .map2bar(minLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
    abline(v = .map2bar(meanL, midL, bar_x), col = 3, lwd = 2)
    abline(v = .map2bar(medianL, midL, bar_x), col = 4, lty = 2, lwd = 2)
    abline(v = .map2bar(maxLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
    abline(v = .map2bar(maxLEmp, midL, bar_x), col = 4, lty = 1, lwd = 2)
    abline(v = .map2bar(percL, midL, bar_x), col = 2, lty = 2, lwd = 2)
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
    abline(v = .map2bar(minLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
    abline(v = .map2bar(meanL, midL, bar_x), col = 3, lwd = 2)
    abline(v = .map2bar(medianL, midL, bar_x), col = 4, lty = 2, lwd = 2)
    abline(v = .map2bar(maxLObs, midL, bar_x), col = 4, lty = 3, lwd = 2)
    abline(v = .map2bar(maxLEmp, midL, bar_x), col = 4, lty = 1, lwd = 2)
    abline(v = .map2bar(percL, midL, bar_x), col = 2, lty = 2, lwd = 2)
  }

  attr(x, "length_check") <- list(N = nout,
                                   lPars = lVals,
                                   nAbove = nAbove)

  return(invisible(x))
}


##' Add numbers-at-length to a DATRAS object
##'
##' Calculates numbers-at-length for each haul and stores the result in the
##' `HH` table of a `DATRASraw` object as matrix `N`, with one row per haul and
##' one column per length class.
##'
##' By default, numbers-at-length are calculated using the available haul-level
##' length data in `HL` and the default length recording resolution of the data.
##'
##' @param x A `DATRASraw` object.
##' @param cm_breaks Numeric vector of break points defining the length classes
##'   in cm. If `NULL`, break points are created automatically from the observed
##'   range of `HL$LngtCm` using `by`.
##' @param by Numeric scalar giving the width of the default length classes in
##'   cm. Defaults to the survey's native recording resolution via
##'   [get_accuracy_cm()]. Only used when `cm_breaks = NULL`.
##'
##' @details
##' The function first adds numbers-at-length at the finest available length
##' resolution and stores the result as `x[["HH"]][["N"]]`.
##'
##' The applied break points are stored as attribute `cm.breaks` on the returned
##' object.
##'
##' @return A `DATRASraw` object with numbers-at-length added to the `HH`
##'   component as matrix `N`.
##'
##' @seealso [add_total_numbers_by_haul()]
##'
##' @examples
##' ## Add numbers-at-length using the default length resolution
##' x <- add_numbers_at_length(dab)
##'
##' @export
add_numbers_at_length <- function(x,
                                  cm_breaks = NULL,
                                  by = get_accuracy_cm(x)) {

  .check_class_datras(x)

  if (is.null(cm_breaks)) {
    cm_breaks <- .default_cm_breaks(x, by = by)
  }

  x <- DATRAS::addSpectrum(x, cm.breaks = cm_breaks, by = by)

  x
}


##' Add total numbers by haul to a DATRAS object
##'
##' Calculates total numbers for each haul by summing numbers-at-length across
##' all length classes, and stores the result in the `HH` table as `HaulN`.
##'
##' If numbers-at-length are not already present in the object, they are first
##' created with [add_numbers_at_length()].
##'
##' Optionally, the resulting length classes can be aggregated into coarser bins
##' via `length_cuts`.
##'
##' @param x A `DATRASraw` object.
##' @param cm_breaks Numeric vector of break points defining the length classes
##'   in cm. If `NULL`, break points are created automatically from the observed
##'   range of `HL$LngtCm` using `by`. Only used if numbers-at-length must first
##'   be added.
##' @param by Numeric scalar giving the width of the default length classes in
##'   cm. Only used when `cm_breaks = NULL` and numbers-at-length must first be
##'   added.
##' @param length_cuts Optional numeric vector of break points for aggregating
##'   the original length classes into coarser bins after numbers-at-length have
##'   been calculated. Must be strictly increasing.
##'
##' @details This function sums the matrix `x[["HH"]][["N"]]` over length
##'   classes and writes the result to `x[["HH"]][["HaulN"]]`. If `length_cuts`
##'   is provided, these original classes are summed into the requested bins
##'   instead of a single vector.
##'
##' If `N` is not yet available, the function calls [add_numbers_at_length()]
##' first.
##'
##' @return A `DATRASraw` object with total numbers by haul added to the `HH`
##'   component as column `HaulN`.
##'
##' @seealso [add_numbers_at_length()]
##'
##' @examples
##'
##' ## Add total numbers by haul
##' x <- add_total_numbers_by_haul(dab)
##'
##' ## Aggregate into broader bins
##' x <- add_total_numbers_by_haul(dab, length_cuts = c(0, 10, 20, 30, Inf))
##'
##' @export
add_total_numbers_by_haul <- function(x,
                                      cm_breaks = NULL,
                                      by = get_accuracy_cm(x),
                                      length_cuts = NULL) {
  .check_class_datras(x)

  ## When HL has no length data (LngtCm all NA) and no length_cuts are
  ## requested, skip the N matrix path and compute HaulN directly.
  has_lengths <- any(is.finite(x[["HL"]][["LngtCm"]]))
  if (!has_lengths && is.null(length_cuts)) {
    hl <- x[["HL"]]
    hh_ids <- as.character(x[["HH"]][["haul.id"]])

    if (any(is.finite(hl$Count))) {
      ## Count is available: sum per-length-class raised numbers by haul.
      ## This gives the same result as rowSums(N) in the normal path.
      message("Note: LngtCm is all NA - computing HaulN by summing Count per haul.")
      totals <- tapply(as.numeric(hl$Count), as.character(hl$haul.id),
                       sum, na.rm = TRUE)
    } else {
      ## Count is also unavailable (e.g. catch table with one row per species
      ## per haul and no length breakdown). TotalNo is repeated per length
      ## class, so deduplicate by haul x species before summing.
      message("Note: LngtCm and Count are both NA - computing HaulN by summing TotalNo per species per haul.")
      key <- paste(as.character(hl$haul.id), as.character(hl$SpecCode), sep = ":")
      hl_dedup <- hl[!duplicated(key), ]
      totals <- tapply(as.numeric(hl_dedup$TotalNo),
                       as.character(hl_dedup$haul.id),
                       sum, na.rm = TRUE)
    }

    haul_n <- as.numeric(totals[hh_ids])
    haul_n[is.na(haul_n)] <- 0  # hauls with no HL records -> 0 catch
    x[["HH"]][["HaulN"]] <- haul_n
    return(x)
  }

  if (!.has_numbers_at_length(x)) {
    x <- add_numbers_at_length(x,
                               cm_breaks = cm_breaks,
                               by = by)
  }

  if (!is.null(length_cuts)) {

    stopifnot(is.numeric(length_cuts))
    stopifnot(length(length_cuts) > 1L)
    stopifnot(all(diff(length_cuts) > 0))

    old_breaks <- attr(x, "cm.breaks")
    x[["HH"]][["HaulN"]] <- .aggregate_length_bins(
      mat = x[["HH"]][["N"]],
      old_breaks = old_breaks,
      new_breaks = length_cuts
    )

  } else {

    x[["HH"]][["HaulN"]] <- rowSums(x[["HH"]][["N"]], na.rm = TRUE)

  }

  x
}




##' Get length measurement accuracy in cm
##'
##' Derives the length measurement resolution, in centimetres, from the
##' `LngtCode` column of the `HL` table in a `DATRASraw` object.
##'
##' The returned value is the coarsest available resolution found in the data.
##' If multiple length accuracies are present, the largest value is returned and
##' a warning is issued. If unknown or missing `LngtCode` values are present,
##' they are ignored when possible and a warning is issued.
##'
##' The mapping from `LngtCode` to centimetres is:
##' \itemize{
##'   \item `"."` = 0.1 cm
##'   \item `"0"` = 0.5 cm
##'   \item `"1"` = 1 cm
##'   \item `"2"` = 2 cm
##'   \item `"5"` = 5 cm
##' }
##'
##' @param x A `DATRASraw` object containing an `HL` table with a `LngtCode`
##'   column.
##'
##' @return A numeric scalar giving the inferred length measurement accuracy in
##'   cm.
##'
##' @details
##' The function returns the maximum recognised length resolution present in
##' `x[["HL"]]$LngtCode`, corresponding to the coarsest measurement accuracy in
##' the data.
##'
##' @examples
##' \dontrun{
##' acc <- get_accuracy_cm(x)
##' }
##'
##' @export
get_accuracy_cm <- function(x) {
  ch <- as.character(x[["HL"]]$LngtCode)
  LngtCode2cm <- c(. = 0.1, `0` = 0.5, `1` = 1, `2` = 2, `5` = 5)
  y <- LngtCode2cm[ch]
  ans <- max(y, na.rm = TRUE)
  if (length(na.omit(unique(y))) > 1)
    warning(paste("Mixed accuracies found in var[[3]]$LngtCode - worst chosen:",
                  ans, "cm"))
  if (any(is.na(unique(y))))
    warning(paste("NAs found in var[[3]]$LngtCode - assumed to be",
                  ans, "cm"))
  ans
}



## Internal functions -------------------------------------------------------------

.default_cm_breaks <- function(x, by = get_accuracy_cm(x)) {
  lngt <- x[["HL"]][["LngtCm"]]
  lngt <- lngt[is.finite(lngt)]

  if (length(lngt) == 0L) {
    stop("No finite length values found in `x[['HL']][['LngtCm']]`.")
  }

  seq(min(lngt), max(lngt) + by, by = by)
}

.has_numbers_at_length <- function(x) {
  !is.null(x[["HH"]][["N"]]) && is.matrix(x[["HH"]][["N"]])
}

.aggregate_length_bins <- function(mat, old_breaks, new_breaks) {
  stopifnot(is.matrix(mat))
  stopifnot(is.numeric(old_breaks), length(old_breaks) >= 2L)
  stopifnot(is.numeric(new_breaks), length(new_breaks) >= 2L)
  stopifnot(all(diff(new_breaks) > 0))

  mids <- old_breaks[-length(old_breaks)] + diff(old_breaks) / 2
  grp <- cut(
    mids,
    breaks = new_breaks,
    right = TRUE,
    include.lowest = TRUE,
    labels = FALSE
  )

  nbins <- length(new_breaks) - 1L
  out <- matrix(0, nrow = nrow(mat), ncol = nbins)
  rownames(out) <- rownames(mat)
  colnames(out) <- paste0(
    "(",
    new_breaks[-length(new_breaks)],
    "-",
    new_breaks[-1],
    "]"
  )

  for (j in seq_len(nbins)) {
    cols_in_bin <- which(grp == j)
    if (length(cols_in_bin) > 0L) {
      out[, j] <- rowSums(mat[, cols_in_bin, drop = FALSE], na.rm = TRUE)
    }
  }

  out
}
