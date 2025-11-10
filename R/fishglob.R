##' @title Clean data following FishGlob workflow
##'
##' @param x a DATRASraw object.
##' @param aphias x
##' @param years x
##' @param quarters x
##' @param gears x
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

    ## HaulVal (https://vocab.ices.dk/?ref=1)
    x <- subset(
        x,
        HaulVal %in% "V",
        !is.na(Valid_Aphia), # AphiaID in fishglob
        SpecVal %in% c(1, 10, 4, 5, 6, 7, 8),
        DataType %in% c("S", "R", "C"), 
        StdSpecRecCode == 1 #L382
    ) # from https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R#L347

    # @Tobi is this needed https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R#L359 or is it coded somewhere else?
    
    ## TODO
    ## ... (more fishglob cleaning)

    ## https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R

    ## Also use this here or in another function?
    ## https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/get_datras.R#L347


    ## Keep
    ## hl.pt <- read.csv("/Volumes/Elements/fishglob data/Publicly available/DATRAS/hl.pt.csv") %>%
    ##     dplyr::rename(Valid_Aphia = ValidAphiaID) %>%
    ##     select(RecordType, Survey, Quarter, Country, Ship, Gear, SweepLngt, GearEx,
    ##            DoorType, StNo, HaulNo, Year, SpecCodeType, SpecCode, SpecVal, Sex,
    ##            TotalNo, CatIdentifier, NoMeas, SubFactor, SubWgt, CatCatchWgt, LngtCode,
    ##            LngtClass, HLNoAtLngt, DevStage, LenMeasType, DateofCalculation,
    ##            Valid_Aphia)

    ## Species correction -------------------------
    ## TODO check that this is the same as in fishglob,
    ## Fede: checked, it's the same!
    ## if not: create do.fishglob flag?
    x <- correctSpecies(x)
    
    ## https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/get_datras.R#L432

    return(x)
}



## TODO add weight function for fishglob?
## https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/get_datras.R#L432



##' @title Prune data according to FishGlob workflow
##'
##' @param x a DATRASraw object.
##'
##' @return Pruned DATRASraw object according to FishGlb workflow.
##'
##' @export
pruneFishglob <- function(x) {

    ## TODO see what they keep

    hh.cols <- c("RecordType","Survey","Quarter","Ship","Gear","Year","Month",
                 "Day","TimeShot","HaulDur","DayNight", "StatRec","Depth",
                 "HaulVal","StdSpecRecCode","DataType", "Distance","DoorSpread",
                 "WingSpread","GroundSpeed", "haul.id", "abstime", "timeOfYear",
                 "TimeShotHour", "lon","lat", "Roundfish")

    hl.cols <- c("haul.id","RecordType","Survey","Quarter","Ship","Gear",
                 "Year","SpecVal","Sex","TotalNo", ## "CatIdentifier", "NoMeas",
                 "SubFactor","SubWgt","CatCatchWgt","LngtCode","LngtClas",
                 "HLNoAtLngt", ## "LenMeasType",
                 "Valid_Aphia","LngtCm","Species", "HaulDur","DataType","Count")

    x[["CA"]] <- NULL
    x[["HH"]] <- x[["HH"]][colnames(x[["HH"]]) %in% hh.cols]
    x[["HL"]] <- x[["HL"]][colnames(x[["HL"]]) %in% hl.cols]

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
addSweptAreaFishGlob <- function(x){

    ## Adjusted from original script by Aurore Maureaud and Daniël van Denderen
    xin <- x

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

    x$WingSpread[x$WingSpread == 0] <- NA
    x$DoorSpread[x$DoorSpread == 0] <- NA
    x$Distance[x$Distance == 0] <- NA

    ## select only certain gears
    ## 1. summary of gears per survey
    ## ...
    ## 2. only select certain gears per survey (GOV and/or most dominant in
    ## cases without GOV)
    ## TODO: review this (other surveys represented)
    x <- subset(x, !(x$Survey == "NS-IBTS" &
                     x$Gear %in% c('ABD', 'BOT', 'DHT', 'FOT', 'GRT',
                                   'H18', 'HOB', 'HT', 'KAB', 'VIN')) &
                   !(x$Survey == "BITS" &
                     x$Gear %in% c('CAM', 'CHP', 'DT', 'EGY', 'ESB',
                                   'EXP', 'FOT', 'GRT', 'H20', 'HAK',
                                   'LBT', 'SON')) &
                   !(x$Survey == "PT-IBTS" & x$Gear == 'CAR'))


    ## Re-estimate the wing/doorspread from linear model per survey
    surveys <- unique(x[["HH"]]$Survey)
    area2.list <- vector("list", length(surveys))
    for(i in 1:length(surveys)){

        surv <- subsetSurvey(x, surveys[i])
        ## !is.na(x$Depth) (but we can intrapolate...) for NS-IBTS


        ## Manual corrections --------------------------
        if(surveys[i] == "BITS"){
            surv$DoorSpread[surv$DoorSpread > 200] <- NA
            ## remove two outliers
        }
        if(surveys[i] == "EVHOE"){
            surv$WingSpread[!(surv$Year %in% 2016:2018)] <- NA
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

            lm0 <- lm(DoorSpread ~ log(Depth) + SweepLngt, data=surv)

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

            pred0 <- predict.lm (object=lm0, newdata=surv,
                                 interval='confidence', level=0.95)
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


##' Calculate weight by length classes using empirical a and b, and add to
##' HH-records accoring to FishGlob workflow
##'
##' @title Calculate weight by length classes using empirical a and b, and add
##'     to HH-records
##'
##' @param d DATRASraw object
##' @param to1min divide by haul duration in minutes? (defaults to TRUE)
##'
##' @return DATRASraw object
##'
##' @importFrom DATRAS checkSpectrum
##'
##' @export
addWeightFishglob <- function (d, to1min = TRUE) {
    DATRAS::checkSpectrum(d)

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



##' @title Format DATRAS data to FishGlob data set
##'
##' @param x a DATRASraw object.
##'
##' @return Dataframe in format of FishGlob data set.
##'
##' @export
formatFishglob <- function(x) {

    res <- x

    ## TODO: select columns kept in FishGlob data set

    ## TODO integrate fishglob:
    ## https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/get_datras.R#L1023
    ## survey4 <- survey3 %>%
    ##     rename(survey = Survey,
    ##            haul_id = HaulID,
    ##            stat_rec = StatRec,
    ##            year = Year,
    ##            month = Month,
    ##            quarter = Quarter,
    ##            season = Season,
    ##            latitude = ShootLat,
    ##            longitude = ShootLong,
    ##            haul_dur = HaulDur,
    ##            area_swept = Area.swept,
    ##            gear = Gear,
    ##            depth = Depth,
    ##            sbt = SBT,
    ##            sst = SST,
    ##            verbatim_aphia_id = AphiaID,
    ##            aphia_id = worms_id,
    ##            accepted_name = taxa,
    ##            ) %>%
    ##     mutate(day = NA_integer_,
    ##            verbatim_name = NA_character_,
    ##            station = NA_character_,
    ##            stratum = NA_character_,
    ##            sub_area = NA_character_,
    ##            continent = "europe",
    ##            country = case_when(survey=="PT-IBTS" ~ "portugal",
    ##                                survey=="EVHOE" ~ "france",
    ##                                survey=="IE-IGFS" ~ "ireland",
    ##                                survey %in% c("ROCKALL","SWC-IBTS","NIGFS") ~ "uk",
    ##                                survey=="FR-CGFS" ~ "france",
    ##                                survey %in% c("NS-IBTS","BITS") ~ "multi-countries",
    ##                                survey %in% c("SP-NORTH","SP-ARSA") ~ "spain",
    ##                                survey == "SP-PORC" ~ "multi-countries"),
    ##            num = numlencpue*area_swept,
    ##            num_cpue = numlenh,
    ##            num_cpua = numlencpue,
    ##            wgt = wgtlencpue*area_swept,
    ##            wgt_cpue = wgtlenh,
    ##            wgt_cpua = wgtlencpue,
    ##            haul_dur = haul_dur/60,
    ##            source = "DATRAS ICES",
    ##            timestamp = "2021-07",
    ##            survey_unit = ifelse(survey %in% c("BITS","NS-IBTS","SWC-IBTS","SP-ARSA"),
    ##                                 paste0(survey,"-",quarter),survey),
    ##            survey_unit = ifelse(survey %in% c("NEUS","SEUS","SCS","GMEX"),
    ##                                 paste0(survey,"-",season),survey_unit)) %>%
    ##                                     # Final format
    ##     select(fishglob_data_columns$`Column name fishglob`)



    return(res)
}
