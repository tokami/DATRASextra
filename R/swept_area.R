



##' @title Add Swept Area index following the FishGlob calculations
##'
##' @param x a DATRASraw object.
##'
##' @return DATRASraw object with SweptArea index.
##'
##' @export
addSweptAreaFishGlob <- function(x){

    ## Adjusted from original script by Aurore Maureaud + Daniël van Denderen
    ## TODO: include imputation code for other surveys

    xin <- x

    subsetSurvey <- function(x, survey){
        surv <- subset(x[["HH"]], Survey == survey)
        surv <- surv[ , !(names(surv) %in% c("TotalNo", "NoMeas",
                                             "CatCatchWgt", "LngtCode",
                                             "LngtClass", "HLNoAtLngt",
                                             "AphiaID")) ]
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

##' @title Add Swept Area based on wing spread / beam width using a simple approach.
##'
##' @param d a DATRASraw object.
##' @param minSpeed x
##' @param minDist x
##' @param maxDistDev x
##' @param impute.missing FALSE
##'
##' @return DATRASraw object with two SweptArea indices: SweptArea and SweptArea.median. The latter assumes a fixed trawl width for each gear category (the median).
##'
##' @export
addSweptAreaSimple <- function(d,
                               minSpeed = 1,
                               minDist = 0,
                               maxDistDev = 0.2,
                               impute.missing = FALSE) {

    d$GroundSpeed[ d$GroundSpeed < minSpeed ] <- NA
    d$Distance[ d$Distance < minDist ] <- NA
    d$WingSpread[ d$WingSpread<=0 ] <- NA
    d$WingSpread[ d$Gear=="GOV" & ( d$WingSpread<5 | d$WingSpread >40 ) ] <- NA

    ## Remove some distance outliers
    Distance2 <- (d$HaulDur / 60 * 1852 * d$GroundSpeed)
    badDist <- abs((d$Distance - Distance2)/d$Distance)>maxDistDev
    d$Distance[ badDist ] <- NA

    d2 <- d[[2]]

    ## Impute missing wing spreads (median within gear)
    wtab <- aggregate(WingSpread ~ Gear, data=d2, FUN=median, na.rm=TRUE)
    for(i in 1:nrow(wtab)){
        sel <- which(d$Gear==wtab$Gear[i] & is.na(d$WingSpread))
        d$WingSpread[ sel ] <- wtab$WingSpread[i]
    }
    d$WingSpread2 <- NULL

    d$WingSpread[d$Gear == "BT12"]   <- 12
    d$WingSpread[d$Gear == "BT8"]    <- 8
    d$WingSpread[d$Gear == "BT4A"]   <- 4
    d$WingSpread[d$Gear == "BT7"]    <- 7
    d$WingSpread[d$Gear == "BT4AI"]  <- 4
    d$WingSpread[d$Gear == "BT4S"]   <- 4
    d$WingSpread[d$Gear == "BT4P"]   <- 4
    d$WingSpread[d$Gear == "BT6"]    <- 6
    d$WingSpread[d$Gear == "BT3"]    <- 3

    ## For Beam trawls, GearEx == "DB" means double beam, i.e. catches from two beam trawls added.
    d$BeamWidth[ !is.na(d$GearEx) & d$GearEx=="DB" ] <- d$BeamWidth[ !is.na(d$GearEx) & d$GearEx=="DB" ]*2

    ## There are probably errors in recorded in wing spread and unclear how CPUE correlates with wing spread.
    ## It might therefore be a more robust assumption to use a fixed (median) Wingspread for each gear type.
    d$WingSpread.median <- d$WingSpread
    for(i in 1:nrow(wtab)){
        sel <- which(d$Gear==wtab$Gear[i])
        d$WingSpread.median[ sel ] <- wtab$WingSpread[i]
    }

    ## Impute missing ground speeds
    d2 <- d[[2]]
    stab <- aggregate(GroundSpeed~Gear,data=d2,FUN=median,na.rm=TRUE) ## TODO Gear + Survey?
    for(i in 1:nrow(stab)){
        if(!is.na(stab$GroundSpeed[i])){
            d$GroundSpeed[ is.na(d$GroundSpeed) & d$Gear==stab$Gear[i]  ] <- stab$GroundSpeed[i]
        }
    }
    for(i in 1:nrow(stab)){
        sel <- which(d$Gear==stab$Gear[i] & is.na(d$GroundSpeed))
        d$GroundSpeed[ sel ] <- stab$GroundSpeed[i]
    }

    ## Impute missing distances
    noDist <- which( is.na(d$Distance) )
    d$Distance[ noDist ] <- (d$HaulDur[noDist] / 60 * 1852 * d$GroundSpeed[noDist])

    d$SweptArea <- d$WingSpread * d$Distance
    d$SweptArea.median <- d$WingSpread.median * d$Distance

    return(d)
}
