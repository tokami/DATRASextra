
## Main functions ----------------------------------------------------------------

##' Clean a `datras_raw` object following the FishGlob workflow
##'
##' Apply the main cleaning steps used in the FishGlob data workflow to a
##' `datras_raw` / `DATRASraw` object.
##'
##' This function follows the ICES DATRAS cleaning workflow used to construct the
##' FishGlob data set, including filtering of valid hauls and species records,
##' selected survey renaming, removal of hauls affected by incomplete bycatch
##' recording, and species harmonization.
##'
##' @param x A `datras_raw` object.
##'
##' @details
##' The cleaning steps are adapted from the FishGlob data-processing workflow
##' described in Maureaud et al. (2021) and the associated code repository.
##'
##' The function currently performs the following operations:
##' \itemize{
##'   \item retains only valid hauls (`HaulVal == "V"`),
##'   \item removes records with missing `Valid_Aphia`,
##'   \item keeps only selected `SpecVal` codes,
##'   \item keeps only selected `DataType` codes,
##'   \item renames selected surveys to match FishGlob conventions,
##'   \item removes hauls affected by incomplete bycatch recording for selected
##'   surveys,
##'   \item harmonizes species names and taxonomic identifiers using
##'   [correct_species()].
##' }
##'
##' Survey renaming currently includes:
##' \itemize{
##'   \item `"SCOWCGFS"` to `"SWC-IBTS"`
##'   \item `"SCOROC"` to `"ROCKALL"`
##' }
##'
##' The treatment of bycatch-recording codes follows the FishGlob workflow for
##' the `NS-IBTS` and `BITS` surveys.
##'
##' @return A cleaned `datras_raw` object following the FishGlob workflow.
##'
##' @references
##' Maureaud, A., Frelat, R., Pécuchet, L., Shackell, N., Mérigot, B.,
##' Pinsky, M. L., Amador, K., Anderson, S. C., Arkhipkin, A., Auber, A.,
##' Barri, I., et al. (2021). Are we ready to track climate-driven shifts in
##' marine species across international boundaries? A global survey of
##' scientific bottom trawl data. \emph{Global Change Biology}, 27(2), 220--236.
##'
##' FishGlob workflow code:
##' \url{https://github.com/fishglob/FishGlob_data/tree/main/cleaning_codes}
##'
##' @seealso [clean_datras()], [correct_species()]
##'
##' @examples
##' \dontrun{
##' x_clean <- clean_fishglob(x)
##' }
##'
##' @export
clean_fishglob <- function(x) {

  .check_class_datras(x)

  ## General cleaning -------------------------
  ## https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R#L347
  x <- subset(
    x,
    HaulVal %in% "V", ## HaulVal (https://vocab.ices.dk/?ref=1)
    !is.na(Valid_Aphia), ## AphiaID in fishglob
    SpecVal %in% c(1, 10, 4, 5, 6, 7, 8),
    DataType %in% c("S", "R", "C")
    ## StdSpecRecCode == 1 ## L382  ## Line reference not correct for get_datras? where is this coming from?
  )


  ## Rename surveys ---------------------------
  ## https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R#L380
  ## SCOWCGFS -> SWC-IBTS
  x <- .rename_survey(x, "SCOWCGFS", "SWC-IBTS")
  ## SCOROC -> ROCKALL
  x <- .rename_survey(x, "SCOROC", "ROCKALL")


  ## Account for by catch sampling ------------
  ## Remove hauls were not all species were recorded
  ## https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R#L382
  x[["HH"]] <- x[["HH"]][!(x[["HH"]]$Survey == "NS-IBTS" &
                             x[["HH"]]$BySpecRecCode %in% c(0, 2, 3, 4, 5)) &
                           !(x[["HH"]]$Survey == "BITS" &
                               x[["HH"]]$BySpecRecCode == 0),]


  ## Species correction -----------------------
  ## https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/get_datras.R#L432
  x <- correct_species(x)

  return(x)
}



##' Prune a `datras_raw` object following the FishGlob workflow
##'
##' Reduce a `datras_raw` / `DATRASraw` object to the components and columns
##' needed for the FishGlob workflow.
##'
##' This function removes the `CA` table entirely and retains only a selected
##' subset of columns in the `HH` and `HL` tables. It is mainly intended to
##' reduce memory use when preparing data in a format consistent with the
##' FishGlob data workflow.
##'
##' @param x A `datras_raw` object.
##'
##' @details
##' The FishGlob workflow does not require the full DATRAS object. In particular,
##' the `CA` table is discarded and only a reduced set of variables is kept from
##' the `HH` and `HL` tables.
##'
##' This can substantially reduce memory use when working with large survey data
##' sets.
##'
##' @return A pruned `datras_raw` object following the FishGlob workflow.
##'
##' @seealso [prune_datras()], [clean_fishglob()]
##'
##' @examples
##' \dontrun{
##' x_small <- prune_fishglob(x)
##' }
##'
##' @export
prune_fishglob <- function(x) {

  .check_class_datras(x)

  hh.cols <- c("RecordType","Country","Survey","Quarter", "Ship","Gear",
               "Year","Month", "Day","HaulDur","StatRec","Depth", "HaulVal",
               "StdSpecRecCode","DataType", "Distance","DoorSpread",
               "WingSpread","GroundSpeed","SweepLngt", "haul.id", "lon","lat")

  hl.cols <- c("haul.id","RecordType","Country", "Survey","Quarter","Ship",
               "Gear", "Year","SpecVal","Sex","TotalNo", "SweepLngt",
               "SubFactor","SubWgt","CatCatchWgt","LngtCode", "LngtClas",
               "HLNoAtLngt", "Valid_Aphia","ScientificName_WoRMS","LngtCm",
               "Species", "HaulDur","DataType","Count")

  x["CA"] <- list(NULL)
  x["HH"] <- list(x[["HH"]][colnames(x[["HH"]]) %in% hh.cols])
  x["HL"] <- list(x[["HL"]][colnames(x[["HL"]]) %in% hl.cols])

  return(x)
}


##' Add swept-area estimates following the FishGlob workflow
##'
##' Compute haul-level swept-area estimates for a `datras_raw` / `DATRASraw`
##' object using the FishGlob methodology.
##'
##' The function adds haul-level swept area (`SweptArea`) and door-swept area
##' (`DoorsArea`) to the `HH` table. Missing `WingSpread`, `DoorSpread`, and
##' `Distance` values are reconstructed using survey-specific prediction models
##' and hierarchical fallback rules.
##'
##' @param x A `datras_raw` object containing haul-level data in `HH`.
##'
##' @details
##' The implementation follows the methodology used in the FishGlob workflow.
##' Missing `WingSpread` and `DoorSpread` values are predicted from internally
##' stored survey-specific models. When observed values are missing or judged
##' implausible, the function applies survey-specific corrections and fallback
##' prediction rules.
##'
##' Missing towing distance is reconstructed from `GroundSpeed` and `HaulDur`.
##' Missing `GroundSpeed` values are imputed hierarchically using averages at
##' the following levels:
##' \itemize{
##'   \item survey-year-ship,
##'   \item survey-year-country,
##'   \item survey-country,
##'   \item global mean.
##' }
##'
##' Swept area is then computed as:
##' \deqn{
##'   SweptArea = Distance \times WingSpread \times 10^{-6}
##' }
##'
##' Door-swept area is computed analogously as:
##' \deqn{
##'   DoorsArea = Distance \times DoorSpread \times 10^{-6}
##' }
##'
##' Both quantities are returned in \eqn{km^2}, assuming `Distance`,
##' `WingSpread`, and `DoorSpread` are recorded in metres.
##'
##' Some survey- and gear-specific filtering and manual corrections are applied
##' to match the FishGlob workflow.
##'
##' The original spread-estimation logic was developed by Aurore Maureaud and
##' P. Daniël van Denderen and is available from the FishGlob code repository.
##'
##' @return A `datras_raw` object with two additional columns in `HH`:
##' \itemize{
##'   \item `SweptArea`: swept area in \eqn{km^2},
##'   \item `DoorsArea`: door-swept area in \eqn{km^2}.
##' }
##'
##' @references
##' FishGlob workflow code:
##' \url{https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R}
##'
##' @seealso [add_swept_area_simple()], [clean_fishglob()]
##'
##' @examples
##' \dontrun{
##' x <- add_swept_area_fishglob(x)
##' }
##'
##' @export
add_swept_area_fishglob <- function(x) {

  # data cleaning -----------------------------------------------------------
  x[['HH']]$WingSpread[x[['HH']]$WingSpread == 0] <- NA
  x[['HH']]$DoorSpread[x[['HH']]$DoorSpread == 0] <- NA
  x[['HH']]$Distance[x[['HH']]$Distance == 0] <- NA

  x <- subset(
    x,
    !(Survey == "NS-IBTS" &
        Gear %in% c('ABD','BOT','DHT','FOT','GRT',
                    'H18','HOB','HT','KAB','VIN')),
    !(Survey == "BITS" &
        Gear %in% c('CAM','CHP','DT','EGY','ESB',
                    'EXP','FOT','GRT','H20','HAK',
                    'LBT','SON')),
    !(Survey == "PT-IBTS" & Gear == "CAR")
  ) # check why these has been removed

  surveys <- intersect(unique(x[["HH"]]$Survey),
                       names(spread_models))

  area2.list <- vector("list", length(surveys))

  # survey loop -------------------------------------------------------------

  for(i in seq_along(surveys)){

    surv <- subset(x[["HH"]], Survey == surveys[i])
    surv <- droplevels(surv)

    # manual corrections

    if(surveys[i] == "BITS"){
      surv$DoorSpread[surv$DoorSpread > 200] <- NA
    }

    if(surveys[i] == "EVHOE"){
      surv$WingSpread[!(surv$Year %in% 2016:2018)] <- NA
    }

    if(surveys[i] == "FR-CGFS"){
      surv$WingSpread[surv$WingSpread == 10] <- NA
    }

    if(surveys[i] == "NS-IBTS"){
      surv$WingSpread[surv$WingSpread == 50] <- NA
    }

    if(surveys[i] == "SWC-IBTS"){
      surv$SweepLngt <- as.numeric(surv$SweepLngt)
      surv$SweepLngt[is.na(surv$SweepLngt)] <- 60
    }

    if(surveys[i] == "PT-IBTS"){
      surv$WingSpread[surv$WingSpread > 20] <- NA
      surv$cat <- ifelse(surv$Depth > 120, "deep", "shallow")
    }

    if (surveys[i] %in% c("EVHOE","IE-IGFS")) {
      surv$SweepLngtCat <- ifelse(surv$SweepLngt <= 60,
                                  "short","long")
    }
    
    surv <- .clean_haul_metrics(surv)

    # model predictions
    model_set <- spread_models[[surveys[i]]]

    # ---- DoorSpread ----
    missing_door <- is.na(surv$DoorSpread)
    if (any(missing_door)) {
      newdata <- surv[missing_door, , drop = FALSE]
      preds <- .safe_predict_hierarchy(newdata, model_set, "door")
      surv$DoorSpread[missing_door] <- preds
    }

    # ---- WingSpread ----
    missing_wing <- is.na(surv$WingSpread)
    if (any(missing_wing)) {
      newdata <- surv[missing_wing, , drop = FALSE]
      preds <- .safe_predict_hierarchy(newdata, model_set, "wing")
      surv$WingSpread[missing_wing] <- preds
    }

    # PT fallback
    if (surveys[i] == "PT-IBTS" &&
          all(is.na(surv$DoorSpread))) {
      surv$DoorSpread <- surv$WingSpread / 0.3
    }

    area2.list[[i]] <- .combine_survey(surv)
  }

  # -------------------------------------------------
  # Merge spreads
  # -------------------------------------------------

  area2 <- unique(do.call(rbind, area2.list))

  x[["HH"]] <- merge(x[["HH"]], area2,
                     by = "haul.id", all.x = TRUE)

  x$DoorSpread <- ifelse(is.na(x$DoorSpread),
                         x$DoorSpread2,
                         x$DoorSpread)

  x$WingSpread <- ifelse(is.na(x$WingSpread),
                         x$WingSpread2,
                         x$WingSpread)

  x$DoorSpread2 <- NULL
  x$WingSpread2 <- NULL

  # -------------------------------------------------
  # Distance + hrearchical speed fallback
  # -------------------------------------------------
  dist <- unique(x[["HH"]][, c("haul.id","Survey","Year",
                               "Ship","Country","Distance",
                               "GroundSpeed","HaulDur")])

  dist$Distance[dist$Distance <= 0 | dist$Distance > 11000] <- NA
  x$Distance[x$Distance > 11000] <- NA
  dist$GroundSpeed[dist$GroundSpeed <= 0 | dist$GroundSpeed > 30] <- NA

  # hierarchical speed imputation --------------------------------------------------------
  # 1) Survey-Year-Ship
  avgspeed <- aggregate(GroundSpeed ~ Survey + Year + Ship,
                        data = dist, mean, na.rm = TRUE)
  names(avgspeed)[4] <- "Speed2"
  dist <- merge(dist, avgspeed,
                by = c("Survey","Year","Ship"), all.x = TRUE)
  dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                             dist$Speed2,
                             dist$GroundSpeed)
  dist$Speed2 <- NULL

  # 2) Survey-Year-Country
  avgspeed <- aggregate(GroundSpeed ~ Survey + Year + Country,
                        data = dist, mean, na.rm = TRUE)
  names(avgspeed)[4] <- "Speed2"
  dist <- merge(dist, avgspeed,
                by = c("Survey","Year","Country"), all.x = TRUE)
  dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                             dist$Speed2,
                             dist$GroundSpeed)
  dist$Speed2 <- NULL

  # 3) Survey-Country
  avgspeed <- aggregate(GroundSpeed ~ Survey + Country,
                        data = dist, mean, na.rm = TRUE)
  names(avgspeed)[3] <- "Speed2"
  dist <- merge(dist, avgspeed,
                by = c("Survey","Country"), all.x = TRUE)
  dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                             dist$Speed2,
                             dist$GroundSpeed)
  dist$Speed2 <- NULL

  # 4) Global
  dist$GroundSpeed[is.na(dist$GroundSpeed)] <-
    mean(dist$GroundSpeed, na.rm = TRUE)

  # recalculate distance
  dist$Distance2 <- dist$GroundSpeed * 1.852 *
    dist$HaulDur / 60 * 1000

  dist$Distance <- ifelse(is.na(dist$Distance),
                          dist$Distance2,
                          dist$Distance)

  dist <- dist[, c("haul.id","Distance")]

  x[["HH"]] <- merge(x[["HH"]], dist,
                     by = "haul.id",
                     all.x = TRUE,
                     suffixes = c("", "_pred"))

  x[["HH"]]$Distance <- ifelse(
    is.na(x[["HH"]]$Distance),
    x[["HH"]]$Distance_pred,
    x[["HH"]]$Distance
  )

  x[["HH"]]$Distance_pred <- NULL

  # -------------------------------------------------
  # Swept area calculation
  # -------------------------------------------------
  x[["HH"]]$SweptArea <-
    x[["HH"]]$Distance * 0.001 *
    x[["HH"]]$WingSpread * 0.001

  x[["HH"]]$DoorsArea <-
    x[["HH"]]$Distance * 0.001 *
    x[["HH"]]$DoorSpread * 0.001

  return(x)
}



##' Add weight estimates to `HL` records following the FishGlob workflow
##'
##' Calculate weight-at-length using empirical length-weight parameters and add
##' the resulting weight fields to the `HL` table of a `datras_raw` /
##' `DATRASraw` object.
##'
##' The function merges the `HL` table with internal species information to
##' obtain empirical length-weight parameters (`aFG` and `bFG`), computes
##' individual weight from length, and then calculates total weight for each
##' length class record.
##'
##' @param x A `datras_raw` object containing `HL` and `HH` tables.
##'
##' @details
##' Weight-at-length is calculated for each `HL` record as:
##' \deqn{
##'   Wgt\_indiv = aFG \times LngtCm^{bFG}
##' }
##'
##' where `LngtCm` is fish length in centimetres and `aFG` and `bFG` are
##' empirical species-specific length-weight parameters obtained from the
##' internal `species_info` data.
##'
##' Total weight per record is then calculated as:
##' \deqn{
##'   Wgt\_total = Wgt\_indiv \times Count
##' }
##'
##' Individual weight is first computed in grams and total weight is returned in
##' kilograms.
##'
##' Only species belonging to the classes `Teleostei`, `Elasmobranchii`,
##' `Petromyzonti`, and `Myxini` are retained in the join with `species_info`.
##'
##' A warning is issued if species are present in the joined data but have
##' missing length-weight parameters.
##'
##' @return A `datras_raw` object with the `HL` table updated to include the
##'   additional columns:
##' \itemize{
##'   \item `Wgt_indiv`: estimated individual weight in grams,
##'   \item `Wgt_total`: estimated total weight for the record in kilograms.
##' }
##'
##' @seealso [add_total_weight_by_haul()]
##'
##' @examples
##' \dontrun{
##' x <- add_total_weight_by_haul_fishglob(x)
##' }
##'
##' @export
add_total_weight_by_haul_fishglob <- function(x) {


  ## --- input checks ---
  .check_class_datras(x)
  if (!all(c("HL","HH") %in% names(x))) stop("datras_raw object must contain HL and HH tables")

  hl <- x[["HL"]]
  hh <- x[["HH"]]

  ## convert factors to character
  hl[] <- lapply(hl, function(z) if (is.factor(z)) as.character(z) else z)

  ## check required columns
  req_cols <- c("Valid_Aphia","Species","HLNoAtLngt","LngtCm")
  missing_cols <- req_cols[!req_cols %in% names(hl)]
  if (length(missing_cols) > 0) stop("missing required HL columns: ", paste(missing_cols, collapse=", "))

  ## load species info
  data(species_info, envir = environment())

  ## merge with species info to get a and b parameters
  hl2 <- merge(
    hl,
    species_info[species_info$class %in% c("Teleostei","Elasmobranchii","Petromyzonti","Myxini"), ],
    by.x = c("Valid_Aphia","Species"),
    by.y = c("WoRMS_AphiaID","ScientificName_WoRMS"),
    all.x = FALSE
  )

  ## warning if a/b missing
  if (any(is.na(hl2$aFG)) || any(is.na(hl2$bFG))) {
    missing <- unique(hl2$Valid_Aphia[is.na(hl2$aFG) | is.na(hl2$bFG)])
    warning("some species missing a/b parameters in species_info: ", paste(missing, collapse=", "))
  }

  ## calculate weights
  hl2$Wgt_indiv <- with(hl2, aFG * (LngtCm ^ bFG))  # grams per individual
  hl2$Wgt_total <- hl2$Wgt_indiv * hl2$Count   # grams per length class group

  ## convert to kg
  hl2$Wgt_total <- hl2$Wgt_total / 1000             # kg

  ## update hl table in datras_raw object
  x[["HL"]] <- hl2

  return(x)
}



##' Convert a `datras_raw` object to FishGlob format
##'
##' Convert a `datras_raw` / `DATRASraw` object into a data frame structured to
##' match the FishGlob data set format.
##'
##' The function aggregates length-based catch information in `HL` to the
##' haul-species level, merges the result with haul-level metadata from `HH`,
##' computes abundance and biomass standardization metrics, and renames selected
##' fields to match FishGlob naming conventions.
##'
##' @param x A `datras_raw` object containing `HH` and `HL` tables.
##'
##' @details
##' The function first aggregates `HL` records by haul and taxon using:
##' \itemize{
##'   \item total weight (`wgt`), calculated as the sum of `Wgt_total`,
##'   \item total number (`num`), calculated as the sum of `Count`.
##' }
##'
##' These aggregated values are merged with the `HH` table and used to compute:
##' \itemize{
##'   \item `wgt_cpue`: biomass per hour trawled,
##'   \item `wgt_cpua`: biomass per swept area,
##'   \item `num_cpue`: abundance per hour trawled,
##'   \item `num_cpua`: abundance per swept area.
##' }
##'
##' Haul duration is converted from minutes to hours before calculating CPUE
##' metrics.
##'
##' The returned data frame follows FishGlob naming conventions where possible,
##' including fields such as `survey`, `haul_id`, `latitude`, `longitude`,
##' `accepted_name`, and `aphia_id`.
##'
##' Some output fields are created as placeholders with missing values when the
##' corresponding information is not available in the input data.
##'
##' Country and survey-unit fields are assigned using survey-specific rules that
##' approximate the FishGlob workflow.
##'
##' @return A data frame in FishGlob-like format, with one row per
##'   haul-taxon combination.
##'
##' @seealso [clean_fishglob()], [prune_fishglob()], [add_swept_area_fishglob()],
##'   [add_total_weight_by_haul_fishglob()]
##'
##' @examples
##' \dontrun{
##' fg <- as_fishglob(x)
##' }
##'
##' @importFrom stats aggregate
##'
##' @export
as_fishglob <- function(x) {

  .check_class_datras(x)

  # extract hh and hl
  hh <- x[["HH"]]
  hl <- x[["HL"]]

  # select grouping variables for aggregation
  groups <- hl[, c(
    "Survey","Quarter","Year","haul.id","Valid_Aphia",
    "Species","genus","family","order","class","rank"
  )]

  # aggregate wgt and num
  hl2 <- aggregate(
    cbind(wgt = hl$Wgt_total, num = hl$Count),
    by = groups,
    FUN = function(z) sum(z, na.rm = TRUE)
  )

  # merge back to hh (left join)
  hh2 <- merge(
    hh, hl2,
    by = intersect(names(hh), names(hl2)),
    all.x = TRUE
  )

  # remove rows without catch
  hh2 <- hh2[!is.na(hh2$wgt) & !is.na(hh2$num), ]

  # convert haul duration minutes → hours
  hh2$haul_dur_h <- hh2$HaulDur / 60

  # cpue and cpua
  hh2$wgt_cpue <- hh2$wgt / hh2$haul_dur_h
  hh2$wgt_cpua <- hh2$wgt / hh2$SweptArea
  hh2$num_cpue <- hh2$num / hh2$haul_dur_h
  hh2$num_cpua <- hh2$num / hh2$SweptArea

  # rename columns
  names(hh2)[names(hh2) == "Survey"]      <- "survey"
  names(hh2)[names(hh2) == "haul.id"]     <- "haul_id"
  names(hh2)[names(hh2) == "StatRec"]     <- "stat_rec"
  names(hh2)[names(hh2) == "Year"]        <- "year"
  names(hh2)[names(hh2) == "Month"]       <- "month"
  names(hh2)[names(hh2) == "Day"]         <- "day"
  names(hh2)[names(hh2) == "Quarter"]     <- "quarter"
  names(hh2)[names(hh2) == "lat"]         <- "latitude"
  names(hh2)[names(hh2) == "lon"]         <- "longitude"
  names(hh2)[names(hh2) == "HaulDur"]     <- "haul_dur"
  names(hh2)[names(hh2) == "Depth"]       <- "depth"
  names(hh2)[names(hh2) == "Gear"]        <- "gear"
  names(hh2)[names(hh2) == "Valid_Aphia"] <- "aphia_id"

  # scientificname_worms kept for accepted_name
  hh2$accepted_name <- hh2$Species

  # new empty fields
  hh2$verbatim_aphia_id <- NA_integer_
  hh2$verbatim_name     <- NA_character_
  hh2$station           <- NA_character_
  hh2$stratum           <- NA_character_
  hh2$sub_area          <- NA_character_
  hh2$continent         <- "europe"

  # country classification
  hh2$country <- NA_character_
  hh2$country[hh2$survey == "PT-IBTS"] <- "portugal"
  hh2$country[hh2$survey == "EVHOE"]   <- "france"
  hh2$country[hh2$survey == "IE-IGFS"] <- "ireland"
  hh2$country[hh2$survey %in% c("ROCKALL","SWC-IBTS","NIGFS")] <- "uk"
  hh2$country[hh2$survey == "FR-CGFS"] <- "france"
  hh2$country[hh2$survey %in% c("NS-IBTS","BITS")] <- "multi-countries"
  hh2$country[hh2$survey %in% c("SP-NORTH","SP-ARSA")] <- "spain"
  hh2$country[hh2$survey == "SP-PORC"] <- "multi-countries"

  # convert haul duration minutes → hours (final field)
  hh2$haul_dur <- hh2$haul_dur_h

  # metadata
  hh2$source    <- "DATRAS ICES"
  hh2$timestamp <- format(as.Date(Sys.time(), tz="UTC"), "%Y-%m")

  # survey units
  hh2$survey_unit <- hh2$survey
  hh2$survey_unit <- as.character(hh2$survey_unit)
  idx <- hh2$survey %in% c("BITS","NS-IBTS","SWC-IBTS","SP-ARSA")
  hh2$survey_unit[idx] <- paste0(hh2$survey[idx], "-", hh2$quarter[idx])

  idx2 <- hh2$survey %in% c("NEUS","SEUS","SCS","GMEX")
  hh2$survey_unit[idx2] <- paste0(hh2$survey[idx2], "-", hh2$season[idx2])

  final_cols <- c(
    "survey",
    "source",
    "timestamp",
    "haul_id",
    "country",
    "sub_area",
    "continent",
    "stat_rec",
    "station",
    "stratum",
    "year",
    "month",
    "day",
    "quarter",
    "season",
    "latitude",
    "longitude",
    "haul_dur",
    "area_swept",
    "gear",
    "depth",
    "sbt",
    "sst",
    "num",
    "num_cpue",
    "num_cpua",
    "wgt",
    "wgt_cpue",
    "wgt_cpua",
    "verbatim_name",
    "verbatim_aphia_id",
    "accepted_name",
    "aphia_id",
    "SpecCode",
    "kingdom",
    "phylum",
    "class",
    "order",
    "family",
    "genus",
    "rank",
    "survey_unit"
  )

  hh2 <- hh2[, intersect(final_cols, names(hh2)), drop = FALSE]

  return(hh2)
}





## Internal functions -----------------------------------------------------------

.safe_predict_hierarchy <- function(newdata, model_set, prefix) {

  models <- list(
    model_set[[paste0(prefix, "_primary")]],
    model_set[[paste0(prefix, "_fallback1")]],
    model_set[[paste0(prefix, "_fallback2")]]
  )

  models <- models[!sapply(models, is.null)]

  preds <- rep(NA_real_, nrow(newdata))
  remaining <- seq_len(nrow(newdata))

  for (m in models) {

    if (length(remaining) == 0) break

    dat <- newdata[remaining, , drop = FALSE]
    ok <- rep(TRUE, nrow(dat))

    if (!is.null(m$xlevels)) {
      for (var in names(m$xlevels)) {
        if (var %in% names(dat)) {
          ok <- ok & dat[[var]] %in% m$xlevels[[var]]
        }
      }
    }

    if (any(ok)) {
      idx_ok <- remaining[ok]
      preds[idx_ok] <- predict(m, newdata[idx_ok, , drop = FALSE])
      remaining <- setdiff(remaining, idx_ok)
    }
  }

  return(preds)
}


.combine_survey <- function(surv){
  surv <- surv[, c("haul.id","DoorSpread","WingSpread")]
  names(surv)[names(surv) == "DoorSpread"] <- "DoorSpread2"
  names(surv)[names(surv) == "WingSpread"] <- "WingSpread2"
  surv
}


.rename_survey <- function(x, survNameOld, survNameNew) {
  for (i in c("HH","HL","CA")) {
    if (!any(names(x) == i)) next()
    if (survNameOld %in% levels(x[[i]]$Survey)) {
      levels(x[[i]]$Survey)[levels(x[[i]]$Survey) == survNameOld] <- survNameNew
      x[[i]]$haul.id <- factor(
        gsub(survNameOld, survNameNew, x[[i]]$haul.id)
      )
    }
  }
  return(x)
}

.clean_haul_metrics <- function(surv) {
  
  # -----------------------
  # Hard limits
  # -----------------------
  surv$DoorSpread[surv$DoorSpread <= 0 | surv$DoorSpread > 300] <- NA
  surv$WingSpread[surv$WingSpread <= 0 | surv$WingSpread > 100] <- NA
  
  surv$Distance[surv$Distance <= 0 | surv$Distance > 11000] <- NA
  surv$GroundSpeed[surv$GroundSpeed <= 0 | surv$GroundSpeed > 30] <- NA
  
  # -----------------------
  # Gentle outliers (ONLY spreads)
  # -----------------------
  surv <- .flag_outliers_iqr(
    surv,
    group_vars = c("Survey","Gear"),
    cols = c("DoorSpread","WingSpread"),
    k = 3
  )
  
  return(surv)
}

.flag_outliers_iqr <- function(x, group_vars, cols, k = 1.5) {
  
  group <- interaction(x[group_vars], drop = TRUE)
  
  for (col in cols) {
    
    values <- x[[col]]
    split_idx <- split(seq_along(values), group)
    
    for (idx in split_idx) {
      
      v <- values[idx]
      
      if (all(is.na(v)) || length(stats::na.omit(v)) < 4) next
      
      q1 <- stats::quantile(v, 0.25, na.rm = TRUE)
      q3 <- stats::quantile(v, 0.75, na.rm = TRUE)
      iqr <- q3 - q1
      
      low  <- q1 - k * iqr
      high <- q3 + k * iqr
      
      outliers <- v < low | v > high
      values[idx][outliers] <- NA
    }
    
    x[[col]] <- values
  }
  
  x
}
