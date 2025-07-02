
##' @title Download DATRAS survey information
##'
##' @param surveys surveys
##'
##' @return NULL
##'
##' @importFrom DATRAS downloadExchange
##' @importFrom icesDatras getSurveyList getSurveyYearList
##'
##' @export
downloadDATRAS <- function(surveys = NULL,
                           years = NULL,
                           download.missing.only = TRUE,
                           dir = NULL,
                           verbose = TRUE){

    yearsin <- years

    dir0 <- getwd()

    if(is.null(dir)) dir <- dir0

    ## Surveys
    if(is.null(surveys)){
        surveys <- icesDatras::getSurveyList()
        ## surveys.with.issues <- c("NS-IDPS", "IS-IDPS")
    }

    ## Dowload data for each survey
    for(s in 1:length(surveys)){
        survey <- surveys[s]

        print(paste0("Doing survey: ", survey))

        ## Create directory if doesn't exist
        if(!dir.exists(file.path(dir, survey))) dir.create(file.path(dir, survey))

        ## Download data to directory
        setwd(file.path(dir, survey))

        ## TODO: check if php works on mac
        if (.Platform$OS.type == "windows") {

            years <- icesDatras::getSurveyYearList(survey)
            if (!is.null(yearsin)) {
                years <- years[years %in% yearsin]
            }
            for (y in 1:length(years)) {
                year <- years[y]
                quarters <- icesDatras::getSurveyYearQuarterList(survey, year)

                if (download.missing.only) {
                    if (!file.exists(file.path(dir, survey,
                                               paste0(survey,"_",year,".zip")))) {
                        datras_raw <- getDatrasExchange(survey, year, quarters,
                                                        strict = TRUE)
                        datras_clean <- removeExtraVariables(datras_raw)
                        writeExchange(datras_clean, file.path(dir, survey,
                                                     paste0(survey,"_",year,".zip")))
                    }
                } else {
                    datras_raw <- getDatrasExchange(survey, year, quarters,
                                                    strict = TRUE)
                        datras_clean <- removeExtraVariables(datras_raw)
                    writeExchange(datras_clean,
                                  file.path(dir, survey,
                                            paste0(survey,"_",year,".zip")))
                }
            }

        } else {

            if (download.missing.only) {
                years <- icesDatras::getSurveyYearList(survey)
                if (!is.null(yearsin)) {
                    years <- years[years %in% yearsin]
                }
                for (y in 1:length(years)) {
                    year <- years[y]
                    if (!file.exists(file.path(dir, survey,
                                               paste0(survey,"_",year,".zip")))) {
                        tmp <- downloadExchange(survey, year)
                    }
                }
            } else {
                if (!is.null(yearsin)) {
                    years <- icesDatras::getSurveyYearList(survey)
                    years <- years[years %in% yearsin]
                }
                tmp <- downloadExchange(survey, years)
            }

        }
    }

    setwd(dir0)

    if(verbose) writeLines(paste0("Survey information has been downloaded and saved in folder for each survey at: ", dir))

    return(invisible(NULL))
}




##' @title Download DATRAS survey information
##'
##' @param surveys surveys
##'
##' @return NULL
##'
##' @importFrom DATRAS downloadExchange
##'
##' @export
readDATRAS <- function(paths, years = NULL){

    if (any(dir.exists(paths))) {

        if (!is.null(years)) {
            paths <- dir(paths,
                         full.names = TRUE)[sort(unlist(lapply(years,
                                                               function(x)
                                                                   grep(x, dir(paths)))))]
            surv0 <- readExchange(paths, strict = FALSE)
        }else{
            surv0 <- readExchangeDir(paths,
                                     pattern = ".zip",
                                     strict = FALSE)
        }

    } else if (any(file.exists(paths))) {

        surv0 <- readExchange(paths, strict = FALSE)

    }else {

        stop(paste0("Cannot find a file or folder under path: ",
                    paste(paths, collapse = ", ")))

    }

    return(surv0)
}



##' @title Write DATRASraw to Exchange
##'
##' @param x a DATRASraw object
##'
##' @return NULL
##'
##' @export
writeExchange <- function(x, zipfile = "DATRAS.zip") {
    stopifnot(inherits(x, "DATRASraw"))

    tmp_csv <- tempfile(fileext = ".csv")
    con <- file(tmp_csv, open = "wt", encoding = "UTF-8")
    for (comp in c("HH", "HL", "CA")) {
        if (!comp %in% names(x)) next
        df <- x[[comp]]
        if (nrow(df) == 0) next
        writeLines(paste(names(df), collapse = ","), con)
        write.table(df, con, sep = ",", row.names = FALSE,
                    col.names = FALSE, append = TRUE, na = "",
                    quote = FALSE, eol = "\n")
    }
    close(con)

    zip(zipfile, files = tmp_csv, flags = "-j")  # -j to strip directory

    message("Created zip file: ", zipfile)
    invisible(zipfile)
}




removeExtraVariables <- function(x) {
  stopifnot(inherits(x, "DATRASraw"))

  # Define the official names for each component
  CA_vars <- c(
    "RecordType", "Survey", "Quarter", "Country", "Ship", "Gear",
    "SweepLngt", "GearEx", "DoorType", "StNo", "HaulNo", "Year",
    "SpecCodeType", "SpecCode", "AreaType", "AreaCode", "LngtCode",
    "LngtClas", "Sex", "Maturity", "PlusGr", "Age", "NoAtALK",
    "IndWgt", "FishID", "GenSamp", "StomSamp", "AgeSource",
    "AgePrepMet", "OtGrading", "ParSamp", "MaturityScale",
    "LiverWeight", "Valid_Aphia", "ScientificName_WoRMS",
    "DateofCalculation"
  )

  HH_vars <- c(
    "RecordType", "Survey", "Quarter", "Country", "Ship", "Gear",
    "SweepLngt", "GearEx", "DoorType", "StNo", "HaulNo", "Year",
    "Month", "Day", "TimeShot", "DepthStratum", "HaulDur",
    "DayNight", "ShootLat", "ShootLong", "HaulLat", "HaulLong",
    "StatRec", "Depth", "HaulVal", "HydroStNo", "StdSpecRecCode",
    "BySpecRecCode", "DataType", "Netopening", "Rigging",
    "Tickler", "Distance", "Warplngt", "Warpdia", "WarpDen",
    "DoorSurface", "DoorWgt", "DoorSpread", "WingSpread",
    "Buoyancy", "KiteDim", "WgtGroundRope", "TowDir",
    "GroundSpeed", "SpeedWater", "SurCurDir", "SurCurSpeed",
    "BotCurDir", "BotCurSpeed", "WindDir", "WindSpeed",
    "SwellDir", "SwellHeight", "SurTemp", "BotTemp", "SurSal",
    "BotSal", "ThermoCline", "ThClineDepth", "CodendMesh",
    "SecchiDepth", "Turbidity", "TidePhase", "TideSpeed",
    "PelSampType", "MinTrawlDepth", "MaxTrawlDepth",
    "SurveyIndexArea", "DateofCalculation"
  )

  HL_vars <- c(
    "RecordType", "Survey", "Quarter", "Country", "Ship", "Gear",
    "SweepLngt", "GearEx", "DoorType", "StNo", "HaulNo", "Year",
    "SpecCodeType", "SpecCode", "SpecVal", "Sex", "TotalNo",
    "CatIdentifier", "NoMeas", "SubFactor", "SubWgt", "CatCatchWgt",
    "LngtCode", "LngtClas", "HLNoAtLngt", "DevStage", "LenMeasType",
    "Valid_Aphia", "ScientificName_WoRMS", "DateofCalculation"
  )

  # Keep only the matching columns that exist
  x$CA <- x$CA[ intersect(CA_vars, names(x$CA)) ]
  x$HH <- x$HH[ intersect(HH_vars, names(x$HH)) ]
  x$HL <- x$HL[ intersect(HL_vars, names(x$HL)) ]

  return(x)
}
