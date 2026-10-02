
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
##' By default (`method = "api"`), data are downloaded from the ICES DATRAS
##' Download API, the service behind `icesDatras::getDatrasUnaggregated()`,
##' and written to disk with [write_datras()]. The previous route,
##' `DATRAS::getDatrasExchange()` on the DATRAS web service, is available as
##' `method = "webservice"`, and the legacy PHP-based route from
##' `DATRAS::downloadExchange()` as `method = "php"`.
##'
##' @param path Character string giving the directory where downloaded files
##'   should be stored. Survey-specific subdirectories are created within this
##'   directory. If `NULL`, the current working directory is used.
##' @param surveys A character vector of DATRAS survey names to download, for
##'   example `"NS-IBTS"` or `"BITS"`. If `NULL`, all available surveys are
##'   used.
##' @param years An integer vector of years to download. If `NULL`, all
##'   available years for each selected survey are used.
##' @param overwrite Logical. If `FALSE` (default), survey-year files that
##'   already exist in `path` are skipped. Set to `TRUE` to re-download and
##'   overwrite existing files.
##' @param download_hl Logical. If `TRUE` (default), length-frequency data are
##'   also downloaded where available. This option is not used when `method =
##'   "php"`.
##' @param download_ca Logical. If `TRUE` (default), age-length keys and age
##'   data are also downloaded where available. This option is not used when
##'   `method = "php"`.
##' @param method Character string naming the download route: `"api"`
##'   (default) for the ICES DATRAS Download API, `"webservice"` for
##'   `DATRAS::getDatrasExchange()`, or `"php"` for the legacy
##'   `DATRAS::downloadExchange()`. See Details.
##' @param use_php Logical. Kept for backward compatibility: `use_php = TRUE` is
##'   the same as `method = "php"`. Default is `FALSE`.
##' @param years_per_request Integer. With `method = "api"`, the maximum number
##'   of years fetched in one request per record type. Larger values mean fewer
##'   requests but more memory for large surveys. Default is 10.
##' @param include_flagged Logical. If `FALSE` (default), known test surveys are
##'   skipped when the survey list is taken from the server. Set to `TRUE` to
##'   download them anyway.
##' @param return_data Logical. If `TRUE` (default), the function returns the
##'   downloaded data by running `read_datras()` on the specified path.
##' @param strict Logical. Passed to [read_datras()] when `return_data = TRUE`,
##'   and ignored otherwise. Controls how records in `CA` without a haul
##'   identifier are matched back to a haul: if `TRUE` (default), a record
##'   matching several candidate hauls is left as `NA`; if `FALSE`, it is
##'   assigned one of them at random. It does not affect the files written to
##'   disk, which always hold the exchange data as delivered by ICES.
##' @param verbose Logical. If `TRUE` (default), progress messages are printed.
##' @param timeout Numeric. Maximum number of seconds to wait for the ICES
##'   DATRAS server to respond when retrieving the list of available surveys or
##'   years. If the server does not respond within this time (e.g. because a
##'   firewall blocks the connection), the function falls back to locally cached
##'   information. Default is 10 seconds.
##' @param ... Additional arguments for the function `read_datras()`, used when
##'   `return_data = TRUE`. The most useful ones control how much is held in
##'   memory: `prune = TRUE` drops non-essential columns, `drop_hl = TRUE` and
##'   `drop_ca = TRUE` omit the length-frequency and biological tables from the
##'   returned object, and `ncores` sets the number of workers used to read the
##'   files. None of them affect what is written to disk. See [read_datras()]
##'   for the full list.
##'
##' @details
##' Files are saved as zipped exchange files named
##' `"<survey>_<year>.zip"` inside survey-specific subfolders, whichever
##' `method` is used.
##'
##' `method = "api"` is considerably faster than `method = "webservice"`. It
##' fetches several years and all quarters in one request per record type
##' (`HH`, `HL`, `CA`) and receives a zipped CSV file, where the web service
##' needs one XML request per record type, year and quarter plus several
##' availability checks. The API delivers the new ICES field names; they are
##' mapped back to the exchange names so that the files are the same in layout
##' whichever route wrote them. Values are written as delivered by ICES, read as
##' text so that codes such as ICES rectangle `"37E9"` are kept exactly.
##' Missing values (`-9`) are written as empty fields, as with `method =
##' "webservice"`, so that both routes give the same haul identifiers.
##'
##' The following surveys are treated as test surveys and are skipped unless
##' `include_flagged = TRUE`: `"Test-DATRAS"` and `"NS-IBTS_UNIFtest"`. The
##' filter applies only when `surveys` is `NULL`, i.e. when the survey list is
##' taken from the DATRAS server; a survey named explicitly is always
##' downloaded.
##'
##' Each downloaded survey-year is recorded in an archive manifest,
##' `DATRAS_manifest.csv`, written in the root of `path`. The manifest holds the
##' extraction date, the checksum of each exchange file, the ICES calculation
##' date of the records it contains, and the package versions used, so that a
##' snapshot can later be verified with [verify_extraction()] and so that data
##' read from the archive can report where they came from. Existing manifest
##' entries for the same survey, year and quarter are replaced.
##'
##' Downloading a large part of the database and returning it in one call can
##' exhaust memory, because every survey-year is read back into a single object.
##' Either set `return_data = FALSE` and read the archive in pieces afterwards,
##' or pass the memory-reducing arguments of [read_datras()] through `...`, for
##' example `prune = TRUE` and `drop_ca = TRUE`.
##'
##' Survey-year-quarters that have hauls but no length data (`HL`) at all are
##' listed in a warning. Their hauls would otherwise be read as empty hauls
##' with zero catch; DATRAS holds a few such cases, for example test entries
##' (see <https://github.com/ices-tools-prod/icesDatras/issues/59>). The files
##' are still written as delivered; remove the cases from an analysis with
##' `clean_datras(drop_without_hl = TRUE)`. The check needs `download_hl =
##' TRUE` and is not made with `method = "php"`.
##'
##' No manifest entries are written when `method = "php"`, because
##' `DATRAS::downloadExchange()` writes the files through an external script and
##' reports nothing about what it retrieved. Run [write_manifest()] on the
##' directory afterwards to describe such an archive.
##'
##' @return Invisibly returns `NULL`.
##'
##' @seealso [read_datras()], [write_manifest()], [verify_extraction()],
##'   [extraction()]
##'
##' @importFrom DATRAS downloadExchange getDatrasExchange
##' @importFrom utils URLencode
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
##'   path = "data/datras"
##' )
##'
##' ## Re-download existing files
##' dat <- download_datras(
##'   surveys = "NS-IBTS",
##'   years = 2020,
##'   overwrite = TRUE
##' )
##' }
##'
##' @export
download_datras <- function(path = NULL,
                            surveys = NULL,
                            years = NULL,
                            overwrite = FALSE,
                            download_hl = TRUE,
                            download_ca = TRUE,
                            method = c("api", "webservice", "php"),
                            use_php = FALSE,
                            years_per_request = 10,
                            include_flagged = FALSE,
                            return_data = TRUE,
                            strict = TRUE,
                            verbose = TRUE,
                            timeout = 10,
                            ...) {

  method <- match.arg(method)
  if (isTRUE(use_php)) method <- "php"

  dir0 <- getwd()
  on.exit(setwd(dir0), add = TRUE)

  if (is.null(path)) path <- dir0

  ## Resolve path to an absolute path now, before any setwd() calls change
  ## the working directory and make relative paths ambiguous.
  path <- normalizePath(path.expand(path), mustWork = FALSE)

  ## Surveys
  if (is.null(surveys)) {
    surveys <- .get_survey_list(timeout = timeout)
    ## Test surveys only. "NS-IDPS" and "IS-IDPS" were listed here previously
    ## but are real surveys - the Norwegian Sea and Irminger Sea International
    ## Deep Pelagic Surveys - so they are downloaded like any other.
    surveys_with_issues <- c("Test-DATRAS", "NS-IBTS_UNIFtest")

    ind <- which(surveys %in% surveys_with_issues)
    if (length(ind) > 0 && !isTRUE(include_flagged)) {
      message("These surveys are test surveys and will not be downloaded: ", paste(surveys[ind], collapse = ", "), ". Please use include_flagged = TRUE if you want to download these surveys.")
      surveys <- surveys[-ind]
    }
  }

  ## Pre-flight: verify all target directories are writable before downloading
  for (survey in surveys) {
    survey_dir <- file.path(path, survey)
    if (!dir.exists(survey_dir)) {
      ok <- dir.create(survey_dir, recursive = TRUE, showWarnings = FALSE)
      if (!ok) stop("Cannot create output directory: ", survey_dir,
                    "\nPlease check that the path exists and is writable.")
    } else {
      test_path <- file.path(survey_dir, ".write_test")
      ok <- tryCatch({writeLines("", test_path); TRUE}, error = function(e) FALSE)
      if (ok) unlink(test_path) else
        stop("Output directory is not writable: ", survey_dir)
    }
  }

  ## Extraction records, accumulated across surveys and merged into the archive
  ## manifest once all downloads have finished.
  ext_rows <- list()

  ## Survey-year-quarters with hauls but no length data, reported at the end
  no_hl <- list()

  ## Download data for each survey
  for (s in seq_along(surveys)) {
    survey <- surveys[s]

    print(paste0("Doing survey: ", survey))

    setwd(file.path(path, survey))

    ## Per-survey year list. Kept in its own variable: `years` is the user's
    ## request and must survive the loop intact, so that the archive is read
    ## back with the filter that was asked for and not with the year coverage
    ## of whichever survey happened to be downloaded last.
    survey_years <- .get_survey_year_list(survey, path, years, timeout = timeout)

    if (method == "api") {

      ## Years still to fetch, in contiguous runs of at most years_per_request
      ## years, so that each run is one request per record type.
      todo <- survey_years[overwrite | !file.exists(
        file.path(path, survey, paste0(survey, "_", survey_years, ".zip")))]

      for (chunk in .year_chunks(todo, years_per_request)) {
        if (verbose) message("Downloading ", survey, " ", .year_range(chunk))
        extracted_at <- Sys.time()
        tabs <- list(HH = .datras_download_api("HH", survey, chunk))
        if (download_hl) tabs$HL <- .datras_download_api("HL", survey, chunk)
        if (download_ca) tabs$CA <- .datras_download_api("CA", survey, chunk)
        no_hl[[length(no_hl) + 1L]] <- .groups_without_hl(tabs)

        for (year in chunk) {
          x <- lapply(tabs, function(d) d[d$Year == year, , drop = FALSE])
          if (nrow(x$HH) == 0) next
          x <- .remove_extra_variables(.add_class_datras(x))

          zip_path <- file.path(path, survey, paste0(survey, "_", year, ".zip"))
          zp <- write_datras(x, zip_path)

          ext_rows[[length(ext_rows) + 1L]] <- .extraction_record(
            x,
            extracted = extracted_at,
            source = "download_api",
            endpoint = .datras_download_endpoint(),
            file = file.path(survey, basename(zip_path)),
            payload_hash = attr(zp, "payload_hash"),
            zip_hash = attr(zp, "zip_hash"),
            algo = attr(zp, "algo")
          )
        }
      }

    } else if (method == "webservice") {

      for (y in seq_along(survey_years)) {
        year <- survey_years[y]

        zip_path <- file.path(path, survey, paste0(survey, "_", year, ".zip"))
        if (!overwrite && file.exists(zip_path)) next

        quarters <- .get_survey_year_quarter_list(survey, year, timeout = timeout)
        extracted_at <- Sys.time()
        ## strict is fixed here, not taken from the argument: it only sets
        ## the derived haul.id column, which .remove_extra_variables() drops
        ## before writing, so the archived file is the same either way. Using
        ## strict = FALSE would call sample() for no gain. The user-facing
        ## strict argument applies when the archive is read back below.
        datras_raw <- DATRAS::getDatrasExchange(survey, year, quarters,
                                                strict = TRUE,
                                                download.hl = download_hl,
                                                download.ca = download_ca)
        datras_raw <- .add_class_datras(datras_raw)
        datras_clean <- .remove_extra_variables(datras_raw)
        no_hl[[length(no_hl) + 1L]] <- .groups_without_hl(datras_raw)
        zp <- write_datras(datras_clean, zip_path)

        ext_rows[[length(ext_rows) + 1L]] <- .extraction_record(
          datras_raw,
          extracted = extracted_at,
          source = "api",
          endpoint = .datras_endpoint(),
          file = file.path(survey, basename(zip_path)),
          payload_hash = attr(zp, "payload_hash"),
          zip_hash = attr(zp, "zip_hash"),
          algo = attr(zp, "algo")
        )
      }

    } else {

      if ((!download_hl || !download_ca) && verbose) message("Note that this functionality is not yet implemented, php always downloads HL and CA. Consider using method = \"api\".")

      if (!overwrite) {
        for (y in seq_along(survey_years)) {
          year <- survey_years[y]
          zip_path <- file.path(path, survey, paste0(survey, "_", year, ".zip"))
          if (file.exists(zip_path)) next

          tmp <- DATRAS::downloadExchange(survey, year)
        }
      } else {
        tmp <- DATRAS::downloadExchange(survey, survey_years)
      }

    }
  }

  ## The files are written as delivered; this only reports the cases.
  no_hl <- do.call(rbind, no_hl)
  if (!is.null(no_hl) && nrow(no_hl) > 0) {
    warning("These survey-year-quarters have hauls but no length data (HL), ",
            "so their hauls would be read as empty hauls with zero catch:\n",
            .format_groups_without_hl(no_hl),
            "\nThey may be test entries left in DATRAS. Remove them with ",
            "clean_datras(drop_without_hl = TRUE), and consider reporting them ",
            "to datrasadministration@ices.dk.", call. = FALSE)
  }

  ## Record the extraction in the archive manifest. The php route writes files
  ## through an external script, so nothing is known about them here; the
  ## manifest is rebuilt from the files on disk instead.
  if (length(ext_rows) > 0) {
    .update_manifest(path, ext_rows, verbose = verbose)
  }

  if(verbose) message("Survey information has been downloaded and saved in folder for each survey at: ", path)

  if (isTRUE(return_data)) {
    dat <- read_datras(path = path, surveys = surveys, years = years,
                       strict = strict, ...)
    return(dat)
  } else {
    return(invisible(path))
  }
}





## Internal functions -----------------------------------------------------


## Attempt to fetch the survey list from the DATRAS API; fall back to a cached
## list when offline or when the server does not respond within `timeout` seconds.
.get_survey_list <- function(timeout = 10) {
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  tryCatch({
    setTimeLimit(elapsed = timeout, transient = TRUE)
    .datras_api_get("getSurveyList", tag = "Survey")
  }, error = function(e) {
    message("Could not reach DATRAS server within ", timeout,
            " seconds - using cached survey list. (Consider increasing timeout).")
    c("BITS", "BTS", "BTS-GSA17", "BTS-VIII", "Can-Mar", "CODS-Q4",
      "DWS", "DYFS", "EVHOE", "FR-CGFS", "FR-WCGFS", "IE-IAMS",
      "IE-IGFS", "IS-IDPS", "NIGFS", "NL-BSAS", "NS-IBTS",
      "NS-IBTS_UNIFtest", "NS-IDPS", "NSSS", "PT-IBTS", "ROCKALL",
      "SCOROC", "SCOWCGFS", "SE-SOUND", "SNS", "SP-ARSA", "SP-NORTH",
      "SP-PORC", "SWC-IBTS", "Test-DATRAS")
  })
}


## Attempt to fetch available years from the DATRAS API; fall back to years
## inferred from locally present zip files when offline or when the server does
## not respond within `timeout` seconds.  yearsin, if non-NULL, is applied as a
## filter in both the online and offline paths.
.get_survey_year_list <- function(survey, dir, yearsin = NULL, timeout = 10) {
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  years <- tryCatch({
    setTimeLimit(elapsed = timeout, transient = TRUE)
    as.integer(.datras_api_get("getSurveyYearList",
                               paste0("survey=",
                                      URLencode(survey, reserved = TRUE)),
                               tag = "Year"))
  }, error = function(e) {
    files <- list.files(file.path(dir, survey),
                        pattern = paste0("^", survey, "_[0-9]{4}\\.zip$"))
    if (length(files) == 0)
      stop("Could not reach DATRAS server and no local files found for survey '",
           survey, "' in '", file.path(dir, survey), "'.")
    message("Could not reach DATRAS server within ", timeout,
            " seconds - inferring available years from local files for ",
            survey, ". (Consider increasing timeout).")
    as.integer(sub(paste0("^", survey, "_([0-9]{4})\\.zip$"), "\\1", files))
  })
  if (!is.null(yearsin)) years <- years[years %in% yearsin]
  years
}


## Attempt to fetch available quarters from the DATRAS API; fall back to 1:4
## when offline or when the server does not respond within `timeout` seconds.
.get_survey_year_quarter_list <- function(survey, year, timeout = 10) {
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  tryCatch({
    setTimeLimit(elapsed = timeout, transient = TRUE)
    as.integer(.datras_api_get("getSurveyYearQuarterList",
                               paste0("survey=",
                                      URLencode(survey, reserved = TRUE),
                                      "&year=", year),
                               tag = "Quarter"))
  }, error = function(e) {
    message("Could not reach DATRAS server within ", timeout,
            " seconds - falling back to all quarters 1:4 for ",
            survey, " ", year, ". (Consider increasing timeout).")
    1:4
  })
}


## Make a GET request to the ICES DATRAS web service and return the values of
## `tag` elements from the XML response as a character vector.  The service pads
## some values to a fixed width (e.g. "EVHOE     "), so values are trimmed and
## any that are empty afterwards are dropped.
.datras_api_get <- function(endpoint, query = "", tag) {
  base <- "https://datras.ices.dk/WebServices/DATRASWebService.asmx/"
  addr <- if (nchar(query) > 0) paste0(base, endpoint, "?", query) else paste0(base, endpoint)
  con <- url(addr)
  on.exit(close(con), add = TRUE)
  txt <- paste(readLines(con, warn = FALSE), collapse = "")
  m <- gregexpr(paste0("(?<=<", tag, ">)[^<]+"), txt, perl = TRUE)
  vals <- trimws(regmatches(txt, m)[[1]])
  vals[nzchar(vals)]
}


## Download one record type for a survey and a contiguous run of years from the
## ICES DATRAS Download API, the service behind
## icesDatras::getDatrasUnaggregated(), and return it with exchange names.
## The CSV is read as text: type guessing would turn ICES rectangles such as
## "37E9" into numbers and drop leading zeros, and icesDatras' own typing
## truncates the HL numbers at length to integers.
.datras_download_api <- function(recordtype, survey, years, quarters = "1:4") {
  addr <- paste0(.datras_download_endpoint(),
                 "?recordtype=", recordtype,
                 "&survey=", URLencode(survey, reserved = TRUE),
                 "&year=", .year_range(years, sep = ":"),
                 "&quarter=", quarters)

  zipfile <- tempfile(fileext = ".zip")
  exdir <- tempfile("datras_api_")
  on.exit(unlink(c(zipfile, exdir), recursive = TRUE), add = TRUE)

  ## Large HL files can take longer than R's default 60 second timeout
  op <- options(timeout = max(3600, getOption("timeout")))
  on.exit(options(op), add = TRUE)

  ok <- tryCatch(utils::download.file(addr, zipfile, mode = "wb", quiet = TRUE) == 0,
                 error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok || !file.exists(zipfile)) {
    stop("Could not download ", recordtype, " data for ", survey, " ",
         .year_range(years), " from the DATRAS Download API:\n", addr)
  }

  csv <- tryCatch(utils::unzip(zipfile, exdir = exdir), error = function(e) character(0))
  csv <- csv[basename(csv) == "DATRASDataTable.csv"]
  if (length(csv) == 0) {
    stop("The DATRAS Download API returned no data file for ", recordtype, " ",
         survey, " ", .year_range(years), ":\n", addr)
  }

  .datras_api_to_exchange(.read_download_api_csv(csv[1]), recordtype)
}


## Read a Download API CSV file with every column as text. The header is read
## separately because the HH header lists EDOM and ReasonHaulDisruption while
## the data rows do not hold them; reading with the header as is would shift
## DateofCalculation into EDOM. Any other mismatch is an error rather than a
## silent shift of columns.
.read_download_api_csv <- function(file) {

  ## The file starts with a byte order mark
  con <- file(file, encoding = "UTF-8-BOM")
  header <- trimws(strsplit(readLines(con, n = 1, warn = FALSE), ",", fixed = TRUE)[[1]])
  close(con)

  empty <- as.data.frame(stats::setNames(rep(list(character(0)), length(header)), header),
                         check.names = FALSE, stringsAsFactors = FALSE)
  d <- tryCatch(
    utils::read.table(file, header = FALSE, skip = 1, sep = ",", quote = "\"",
                      colClasses = "character", na.strings = "",
                      comment.char = "", fileEncoding = "UTF-8-BOM"),
    error = function(e) {
      if (grepl("no lines available", conditionMessage(e))) return(empty)
      stop(e)
    })
  if (nrow(d) == 0) return(empty)

  if (ncol(d) != length(header)) {
    absent <- intersect(c("EDOM", "ReasonHaulDisruption"), header)
    if (length(header) - ncol(d) != length(absent)) {
      stop("The DATRAS Download API file has ", length(header),
           " columns in its header but ", ncol(d), " in its rows: ", file)
    }
    header <- setdiff(header, absent)
  }
  names(d) <- header
  d
}


.datras_download_endpoint <- function() {
  "https://datras.ices.dk/Data_products/Download/DATRASDownloadAPI.aspx"
}


## Rename the fields of the Download API to the DATRAS exchange names and blank
## the -9 codes for missing values. The map was built from
## icesDatras::getDatrasFieldList(), with three corrections: the
## list gives "-" as the old name of Survey, CA uses AphiaID rather than
## ValidAphiaID, and its count column already arrives as CANoAtLngt. Fields
## without an exchange name (e.g. EDOM, ReasonHaulDisruption) are kept here and
## dropped later by .remove_extra_variables().
.datras_api_to_exchange <- function(d, recordtype) {
  common <- c(
    RecordHeader = "RecordType", Platform = "Ship", SweepLength = "SweepLngt",
    GearExceptions = "GearEx", StationName = "StNo", HaulNumber = "HaulNo"
  )
  map <- switch(recordtype,
    HH = c(common,
      StartTime = "TimeShot", HaulDuration = "HaulDur",
      ShootLatitude = "ShootLat", ShootLongitude = "ShootLong",
      HaulLatitude = "HaulLat", HaulLongitude = "HaulLong",
      StatisticalRectangle = "StatRec", BottomDepth = "Depth",
      HaulValidity = "HaulVal", HydrographicStationID = "HydroStNo",
      StandardSpeciesCode = "StdSpecRecCode", BycatchSpeciesCode = "BySpecRecCode",
      NetOpening = "Netopening", WarpLength = "Warplngt",
      WarpDiameter = "Warpdia", WarpDensity = "WarpDen",
      DoorWeight = "DoorWgt", KiteArea = "KiteDim",
      GroundRopeWeight = "WgtGroundRope", TowDirection = "TowDir",
      SpeedGround = "GroundSpeed",
      SurfaceCurrentDirection = "SurCurDir", SurfaceCurrentSpeed = "SurCurSpeed",
      BottomCurrentDirection = "BotCurDir", BottomCurrentSpeed = "BotCurSpeed",
      WindDirection = "WindDir", SwellDirection = "SwellDir",
      SurfaceTemperature = "SurTemp", BottomTemperature = "BotTemp",
      SurfaceSalinity = "SurSal", BottomSalinity = "BotSal",
      ThermoClineDepth = "ThClineDepth", PelagicSamplingType = "PelSampType"),
    HL = c(common,
      SpeciesCodeType = "SpecCodeType", SpeciesCode = "SpecCode",
      SpeciesValidity = "SpecVal", SpeciesSex = "Sex",
      TotalNumber = "TotalNo", SpeciesCategory = "CatIdentifier",
      SubsampledNumber = "NoMeas", SubsamplingFactor = "SubFactor",
      SubsampleWeight = "SubWgt", SpeciesCategoryWeight = "CatCatchWgt",
      LengthCode = "LngtCode", LengthClass = "LngtClas",
      NumberAtLength = "HLNoAtLngt", DevelopmentStage = "DevStage",
      LengthType = "LenMeasType", ValidAphiaID = "Valid_Aphia"),
    CA = c(common,
      SpeciesCodeType = "SpecCodeType", SpeciesCode = "SpecCode",
      LengthCode = "LngtCode", LengthClass = "LngtClas",
      IndividualSex = "Sex", IndividualMaturity = "Maturity",
      AgePlusGroup = "PlusGr", IndividualAge = "Age",
      CANoAtLngt = "NoAtALK", NumberAtLength = "NoAtALK",
      IndividualWeight = "IndWgt", GeneticSamplingFlag = "GenSamp",
      StomachSamplingFlag = "StomSamp", AgePreparationMethod = "AgePrepMet",
      OtolithGrading = "OtGrading", ParasiteSamplingFlag = "ParSamp",
      AphiaID = "Valid_Aphia", ValidAphiaID = "Valid_Aphia"),
    stop("recordtype must be one of 'HH', 'HL' or 'CA'")
  )
  i <- match(names(d), names(map))
  names(d)[!is.na(i)] <- map[i[!is.na(i)]]

  ## Write missing values as empty fields, as the web service route does after
  ## DATRAS::minus9toNA(). Kept as -9, DATRAS would read them as NA, and a
  ## missing StNo would then give haul ids such as "BTS:2022:1:GB:74E9:BT4P:NA:5"
  ## instead of the "...:BT4P::5" of archives written by the web service route.
  ## The codes are those DATRAS reads as NA (na.strings of DATRAS:::readICES).
  d[] <- lapply(d, function(v) {
    v[v %in% c("-9", "-9.0", "-9.00", "-9.0000")] <- NA_character_
    v
  })
  d
}


## Split years into contiguous runs of at most `size` years.
.year_chunks <- function(years, size = 10) {
  years <- sort(unique(as.integer(years)))
  if (length(years) == 0) return(list())
  run <- cumsum(c(1, diff(years) != 1))
  out <- lapply(split(years, run), function(y) split(y, ceiling(seq_along(y) / size)))
  unname(unlist(out, recursive = FALSE))
}


## "2015-2022" for messages, "2015:2022" for the Download API.
.year_range <- function(years, sep = "-") {
  if (length(years) == 1) return(as.character(years))
  paste0(min(years), sep, max(years))
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
