
## Main functions ----------------------------------------------------------------


##' Download ICES DATRAS survey data
##'
##' Download ICES DATRAS survey data for one or more surveys and years, and save
##' each survey-year combination as a zipped exchange file in a survey-specific
##' subdirectory.
##'
##' If `surveys` is `NULL`, all available surveys returned by
##' `icesDatras::getSurveyList()` are used. If `years` is `NULL`, all available
##' years for each selected survey are downloaded.
##'
##' By default, data are downloaded using `DATRAS::getDatrasExchange()`, cleaned
##' to remove extra variables, and written to disk with [write_exchange()].
##' Alternatively, the legacy PHP-based download route from
##' `DATRAS::downloadExchange()` can be used by setting `use_php = TRUE`.
##'
##' @param surveys A character vector of DATRAS survey names to download, for
##'   example `"NS-IBTS"` or `"BITS"`. If `NULL`, all available surveys are
##'   used.
##' @param years An integer vector of years to download. If `NULL`, all
##'   available years for each selected survey are used.
##' @param download_missing_only Logical. If `TRUE` (default), only survey-year
##'   files that do not already exist in `dir` are downloaded.
##' @param download_hl Logical. If `TRUE` (default), length-frequency data are
##'   also downloaded where available. This option is only used when `use_php =
##'   FALSE`.
##' @param download_ca Logical. If `TRUE` (default), age-length keys and age
##'   data are also downloaded where available. This option is only used when
##'   `use_php = FALSE`.
##' @param use_php Logical. If `FALSE` (default), data are downloaded via
##'   `DATRAS::getDatrasExchange()`. If `TRUE`, the legacy
##'   `DATRAS::downloadExchange()` method is used.
##' @param dir Character string giving the directory where downloaded files
##'   should be stored. Survey-specific subdirectories are created within this
##'   directory. If `NULL`, the current working directory is used.
##' @param force Logical. If `FALSE` (default), surveys known to be test surveys
##'   or surveys with incomplete data may be skipped. If `TRUE`, they are also
##'   downloaded.
##' @param return_data Logical. If `TRUE` (default), the function returns the
##'   downloaded data by running `read_datras()` on the specified path.
##' @param verbose Logical. If `TRUE` (default), progress messages are printed.
##' @param ... Additional arguments for the function `read_datras()`.
##'
##' @details
##' Files are saved as zipped exchange files named
##' `"<survey>_<year>.zip"` inside survey-specific subfolders.
##'
##' The following surveys are currently treated as problematic or test surveys:
##' `"NS-IDPS"`, `"IS-IDPS"`, `"Test-DATRAS"`, and `"NS-IBTS_UNIFtest"`.
##'
##' @return Invisibly returns `NULL`.
##'
##' @importFrom DATRAS downloadExchange getDatrasExchange
##' @importFrom icesDatras getSurveyList getSurveyYearList getSurveyYearQuarterList
##'
##' @examples
##' \dontrun{
##' ## Download all available years for one survey into the current directory
##' dat <- download_datras(surveys = "NS-IBTS")
##'
##' ## Download selected years for multiple surveys
##' dat <- download_datras(
##'   surveys = c("NS-IBTS", "BITS"),
##'   years = 2010:2012,
##'   dir = "data/datras"
##' )
##'
##' ## Re-download existing files
##' dat <- download_datras(
##'   surveys = "NS-IBTS",
##'   years = 2020,
##'   download_missing_only = FALSE
##' )
##' }
##'
##' @export
download_datras <- function(surveys = NULL,
                            years = NULL,
                            download_missing_only = TRUE,
                            download_hl = TRUE,
                            download_ca = TRUE,
                            use_php = FALSE,
                            dir = NULL,
                            force = FALSE,
                            return_data = TRUE,
                            verbose = TRUE,
                            ...) {

  yearsin <- years

  dir0 <- getwd()
  on.exit(setwd(dir0), add = TRUE)

  if(is.null(dir)) dir <- dir0

  ## Surveys
  if (is.null(surveys)) {
    surveys <- .get_survey_list()
  }
  surveys_with_issues <- c("NS-IDPS", "IS-IDPS",
                           "Test-DATRAS", "NS-IBTS_UNIFtest")

  ind <- which(surveys %in% surveys_with_issues)
  if (length(ind) > 0 && !isTRUE(force)) {
    message("These surveys are test surveys or do not contain all required data and will not be downloaded: ", paste(surveys[ind], collapse = ", "), " Please use force=TRUE if you want to download these surveys.")
    surveys <- surveys[-ind]
  }

  ## Dowload data for each survey
  for (s in seq_along(surveys)) {
    survey <- surveys[s]

    print(paste0("Doing survey: ", survey))

    ## Create directory if doesn't exist
    if (!dir.exists(file.path(dir, survey))) dir.create(file.path(dir, survey))

    ## Download data to directory
    setwd(file.path(dir, survey))

    ## if (.Platform$OS.type == "windows") {
    if (!use_php) {

      years <- .get_survey_year_list(survey, dir, yearsin)
      for (y in seq_along(years)) {
        year <- years[y]
        zip_path <- file.path(dir, survey, paste0(survey, "_", year, ".zip"))

        if (download_missing_only && file.exists(zip_path)) next

        quarters <- icesDatras::getSurveyYearQuarterList(survey, year)
        datras_raw <- DATRAS::getDatrasExchange(survey, year, quarters,
                                                strict = TRUE,
                                                download.hl = download_hl,
                                                download.ca = download_ca)
        datras_raw <- .add_class_datras(datras_raw)
        datras_clean <- .remove_extra_variables(datras_raw)
        write_exchange(datras_clean, zip_path)
      }

    } else {

      if ((!download_hl || !download_ca) && verbose) message("Note that this functionality is not yet implemented, php always downloads HL and CA. Consider setting use_php = FALSE.")

      if (download_missing_only) {
        years <- .get_survey_year_list(survey, dir, yearsin)
        for (y in seq_along(years)) {
          year <- years[y]
          if (!file.exists(file.path(dir, survey,
                                     paste0(survey, "_", year, ".zip")))) {
            tmp <- DATRAS::downloadExchange(survey, year)
          }
        }
      } else {
        years <- if (!is.null(yearsin)) yearsin else icesDatras::getSurveyYearList(survey)
        tmp <- DATRAS::downloadExchange(survey, years)
      }

    }
  }

  if(verbose) message("Survey information has been downloaded and saved in folder for each survey at: ", dir)

  if (isTRUE(return_data)) {
    dat <- read_datras(paths = dir, surveys = surveys, years = years, ...)
    return(dat)
  } else {
    return(invisible(dir))
  }
}





## Internal functions -----------------------------------------------------


## Attempt icesDatras::getSurveyList(); fall back to a cached list when offline.
.get_survey_list <- function() {
  tryCatch(
    icesDatras::getSurveyList(),
    error = function(e) {
      message("No internet connection — using cached survey list.")
      c("BITS", "BTS", "BTS-GSA17", "BTS-VIII", "Can-Mar", "CODS-Q4",
        "DWS", "DYFS", "EVHOE", "FR-CGFS", "FR-WCGFS", "IE-IAMS",
        "IE-IGFS", "IS-IDPS", "NIGFS", "NL-BSAS", "NS-IBTS",
        "NS-IBTS_UNIFtest", "NS-IDPS", "NSSS", "PT-IBTS", "ROCKALL",
        "SCOROC", "SCOWCGFS", "SE-SOUND", "SNS", "SP-ARSA", "SP-NORTH",
        "SP-PORC", "SWC-IBTS", "Test-DATRAS")
    }
  )
}


## Attempt icesDatras::getSurveyYearList(); fall back to years inferred from
## locally present zip files when offline.  yearsin, if non-NULL, is applied as
## a filter in both the online and offline paths.
.get_survey_year_list <- function(survey, dir, yearsin = NULL) {
  years <- tryCatch(
    icesDatras::getSurveyYearList(survey),
    error = function(e) {
      files <- list.files(file.path(dir, survey),
                          pattern = paste0("^", survey, "_[0-9]{4}\\.zip$"))
      if (length(files) == 0)
        stop("No internet connection and no local files found for survey '",
             survey, "' in '", file.path(dir, survey), "'.")
      message("No internet connection — inferring years from local files for ", survey)
      as.integer(sub(paste0("^", survey, "_([0-9]{4})\\.zip$"), "\\1", files))
    }
  )
  if (!is.null(yearsin)) years <- years[years %in% yearsin]
  years
}


.remove_extra_variables <- function(x) {
  stopifnot(inherits(x, "datras_raw"))


  ## Define the official names for each component
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

  ## Keep only the matching columns that exist
  x[["CA"]] <- x[["CA"]][ intersect(CA_vars, names(x[["CA"]])) ]
  x[["HH"]] <- x[["HH"]][ intersect(HH_vars, names(x[["HH"]])) ]
  x[["HL"]] <- x[["HL"]][ intersect(HL_vars, names(x[["HL"]])) ]

  for(i in c("CA","HH","HL")){
    if(!is.null(x[[i]])) {
      colnames(x[[i]])[colnames(x[[i]]) == "LngtClas"] <- "LngtClass"
      colnames(x[[i]])[colnames(x[[i]]) == "Valid_Aphia"] <- "ValidAphiaID"
      colnames(x[[i]])[colnames(x[[i]]) == "Age"] <- "AgeRings"
      colnames(x[[i]])[colnames(x[[i]]) == "NoAtALK"] <- "CANoAtLngt"
    }
  }

  return(x)
}
