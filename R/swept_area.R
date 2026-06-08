
## Main functions ----------------------------------------------------------------


##' Add swept-area estimates to a `datras_raw` object
##'
##' Compute haul-level swept-area estimates for a `datras_raw` / `DATRASraw`
##' object using one of the supported methods.
##'
##' This function is a wrapper around [add_swept_area_simple()] and
##' [add_swept_area_fishglob()]. It allows users to choose between a simple
##' rule-based approach and the FishGlob workflow.
##'
##' @param x A `datras_raw` object.
##' @param method Character string specifying the method used to calculate swept
##'   area. Must be either `"simple"` (default) or `"fishglob"`.
##' @param min_speed Minimum plausible ground speed. Values below this threshold
##'   are treated as missing. Only used when `method = "simple"`. Defaults to
##'   `1`.
##' @param min_dist Minimum plausible towing distance. Values below this
##'   threshold are treated as missing. Only used when `method = "simple"`.
##'   Defaults to `0`.
##' @param max_dist_dev Maximum relative deviation allowed between recorded
##'   distance and distance reconstructed from `HaulDur` and `GroundSpeed`.
##'   Distances with larger deviations are treated as missing. Only used when
##'   `method = "simple"`. Defaults to `0.2`.
##' @param impute_missing Logical. Passed to [add_swept_area_simple()]. Only used
##'   when `method = "simple"`. Defaults to `FALSE`.
##' @param width Character string specifying which spread column to use as trawl
##'   width. Must be either `"WingSpread"` (default) or `"DoorSpread"`. Only
##'   used when `method = "simple"`; ignored for `method = "fishglob"`.
##'
##' @details
##' If `method = "simple"`, swept area is calculated using
##' [add_swept_area_simple()], which applies basic plausibility filters,
##' gear-specific median imputations, and a direct distance-times-width
##' calculation.
##'
##' If `method = "fishglob"`, swept area is calculated using
##' [add_swept_area_fishglob()], which follows the FishGlob workflow based on
##' survey-specific spread models and hierarchical fallback rules.
##'
##' @return A `datras_raw` object with swept-area estimates added.
##'
##' @seealso [add_swept_area_simple()], [add_swept_area_fishglob()]
##'
##' @examples
##' \dontrun{
##' ## Simple swept-area estimation
##' x <- add_swept_area(x)
##'
##' ## FishGlob workflow
##' x <- add_swept_area(x, method = "fishglob")
##'
##' ## Simple method with stricter filters
##' x <- add_swept_area(x, method = "simple", min_speed = 2,
##'                     max_dist_dev = 0.1)
##' }
##'
##' @export
add_swept_area <- function(x,
                           method = "simple",
                           min_speed = 1,
                           min_dist = 0,
                           max_dist_dev = 0.2,
                           impute_missing = FALSE,
                           width = "WingSpread") {

  .check_class_datras(x)

  if (method == "simple") {

    x <- add_swept_area_simple(x,
                               min_speed = min_speed,
                               min_dist = min_dist,
                               max_dist_dev = max_dist_dev,
                               impute_missing = impute_missing,
                               width = width)

  } else if (method == "fishglob") {

    if (!missing(width) && width != "WingSpread")
      message("The 'width' argument is ignored when method = \"fishglob\".")
    x <- add_swept_area_fishglob(x)

  } else stop("Unknown method. Use 'simple' or 'fishglob'.")

  return(x)
}




##' Add simple swept-area estimates to a `datras_raw` object
##'
##' Compute haul-level swept-area estimates from towing distance and trawl width
##' using a simple rule-based approach.
##'
##' The function uses recorded `WingSpread` where available, applies a series of
##' basic plausibility filters and gear-specific corrections, imputes missing
##' values from gear-level medians, reconstructs towing distance when needed
##' from `HaulDur` and `GroundSpeed`, and returns two swept-area estimates.
##'
##' @param x A `datras_raw` object.
##' @param min_speed Minimum plausible ground speed. Values below this threshold
##'   are treated as missing. Defaults to `1`.
##' @param min_dist Minimum plausible towing distance. Values below this
##'   threshold are treated as missing. Defaults to `0`.
##' @param max_dist_dev Maximum relative deviation allowed between recorded
##'   distance and distance reconstructed from `HaulDur` and `GroundSpeed`.
##'   Distances with larger deviations are treated as missing. Defaults to `0.2`.
##' @param impute_missing Logical. Currently included for compatibility, but not
##'   used explicitly in the present implementation.
##' @param width Character string specifying which spread column to use as trawl
##'   width. Must be either `"WingSpread"` (default) or `"DoorSpread"`. Use
##'   `"DoorSpread"` for surveys that record door spread but not wing spread.
##'   Note that the fixed beam-trawl widths and the gear-specific plausibility
##'   bounds are only applied when `width = "WingSpread"`.
##'
##' @details
##' Swept area is calculated in \eqn{m^2} as:
##' \deqn{
##'   SweptArea = Spread \times Distance
##' }
##' where \eqn{Spread} is taken from the column selected by `width`.
##'
##' A second estimate, `SweptArea.median`, is also returned. This uses a
##' gear-specific median spread rather than the haul-specific recorded or
##' imputed spread:
##' \deqn{
##'   SweptArea.median = Spread.median \times Distance
##' }
##'
##' The function applies the following steps:
##' \itemize{
##'   \item removes implausible values of `GroundSpeed`, `Distance`, and the
##'   selected spread column,
##'   \item removes distance values that differ too much from reconstructed
##'   distance based on speed and haul duration,
##'   \item when `width = "WingSpread"`: applies fixed widths for selected beam
##'   trawl gear codes and accounts for double-beam trawls via `GearEx == "DB"`,
##'   \item imputes missing spread values using gear-specific medians,
##'   \item imputes missing ground speed using gear-specific medians,
##'   \item reconstructs missing towing distance from haul duration and ground
##'   speed.
##' }
##'
##' @return A `datras_raw` object with two additional swept-area fields:
##' \itemize{
##'   \item `SweptArea`: swept area based on haul-specific spread,
##'   \item `SweptArea.median`: swept area based on gear-specific median spread.
##' }
##'
##' @seealso [add_swept_area_fishglob()]
##'
##' @examples
##' \dontrun{
##' x <- add_swept_area_simple(x)
##'
##' ## Use stricter plausibility filtering
##' x <- add_swept_area_simple(x, min_speed = 2, max_dist_dev = 0.1)
##' }
##'
##' @export
add_swept_area_simple <- function(x,
                                  min_speed = 1,
                                  min_dist = 0,
                                  max_dist_dev = 0.2,
                                  impute_missing = FALSE,
                                  width = "WingSpread") {

  .check_class_datras(x)

  width <- match.arg(width, c("WingSpread", "DoorSpread"))

  if (!width %in% names(x[["HH"]]))
    stop("Column '", width, "' not found in x[['HH']]. ",
         "Check names(x[['HH']]) to see available columns.")

  x$GroundSpeed[ x$GroundSpeed < min_speed ] <- NA
  x$Distance[ x$Distance < min_dist ] <- NA
  x[["HH"]][[width]][ x[["HH"]][[width]] <= 0 ] <- NA

  if (width == "WingSpread") {
    x$WingSpread[ x$Gear == "GOV" & ( x$WingSpread < 5 | x$WingSpread > 40 ) ] <- NA
  }

  ## Remove some distance outliers
  Distance2 <- (x$HaulDur / 60 * 1852 * x$GroundSpeed)
  badDist <- abs((x$Distance - Distance2)/x$Distance) > max_dist_dev
  x$Distance[ badDist ] <- NA

  if (width == "WingSpread") {
    ## Beam trawl "wing spreads"
    x$WingSpread[x$Gear == "BT12"]   <- 12
    x$WingSpread[x$Gear == "BT8"]    <- 8
    x$WingSpread[x$Gear == "BT4A"]   <- 4
    x$WingSpread[x$Gear == "BT7"]    <- 7
    x$WingSpread[x$Gear == "BT4AI"]  <- 4
    x$WingSpread[x$Gear == "BT4S"]   <- 4
    x$WingSpread[x$Gear == "BT4P"]   <- 4
    x$WingSpread[x$Gear == "BT6"]    <- 6
    x$WingSpread[x$Gear == "BT3"]    <- 3

    ## For Beam trawls, GearEx == "DB" means double beam, i.e. catches from two beam trawls added.
    x$BeamWidth[ !is.na(x$GearEx) & x$GearEx=="DB" ] <- x$BeamWidth[ !is.na(x$GearEx) & x$GearEx=="DB" ]*2
  }

  ## Impute missing spread values (median within gear)
  x2 <- x[["HH"]]
  if (sum(!is.na(x2[[width]])) > 0) {
    wtab <- aggregate(x2[[width]], list(Gear = x2$Gear), FUN = median, na.rm = TRUE)
    names(wtab)[2] <- width
    for (i in 1:nrow(wtab)) {
      sel <- which(x$Gear == wtab$Gear[i] & is.na(x[["HH"]][[width]]))
      x[["HH"]][[width]][ sel ] <- wtab[[width]][i]
    }
    if (width == "WingSpread") x$WingSpread2 <- NULL
  } else {
    stop("All ", width, " values are NA. Cannot calculate swept area, ",
         "please check x[['HH']]$", width, ".")
  }

  ## Gear-level median spread (more robust against recording errors)
  spread_med <- paste0(width, ".median")
  x[["HH"]][[spread_med]] <- x[["HH"]][[width]]
  for (i in 1:nrow(wtab)) {
    sel <- which(x$Gear == wtab$Gear[i])
    x[["HH"]][[spread_med]][ sel ] <- wtab[[width]][i]
  }

  ## Impute missing ground speeds
  x2 <- x[["HH"]]
  stab <- aggregate(GroundSpeed~Gear,data=x2,FUN=median,na.rm=TRUE)
  for(i in 1:nrow(stab)){
    if(!is.na(stab$GroundSpeed[i])){
      x$GroundSpeed[ is.na(x$GroundSpeed) & x$Gear==stab$Gear[i]  ] <- stab$GroundSpeed[i]
    }
  }
  for(i in 1:nrow(stab)){
    sel <- which(x$Gear==stab$Gear[i] & is.na(x$GroundSpeed))
    x$GroundSpeed[ sel ] <- stab$GroundSpeed[i]
  }

  ## Impute missing distances
  noDist <- which( is.na(x$Distance) )
  x$Distance[ noDist ] <- (x$HaulDur[noDist] / 60 * 1852 * x$GroundSpeed[noDist])

  x$SweptArea <- x[["HH"]][[width]] * x$Distance
  x$SweptArea.median <- x[["HH"]][[spread_med]] * x$Distance

  return(x)
}
