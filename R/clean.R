
##' @title Clean data
##'
##' @param x a DATRASraw object.
##'
##' @return Cleaned DATRASraw object.
##'
##' @importFrom mgcv gam s predict.gam
##'
##' @export
clean <- function(x, aphias = NULL, years = NULL, quarters = NULL,
                  gears = NULL, impute.missing.depth = TRUE,
                  correct.species = TRUE){


    ## Minimum cleaning ------------------------

    ## HaulVal (https://vocab.ices.dk/?ref=1)
    x <- subset(x, HaulVal %in% c("V","N"))
    ## A	Additional valid stations not used for index calculations
    ## C	Calibrated (BITS only)
    ## I	Invalid haul
    ## M	Pelagic Midwater Trawl (BITS only)
    ## N	No oxygen (BITS only)
    ## P  Partly valid haul - there is catch, but trawl sensors show problems,
    ##    faulty door distance, or other indications of malfunction
    ## S	Standard haul
    ## V	Valid haul

    ## StdSpecRecCode (https://vocab.ices.dk/?ref=88)
    x <- subset(x, StdSpecRecCode == 1)
    ## 0	No standard species recorded
    ## 1	All standard species recorded
    ## 2	Pelagic standard species recorded
    ## 3	Roundfish standard species recorded
    ## 4	Individual standard species recorded

    ## Only keep TVL and TVS in BITS
    ## x <- subset(x, Survey != "BITS" |
    ##                (Survey == "BITS" & Gear %in% c("TVS","TVL")))


    ## Optional subsetting -----------------------
    if(!is.null(aphias)){
        x <- subset(x,
                    Valid_Aphia %in% aphias)
    }
    if(!is.null(years)){
        x <- subset(x,
                    Year %in% years)
    }
    if(!is.null(quarters)){
        x <- subset(x,
                    Quarter %in% quarters)
    }
    if(!is.null(gears)){
        x <- subset(x,
                    Gear %in% gears)
    }

    ## Impute depths ------------------------------
    if (impute.missing.depth && any(is.na(x[[2]]$Depth))) {
        dmodel <- mgcv::gam(log(Depth) ~ s(lon, lat, k = 200), data = x[[2]])
        sel <- subset(x, is.na(Depth))
        sel$Depth <- 0 ## Guard against NA-error
        x$Depth[is.na(x$Depth)] <- exp(mgcv::predict.gam(dmodel, newdata = sel[[2]]))
        sel <- dmodel <- NULL; gc()
    }


    ## Species correction -------------------------
    x <- correctSpecies(x)

    return(x)
}


##' @title Prune data
##'
##' @param x a DATRASraw object.
##'
##' @return Cleaned DATRASraw object.
##'
##' @importFrom mgcv gam s predict.gam
##'
##' @export
prune <- function(x){

    ca.cols <- c("RecordType","Survey","Quarter","Year","LngtCode","LngtClas",
                 "Sex","Maturity","PlusGr","Age","NoAtALK","IndWgt",
                 "MaturityScale","Valid_Aphia","LngtCm","Species","haul.id")

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

    x[["CA"]] <- x[["CA"]][colnames(x[["CA"]]) %in% ca.cols]
    x[["HH"]] <- x[["HH"]][colnames(x[["HH"]]) %in% hh.cols]
    x[["HL"]] <- x[["HL"]][colnames(x[["HL"]]) %in% hl.cols]

    return(x)
}
