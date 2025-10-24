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
##' @return Cleaned DATRASraw object according to FisGlob workflow.
##'
##' @export
cleanFishglob <- function(x) {

    ## HaulVal (https://vocab.ices.dk/?ref=1)
    x <- subset(x, HaulVal %in% "V")

    ## TODO
    ## ... (more fishglob cleaning)

    ## https://github.com/fishglob/FishGlob_data/blob/233d0f4c82114268ac2f8f58d340d11e7efb02c6/cleaning_codes/get_datras.R


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
    ## if not: create do.fishglob flag?
    x <- correctSpecies(x)

    return(x)
}





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

    return(res)
}
