
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
##'   DATRAS internal function `getAccuracyCM()`.
##' @param length_percentile Numeric percentile used to summarize the upper tail
##'   of the observed length distribution. Defaults to `99.9999`.
##' @param plot Logical. If `TRUE` (default), plot the length spectrum on raw and
##'   log count scales.
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
##' @return A list with three elements:
##' \itemize{
##'   \item `N`: a haul-by-length count matrix,
##'   \item `lPars`: a data frame of summary statistics for the length
##'   distribution,
##'   \item `nAbove`: a data frame with the number and percentage of observations
##'   above selected upper-length thresholds.
##' }
##'
##' @seealso [check_weight()]
##'
##' @examples
##' \dontrun{
##' res <- check_length(x)
##'
##' ## Use custom length bins
##' res <- check_length(x, cm_breaks = seq(0, 100, by = 1))
##'
##' ## Use an automatically generated spectrum with 0.5 cm bins
##' res <- check_length(x, by = 0.5)
##' }
##'
##' @export
check_length <- function(x,
                         cm_breaks = seq(min(x[["HL"]]$LngtCm, na.rm = TRUE),
                                         max(x[["HL"]]$LngtCm, na.rm = TRUE) + by,
                                         by = by),
                         by = NULL,
                         length_percentile = 99.9999,
                         plot = TRUE) {

  .check_class(x)

  ## import internal function from DATRAS
  getAccuracyCM <- getFromNamespace("getAccuracyCM", "DATRAS")

  if (is.null(by))
    by <- getAccuracyCM(x)

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
