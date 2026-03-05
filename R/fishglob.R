##' @title Clean data following FishGlob workflow
##'
##' @param x a DATRASraw object
##'
##' @description This function follows the workflow that was used to create the
##' FishGlob data set (Maureaud et al. 2021). Adjusted from:
##' \url{https://github.com/fishglob/FishGlob_data/tree/main/cleaning_codes}.
##'
##'
##' A Maureaud, A., Frelat, R., Pécuchet, L., Shackell, N., Mérigot, B., Pinsky,
##' M.L., Amador, K., Anderson, S.C., Arkhipkin, A., Auber, A. and Barri, I.,
##' 2021. Are we ready to track climate-driven shifts in marine species across
##' international boundaries? A global survey of scientific bottom trawl data.
##' Global change biology, 27(2), pp.220-236.
##'
##' @return Cleaned DATRASraw object according to FishGlob workflow.
##'
##' @export
cleanFishglob <- function(x) {

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
    x <- renameSurvey(x, "SCOWCGFS", "SWC-IBTS")
    ## SCOROC -> ROCKALL
    x <- renameSurvey(x, "SCOROC", "ROCKALL")


    ## Account for by catch sampling ------------
    ## Remove hauls were not all species were recorded
    ## https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R#L382
    x[["HH"]] <- x[["HH"]][!(x[["HH"]]$Survey == "NS-IBTS" &
                             x[["HH"]]$BySpecRecCode %in% c(0, 2, 3, 4, 5)) &
                           !(x[["HH"]]$Survey == "BITS" &
                             x[["HH"]]$BySpecRecCode == 0),]


    ## Species correction -----------------------
    ## https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/get_datras.R#L432
    x <- correctSpecies(x)

    return(x)
}



##' @title Prune data according to FishGlob workflow
##'
##' @param x a DATRASraw object.
##'
##' @details DATRAS' CA data set, and some columns in the 'HH' and 'HL' data
##'     sets are not needed to reproduce the FishGlob data set. Thus, these data
##'     sets and columns can be removed to save some memory.
##'
##' @return Pruned DATRASraw object according to FishGlb workflow.
##'
##' @export
pruneFishglob <- function(x) {

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


##' @title Add swept area indices following FishGlob methodology
##'
##' @description
##' Computes swept area indices (m^2) for haul-level records in a
##' `DATRASraw` object following the methodology developed for FishGlob.
##'
##' DoorSpread and WingSpread are re-estimated using survey-specific
##' linear models (stored internally in the package) when missing.
##' Towing distance is calculated from recorded distance or reconstructed
##' from ground speed and haul duration using a hierarchical fallback:
##' Survey-Year-Ship → Survey-Year-Country → Survey-Country → Global mean.
##'
##' Swept area is calculated as:
##' \deqn{
##' SweptArea = Distance \times WingSpread \times 10^{-6}
##' }
##'
##' Door area is calculated analogously using DoorSpread.
##'
##' @param x A `DATRASraw` object containing haul-level (`HH`) data.
##'
##' @details
##' The original spread estimation logic was developed by
##' Aurore Maureaud and Daniël van Denderen and is available at:
##' \url{https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R}.
##'
##' This implementation uses pre-fitted survey-specific models stored
##' internally in the package and applies hierarchical fallback logic
##' when factor levels are not present in the training data.
##'
##' Swept area is returned in square km (km^2).
##'
##' @return A `DATRASraw` object with two additional columns in `HH`:
##' \itemize{
##'   \item \code{SweptArea} — swept area in km^2
##'   \item \code{DoorsArea} — door swept area in km^2
##' }
##'
##' @export
addSweptAreaFishGlob <- function(x) {
    
    
    # helper function for safe predictions ------------------------------------
    
    
    safe_predict_hierarchy <- function(newdata, model_set, prefix) {
        
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
    
    
    # other helper -----------------------------------------------------------
    combineSurvey <- function(surv){
        surv <- surv[, c("haul.id","DoorSpread","WingSpread")]
        names(surv)[names(surv) == "DoorSpread"] <- "DoorSpread2"
        names(surv)[names(surv) == "WingSpread"] <- "WingSpread2"
        surv
    }
    
    
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
        
        # model predictions 
        model_set <- spread_models[[surveys[i]]]
        
        # ---- DoorSpread ----
        missing_door <- is.na(surv$DoorSpread)
        if (any(missing_door)) {
            newdata <- surv[missing_door, , drop = FALSE]
            preds <- safe_predict_hierarchy(newdata, model_set, "door")
            surv$DoorSpread[missing_door] <- preds
        }
        
        # ---- WingSpread ----
        missing_wing <- is.na(surv$WingSpread)
        if (any(missing_wing)) {
            newdata <- surv[missing_wing, , drop = FALSE]
            preds <- safe_predict_hierarchy(newdata, model_set, "wing")
            surv$WingSpread[missing_wing] <- preds
        }
        
        # PT fallback
        if (surveys[i] == "PT-IBTS" &&
            all(is.na(surv$DoorSpread))) {
            surv$DoorSpread <- surv$WingSpread / 0.3
        }
        
        area2.list[[i]] <- combineSurvey(surv)
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
    
    dist$Distance[dist$Distance > 11000] <- NA
    x$Distance[x$Distance > 11000] <- NA
    dist$GroundSpeed[dist$GroundSpeed > 30] <- NA
    
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



##' calculate weight by length classes using empirical a and b, and add to
##' hh records according to fishglob workflow
##'
##' @title calculate weight by length classes and add to hh records
##'
##' @param x a DATRASraw object
##'
##' @return a DATRASraw object with hl table updated with weight fields
##'
##' @details
##' - weight-at-length is calculated per individual using empirical a and b parameters
##' - total weight per length class is computed as number at length * individual weight
##' - optionally, weight can be divided by haul duration in minutes
##' - final weight is returned in kg
##'
##' @export
addWeightFishglob <- function(x) {

    ## --- input checks ---
    if (!inherits(x, "DATRASraw")) stop("input must be a DATRASraw object")
    if (!all(c("HL","HH") %in% names(x))) stop("DATRASraw object must contain HL and HH tables")

    hl <- x[["HL"]]
    hh <- x[["HH"]]

    ## convert factors to character
    hl[] <- lapply(hl, function(z) if (is.factor(z)) as.character(z) else z)

    ## check required columns
    req_cols <- c("Valid_Aphia","Species","HLNoAtLngt","LngtCm")
    missing_cols <- req_cols[!req_cols %in% names(hl)]
    if (length(missing_cols) > 0) stop("missing required HL columns: ", paste(missing_cols, collapse=", "))

    ## load species info
    data(speciesInfo, envir = environment())

    ## merge with species info to get a and b parameters
    hl2 <- merge(
        hl,
        speciesInfo[speciesInfo$class %in% c("Teleostei","Elasmobranchii","Petromyzonti","Myxini"), ],
        by.x = c("Valid_Aphia","Species"),
        by.y = c("WoRMS_AphiaID","ScientificName_WoRMS"),
        all.x = FALSE
    )

    ## warning if a/b missing
    if (any(is.na(hl2$aFG)) || any(is.na(hl2$bFG))) {
        missing <- unique(hl2$Valid_Aphia[is.na(hl2$aFG) | is.na(hl2$bFG)])
        warning("some species missing a/b parameters in speciesInfo: ", paste(missing, collapse=", "))
    }

    ## calculate weights
    hl2$Wgt_indiv <- with(hl2, aFG * (LngtCm ^ bFG))  # grams per individual
    hl2$Wgt_total <- hl2$Wgt_indiv * hl2$Count   # grams per length class group

    ## convert to kg
    hl2$Wgt_total <- hl2$Wgt_total / 1000             # kg

    ## update hl table in DATRASraw object
    x[["HL"]] <- hl2

    return(x)
}


##' @title Format DATRAS data to FishGlob data set
##'
##' @param x a DATRASraw object.
##'
##' @return Dataframe in format of FishGlob data set.
##'
##' @importFrom stats aggregate
##'
##' @export
formatFishglob.DATRASraw <- function(x) {

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
