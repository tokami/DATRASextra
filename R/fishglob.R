##' @title Clean data following FishGlob workflow
##'
##' @param x a DATRASraw object
##'
##' @description This function follows the workflow that was used to create the
##'     FishGlob data set (Maureaud et al. 2021). Adjusted from:
##'     \url{https://github.com/fishglob/FishGlob_data/tree/main/cleaning_codes}.
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

    x[["HH"]] <- x[["HH"]][colnames(x[["HH"]]) %in% hh.cols]
    x[["HL"]] <- x[["HL"]][colnames(x[["HL"]]) %in% hl.cols]
    x[["CA"]] <- NULL

    return(x)
}


##' @title Add Swept Area index following the FishGlob calculations
##'
##' @param x a DATRASraw object
##'
##' @details
##'
##' The unit of the swept area indices are squaremeters (m^2).
##'
##' The original functions were developed by Aurore Maureaud and Daniël van
##' Denderen and can be accessed here:
##' \url{https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R}.
##'
##' Note, that this function only calculates the swept area for surveys that are
##' included in the FISHGLOB (EVHOE, SWC-IBTS, BITS, IE-IGFS, FR-CGFS, NIGFS,
##' ROCKALL, SP-NORTH, SP-ARSA, SP-PORC; status November 2025).
##'
##' @return DATRASraw object with SweptArea index, columns "SweptArea" and
##'     "DoorArea".
##'
##' @export
addSweptAreaFishGlob <- function(x) {

    ## Adjusted from original script by Aurore Maureaud and Daniël van Denderen

    subsetSurvey <- function(x, survey){
        surv <- subset(x[["HH"]], Survey == survey)
        surv <- surv[ , !(names(surv) %in% c("TotalNo", "NoMeas",
                                             "CatCatchWgt", "LngtCode",
                                             "LngtClass", "HLNoAtLngt",
                                             "Valid_Aphia")) ]
        unique(surv)
    }

    combineSurvey <- function(surv){
        surv <- surv[, c("haul.id", "DoorSpread", "WingSpread")]
        names(surv)[names(surv) == "DoorSpread"] <- "DoorSpread2"
        names(surv)[names(surv) == "WingSpread"] <- "WingSpread2"
        surv
    }

    # Replace 0 with NA
    x[['HH']]$WingSpread[x[['HH']]$WingSpread == 0] <- NA
    x[['HH']]$DoorSpread[x[['HH']]$DoorSpread == 0] <- NA
    x[['HH']]$Distance[x[['HH']]$Distance == 0] <- NA

    ## select only certain gears
    x <- subset(
        x,
        !(Survey == "NS-IBTS" &
              Gear %in% c('ABD', 'BOT', 'DHT', 'FOT', 'GRT',
                          'H18', 'HOB', 'HT', 'KAB', 'VIN')),
        !(Survey == "BITS" &
              Gear %in% c('CAM', 'CHP', 'DT', 'EGY', 'ESB',
                          'EXP', 'FOT', 'GRT', 'H20', 'HAK',
                          'LBT','LPT', 'SON', 'P20')),
        !(Survey == "PT-IBTS" & Gear == "CAR"))


    ## Re-estimate the wing/doorspread from linear model per survey
    surveys <- unique(x[["HH"]]$Survey)
    area2.list <- vector("list", length(surveys))
    for(i in 1:length(surveys)){

        surv <- subsetSurvey(x, surveys[i])
        surv <- droplevels(surv) # safer



        ## Manual corrections --------------------------
        if(surveys[i] == "BITS"){
            surv$DoorSpread[surv$DoorSpread > 200] <- NA
            ## remove two outliers
        }
        if(surveys[i] == "EVHOE"){
            surv$WingSpread[!(surv$Year %in% 2016:2018)] <- NA #remove for sake of example
        }
        if(surveys[i] == "FR-CGFS"){
            surv$WingSpread[surv$WingSpread %in% 10] <- NA
            ## remove fixed number in 1994
        }
        if(surveys[i] == "NS-IBTS"){
            surv$WingSpread[surv$WingSpread %in% 50] <- NA
            ## remove one "outlier" at the high end
        }
        if(surveys[i] == "SWC"){
            surv$SweepLngt <- as.numeric(surv$SweepLngt)
            ## two hauls NA sweeplength
            surv$SweepLngt[is.na(surv$SweepLngt)] <- 60
            ##  (mean(swc$SweepLngt[swc$Ship == "749S"],na.rm = T) =60)
        }
        if(surveys[i] == "PT-IBTS"){
            surv$WingSpread[surv$WingSpread > 20] <- NA
            ## remove at high end
            surv$cat <- "shallow"
            surv$cat[surv$Depth > 120] <- "deep"
            ## seems to be a break-point when plotting (wingspread~depth)
        }


        ## Doorspread --------------------------
        if (surveys[i] %in% c("EVHOE")) {

            lm0 <- lm(DoorSpread ~ Depth * SweepLngt, data=surv)

        } else if (surveys[i] %in% c("SP-ARSA")) {

            lm0 <- lm(DoorSpread ~ log(Depth) * SweepLngt, data=surv)

        } else if (surveys[i] %in% c("SP-NORTH","ROCKALL",
                                     "IE-IGFS","SWC")) {

            lm0 <- lm(DoorSpread ~ log(Depth) , data=surv) # this make no sense double check + SweepLngt

        } else if (surveys[i] %in% c("SP-PORC","NIGFS","FR-CGFS")) {

            lm0 <- lm(DoorSpread ~ log(Depth), data=surv)

        } else if (surveys[i] %in% c("BITS")) {

            lm0 <- lm(DoorSpread ~ log(Depth) + Country + Gear, data=surv)
            ## no country
            lm1 <- lm(DoorSpread ~ log(Depth) + Gear, data=surv)

            ## select data with country x doorspread information
            addcountry <- subset(surv, surv$Country %in% lm0$xlevels$Country)
            ## select data without country x doorspread information
            nocountry <- subset(surv, !(surv$Country %in% lm0$xlevels$Country))

            ## add prediction to addcountry
            pred0 <- predict(lm0, newdata=addcountry, interval='confidence', level=0.95)
            addcountry$fit <-pred0[,1]
            surv <- cbind(surv, addcountry[match(surv$haul.id,addcountry$haul.id), c("fit")])
            colnames(surv)[ncol(surv)] <- "door_fit"

            ## do the same for nocountry
            pred0 <- predict(lm1, newdata=nocountry, interval='confidence', level=0.95)
            nocountry$fit <-pred0[,1]
            surv <- cbind(surv, nocountry[match(surv$haul.id,nocountry$haul.id), c("fit")])
            colnames(surv)[ncol(surv)] <- "door_fit2"

            ## merge into one, remove door_fit2
            surv$door_fit <- ifelse(is.na(surv$door_fit), surv$door_fit2, surv$door_fit)
            surv$door_fit2 <- NULL



        } else if (surveys[i] %in% c("NS-IBTS")) {

            ## add ships/sweeplength
            lm0 <- lm(DoorSpread ~ log(Depth) + SweepLngt + Ship, data=surv)
            ## use country for hauls that miss sweeplength and/or ships x doorspr.
            lm1 <- lm(DoorSpread ~ log(Depth) + Country, data=surv)

            ## select data with ship information + SweepLngt
            addship <- subset(surv, surv$Ship %in% lm0$xlevels$Ship &
                                  surv$SweepLngt >0)
            ## select data without ship information
            noship  <- subset(surv, !(surv$haul.id %in% addship$haul.id))

            ## add prediction to addship
            pred0 <- predict(lm0, newdata=addship, interval='confidence', level=0.95)
            addship$fit <-pred0[,1]
            surv <- cbind(surv, addship[match(surv$haul.id,addship$hau.id),
                                        c("fit")])
            colnames(surv)[ncol(surv)] <- "door_fit"

            ## do the same for noship
            pred0 <- predict(lm1, newdata=noship, interval='confidence',
                             level=0.95)
            noship$fit <-pred0[,1]
            surv <- cbind(surv, noship[match(surv$haul.id,noship$haul.id),
                                       c("fit")])
            colnames(surv)[ncol(surv)] <- "door_fit2"


            surv$door_fit <- ifelse(is.na(surv$door_fit), surv$door_fit2, surv$door_fit)
            surv$door_fit2 <- NULL

        }


        ## No Can-Mar or PT-IBTS
        if (surveys[i] %in% c("EVHOE","SP-ARSA","SP-NORTH","ROCKALL",
                              "IE-IGFS","SWC","SP-PORC","NIGFS",
                              "FR-CGFS")) {

            tryCatch({
                pred0 <- predict(lm0, newdata=surv, interval='confidence', level=0.95)
            }, warning = function(w){
                message("Warning for survey: ", surveys[i])
                message(w$message)
            })
            surv$door_fit <- pred0[,1]

        }


        ## Wingpread ---------------------------------
        if (surveys[i] == "EVHOE") {

            lm0 <- lm(WingSpread ~ DoorSpread * SweepLngt, data=surv)

        }else if(surveys[i] %in% c("ROCKALL","IE-IGFS")){

            lm0 <- lm(WingSpread ~ DoorSpread + SweepLngt, data=surv)

        }else if(surveys[i] %in% c("SP-ARSA","SP-PORC","SP-NORTH",
                                   "NIGFS","FR-CGFS","BITS")){

            lm0 <- lm(WingSpread ~ DoorSpread, data=surv)

        }else if(surveys[i] %in% c("SWC")){

            lm0 <- lm(WingSpread ~ log(Depth) + DoorSpread , data=surv)

        }else if(surveys[i] %in% c("NS-IBTS")){

            lm0 <- lm(WingSpread ~ log(Depth) + Country + DoorSpread + SweepLngt,
                      data=surv) ## add sweeplngt
            lm1 <- lm(WingSpread ~ log(Depth) + Country + DoorSpread, data=surv)
            ## model for hauls without sweeplngt

            surv[is.na(surv$DoorSpread),]$DoorSpread <-
                surv[is.na(surv$DoorSpread),]$door_fit
            ## include the DoorSpread prediction
            addship <- subset(surv, surv$SweepLngt >0)
            ## select data with SweepLngt information
            noship  <- subset(surv, !(surv$haul.id %in% addship$haul.id))
            ## select data without SweepLngt information

            pred0 <- predict(lm0, newdata=addship, interval='confidence', level=0.95)
            ## add prediction to addship
            addship$fit <-pred0[,1]
            surv <- cbind(surv, addship[match(surv$haul.id,addship$haul.id), c("fit")])
            colnames(surv)[ncol(surv)] <- "wing_fit"

            pred0 <- predict(lm1, newdata=noship, interval='confidence', level=0.95)
            ## do the same for noship
            noship$fit <-pred0[,1]
            surv <- cbind(surv, noship[match(surv$haul.id,noship$haul.id), c("fit")])
            colnames(surv)[ncol(surv)] <- "wing_fit2"

            surv$wing_fit <- ifelse(is.na(surv$wing_fit), surv$wing_fit2, surv$wing_fit)
            surv$wing_fit2 <- NULL

            surv[is.na(surv$WingSpread),]$WingSpread <-
                surv[is.na(surv$WingSpread),]$wing_fit

        } else if (surveys[i] %in% c("PT-IBTS")) {

            lm0 <- lm(WingSpread ~ Depth * cat, data=surv)

        }

        if (surveys[i] %in% c("EVHOE","SP-ARSA","SP-NORTH","ROCKALL",
                              "IE-IGFS","SWC","SP-PORC","NIGFS",
                              "FR-CGFS","BITS","PT-IBTS")) {

            if(all(!is.null(surv$door_fit))){
                surv[is.na(surv$DoorSpread),]$DoorSpread <-
                    surv[is.na(surv$DoorSpread),]$door_fit
            }

            pred0 <- predict.lm (object=lm0, newdata=surv,
                                 interval='confidence', level=0.95)
            surv$wing_fit <- pred0[,1]
            surv[is.na(surv$WingSpread),]$WingSpread <-
                surv[is.na(surv$WingSpread),]$wing_fit
        }

        ## If not DoorSpread information!
        if (surveys[i] %in% c("PT-IBTS")) {
            surv$DoorSpread <- surv$WingSpread / 0.3
            ## doorspread probably not needed, rough estimate
        }

        ## Combine
        area2.list[[i]] <- combineSurvey(surv)
    }

    area2 <- do.call(rbind, area2.list)


    ## Replace WingSpread and DoorSpread with imputed values if missing
    area2 <- unique(area2)
    x[["HH"]] <- merge(x[["HH"]], area2, by = "haul.id", all.x = TRUE)
    x$DoorSpread <- ifelse(is.na(x$DoorSpread), x$DoorSpread2, x$DoorSpread)
    x$WingSpread <- ifelse(is.na(x$WingSpread), x$WingSpread2, x$WingSpread)
    x$DoorSpread2 <- NULL
    x$WingSpread2 <- NULL


    ## Calculate Swept Area from WingSpread and DoorSpread
    dist <- unique(x[["HH"]][, c("haul.id", "Survey", "Year",
                                 "Ship", "Country", "Distance",
                                 "GroundSpeed", "HaulDur")])

    ## plot(dist$Distance, dist$GroundSpeed*1.852*dist$HaulDur/60*1000)
    ## remove Distances at high end (seem wrong, see plot)
    dist$Distance[dist$Distance > 11000] <- NA
    ## seems wrong so also in survey data
    x$Distance[x$Distance > 11000] <- NA
    ## remove strande speeds
    dist$GroundSpeed[dist$GroundSpeed > 30] <- NA
    ## calculate 2nd distance
    dist$Distance2 <- dist$GroundSpeed*1.852*dist$HaulDur/60*1000
    dist$Distance <- ifelse(is.na(dist$Distance), dist$Distance2, dist$Distance)
    dist$Distance2 <- NULL

    ## NAs remaining missing speeds
    ## take average speed per survey, year, ship
    avgspeed <- aggregate(dist$GroundSpeed,
                          by=list(dist$Survey, dist$Year, dist$Ship),
                          FUN = mean, na.rm=T)
    colnames(avgspeed) <- c("Survey", "Year", "Ship","GroundSpeed2")

    dist <- merge(dist, avgspeed, by = c("Survey", "Year", "Ship"), all.x = TRUE)
    dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                               dist$GroundSpeed2, dist$GroundSpeed)
    dist$GroundSpeed2 <- NULL

    ## take average speed per survey, year, country
    avgspeed <- aggregate(dist$GroundSpeed,
                          by=list(dist$Survey, dist$Year, dist$Country),
                          FUN = mean, na.rm=T)
    colnames(avgspeed) <- c("Survey", "Year", "Country","GroundSpeed2")

    dist <- merge(dist, avgspeed, by = c("Survey", "Year", "Country"), all.x = TRUE)
    dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                               dist$GroundSpeed2, dist$GroundSpeed)
    dist$GroundSpeed2 <- NULL

    ## take average speed per survey, country
    avgspeed <- aggregate(dist$GroundSpeed, by=list(dist$Survey, dist$Country),
                          FUN = mean, na.rm=T)
    colnames(avgspeed) <- c("Survey", "Country", "GroundSpeed2")

    dist <- merge(dist, avgspeed, by = c("Survey", "Country"), all.x = TRUE)
    dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                               dist$GroundSpeed2, dist$GroundSpeed)
    dist$GroundSpeed2 <- NULL

    ## take average speed
    dist$GroundSpeed2 <- mean(dist$GroundSpeed,na.rm=T)
    dist$GroundSpeed <- ifelse(is.na(dist$GroundSpeed),
                               dist$GroundSpeed2, dist$GroundSpeed)
    dist$GroundSpeed2 <- NULL

    ## calculate 2nd distance
    dist$Distance2 <- dist$GroundSpeed*1.852*dist$HaulDur/60*1000

    dist$Distance_pred <- ifelse(is.na(dist$Distance), dist$Distance2, dist$Distance)
    dist <- dist[ , !(names(dist) %in% c("Distance2", "Distance",
                                         "GroundSpeed",
                                         "HaulDur",
                                         "Survey", "Year", "Ship", "Country")) ]

    x[["HH"]] <- merge(x[["HH"]], dist, by = "haul.id", all.x = TRUE)


    x[["HH"]]$Distance <- ifelse(is.na(x[["HH"]]$Distance),
                                 x[["HH"]]$Distance_pred, x[["HH"]]$Distance)
    x[["HH"]]$Distance_pred <- NULL

    x[["HH"]]$SweptArea <- x[["HH"]]$Distance * 0.001 * x[["HH"]]$WingSpread * 0.001
    x[["HH"]]$DoorsArea <- x[["HH"]]$Distance * 0.001 * x[["HH"]]$DoorSpread * 0.001

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
    req_cols <- c("Valid_Aphia","ScientificName_WoRMS","HLNoAtLngt","LngtCm")
    missing_cols <- req_cols[!req_cols %in% names(hl)]
    if (length(missing_cols) > 0) stop("missing required HL columns: ", paste(missing_cols, collapse=", "))

    ## load species info
    data(speciesInfo, envir = environment())

    ## merge with species info to get a and b parameters
    hl2 <- merge(
        hl,
        speciesInfo[speciesInfo$class %in% c("Teleostei","Elasmobranchii","Petromyzonti","Myxini"), ],
        by.x = c("Valid_Aphia","ScientificName_WoRMS"),
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
        "ScientificName_WoRMS","genus","family","order","class","rank"
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
    hh2$accepted_name <- hh2$ScientificName_WoRMS

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
