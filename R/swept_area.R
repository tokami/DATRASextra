##' @title Add Swept Area based on wing spread / beam width using a simple approach.
##'
##' @param d a DATRASraw object.
##' @param minSpeed x
##' @param minDist x
##' @param maxDistDev x
##' @param impute.missing FALSE
##'
##' @details In m^2.
##'
##' @return DATRASraw object with two SweptArea indices: SweptArea and
##'     SweptArea.median. The latter assumes a fixed trawl width for each gear
##'     category (the median).
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
