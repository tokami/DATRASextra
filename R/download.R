
##' @title Download DATRAS survey information
##'
##' @param surveys NULL
##' @param years NULL
##' @param download.missing.only TRUE
##' @param download.ca TRUE
##' @param use.php FALSE
##' @param dir NULL
##' @param verbose TRUE
##'
##' @return NULL
##'
##' @importFrom DATRAS downloadExchange getDatrasExchange
##' @importFrom icesDatras getSurveyList getSurveyYearList
##'
##' @export
downloadDATRAS <- function(surveys = NULL,
                           years = NULL,
                           download.missing.only = TRUE,
                           download.ca = TRUE,
                           use.php = FALSE,
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
        ## if (.Platform$OS.type == "windows") {
        if (!use.php) {

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
                                                        strict = TRUE,
                                                        download.ca = download.ca)
                        datras_clean <- removeExtraVariables(datras_raw)
                        writeExchange(datras_clean, file.path(dir, survey,
                                                              paste0(survey,"_",year,".zip")))
                    }
                } else {
                    datras_raw <- getDatrasExchange(survey, year, quarters,
                                                    strict = TRUE,
                                                    download.ca = download.ca)
                    datras_clean <- removeExtraVariables(datras_raw)
                    writeExchange(datras_clean,
                                  file.path(dir, survey,
                                            paste0(survey,"_",year,".zip")))
                }
            }

        } else {

            if (!download.ca && verbose) writeLines("Note that this functionality is not yet implemented, php always downloads CA. Consider setting use.php to FALSE.")

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
##' @param paths paths
##' @param years years
##' @param min.file.size Minimum file size in bytes (default: 100KB). Files
##'     below this value will be removed as they will likely cause errors in the
##'     underlying DATRAS functions.
##' @param prune logical; If `TRUE` only core columns are kept (see function
##'     prune which columns are removed).
##' @param verbose print stuff
##'
##' @return NULL
##'
##' @details The zip archives downloaded with dowloadDATRAS are usually between
##'     700KB and 2.5MB dependent on the survey. 100KM is a conservative default
##'     file size to exclude files that might be empty or damaged zip archives.
##'
##' If the whole DATRAS data base is read into R, R might crash due to memory
##' limitations when trying to merge the individual files from multiple surveys.
##' The argument 'prune' allows to get rid of some columns which saves
##' considerable memory before merging all DATRAS files. If some columns that
##' prune removes should be kept consider overwriting prune with your own
##' function code.
##'
##' @importFrom DATRAS downloadExchange
##'
##' @export
readDATRAS <- function(paths,
                       years = NULL,
                       min.file.size = 1e4,
                       prune = FALSE,
                       verbose = TRUE) {

    ## import internal function from DATRAS
    c.DATRASraw <- getFromNamespace("c.DATRASraw", "DATRAS")

    paths0 <- paths

    if (any(dir.exists(paths))) {

        if (!is.null(years)) {

            paths <- dir(paths0,
                         full.names = TRUE)
            paths <- paths[grep("\\.zip$", paths)]
            paths <- paths[sort(unlist(lapply(years,
                                              function(x)
                                                  grep(as.character(x), paths))))]
            ind <- which(file.size(paths) <= min.file.size)
            if(length(ind) > 0 && verbose){
                writeLines(paste0("These files are suspiciously small, are you sure that they were downloaded correctly? They will be removed from the list as they likely give errors. Please check the files or change the 'min.file.size' argument!\n",
                                  paste(paths[ind], collapse = "\n")))
            }
            paths <- paths[file.size(paths) > min.file.size]

            np <- length(paths)
            if(verbose) message("Reading in zip files...")
            if(verbose) pb <- txtProgressBar(min = 0, max = np, style = 3)
            tmp <- vector("list", np)
            for (i in 1:np) {
                invisible(capture.output({
                    tmp[[i]] <- tryCatch({readExchange(paths[i], strict = FALSE)
                    }, error = function(err) {
                        message(paste0("Error with: ", paths[i]))
                        return(NULL)
                    })
                }))
                if (is.null(tmp[[i]]) && verbose) {
                    message(paste0("Error with: ", paths[i]))
                }
                if(verbose) setTxtProgressBar(pb, i)
            }
            if(verbose) close(pb)

            idx <- which(sapply(tmp,is.null))
            if (length(idx) > 0) {
                if (verbose) {
                    message("One or more loaded files are NULL. Removing these. Check your files!")
                }
                tmp <- tmp[-idx]
            }

            removeDuplicatedHaulID <- function(args) {
                x <- lapply(args, function(x) as.character(x$haul.id))
                x2 <- lapply(args, function(x) x[["HH"]]$Survey)
                ind <- which(duplicated(unlist(x)))
                ids <- unlist(x)[ind]
                if (length(ind) > 0) {
                    if(verbose){
                        message(paste0("These hauls are duplicated:\n",
                                       paste(paste0(unlist(x2)[ind],": ",ids),
                                             collapse = "\n")))
                        message("Removing these hauls in order to continue. Please look into these surveys and hauls and find out why they are duplicated!")
                    }
                    args <- lapply(args, function(x) subset(x, !haul.id %in% ids))
                }
                return(args)
            }

            tmp <- removeDuplicatedHaulID(tmp)

            if (prune) {
                if(verbose) message("Pruning files")
                tmp <- lapply(tmp, prune)
            }

            if(verbose) message("Combining files")

            surv0 <- do.call(c.DATRASraw, tmp)

        }else{
            invisible(capture.output({
                surv0 <- readExchangeDir(paths,
                                         pattern = ".zip",
                                         strict = FALSE)
                }))
            }

            } else if (any(file.exists(paths))) {

                paths <- paths[grep("\\.zip$", paths)]
                invisible(capture.output({
                    surv0 <- readExchange(paths, strict = FALSE)
                }))

            }else {

                stop(paste0("Cannot find a file or folder under path: ",
                            paste(paths, collapse = ", ")))

            }

    return(surv0)
}



##' @title Write DATRASraw to Exchange
##'
##' @param x a DATRASraw object
##' @param zipfile name of zip file
##'
##' @return NULL
##'
##' @export
writeExchange <- function(x,
                          zipfile = "DATRAS.zip") {
    stopifnot(inherits(x, "DATRASraw"))

    td <- tempdir()
    csvfile <- file.path(td, "DATRAS.csv")

    con <- file(csvfile, open = "wt", encoding = "UTF-8")
    on.exit({
        ## Only attempt to close if we still hold a connection object
        if (!is.null(con) && inherits(con, "connection")) {
            try(close(con), silent = TRUE)
        }
    }, add = TRUE)

    for (comp in c("HH", "HL", "CA")) {
        if (!comp %in% names(x)) next
        df <- x[[comp]]
        if (is.null(df) || nrow(df) == 0) next

        ## header once per block, then append the rows
        writeLines(paste(names(df), collapse = ","), con)
        write.table(df, con, sep = ",", row.names = FALSE, col.names = FALSE,
                    append = TRUE, na = "", quote = FALSE, eol = "\n")
    }

    ## Flush and close before zipping, then null the handle so on.exit() does nothing
    close(con); con <- NULL

    if (file.exists(zipfile)) unlink(zipfile)
    utils::zip(zipfile, files = csvfile, flags = "-j")

    message("Created zip file: ", zipfile)
    invisible(zipfile)
}




removeExtraVariables <- function(x) {
    stopifnot(inherits(x, "DATRASraw"))


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
