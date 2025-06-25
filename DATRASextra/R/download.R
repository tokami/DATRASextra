
##' @title Download DATRAS survey information
##'
##' @param surveys surveys
##'
##' @return NULL
##'
##' @importFrom DATRAS downloadExchange
##'
##' @export
downloadDATRAS <- function(surveys = NULL,
                           years = NULL,
                           download.missing.only = TRUE,
                           dir = NULL){

    dir0 <- getwd()

    if(is.null(dir)) dir <- dir0

    ## Years
    if(is.null(years)){
        cur.year <- as.numeric(format(Sys.time(),"%Y"))
        years <- 1966:cur.year
    }


    ## Surveys
    if(is.null(surveys)){
        surveys <- c("BITS", "BTS", "BTS-GSA17", "BTS-VIII", "Can-Mar", "DWS",
                     "DYFS", "EVHOE", "FR-CGFS", "FR-WCGFS", "IE-IAMS",
                     "IE-IGFS", "NIGFS", "NL-BSAS", "NS-IBTS",
                     "NSSS", "PT-IBTS", "ROCKALL", "SCOROC", "SCOWCGFS",
                     "SE-SOUND", "SNS", "SP-ARSA", "SP-NORTH", "SP-PORC",
                     "SWC-IBTS")
        surveys.with.issues <- c("NS-IDPS", "IS-IDPS")
    }



    ## Dowload data for each survey
    for(s in 1:length(surveys)){
        survey <- surveys[s]

        print(paste0("Doing survey: ", survey))

        ## Create directory if doesn't exist
        if(!dir.exists(file.path(dir, survey))) dir.create(file.path(dir, survey))

        ## Download data to directory
        setwd(file.path(dir, survey))
        for (y in 1:length(years)) {
            year <- years[y]
            if (download.missing.only) {
                if (!file.exists(file.path(dir, paste0(survey,"_",year,".zip")))) {
                    tmp <- downloadExchange(survey, year)
                }
            } else {
                tmp <- downloadExchange(survey, year)
            }
        }
    }

    setwd(dir0)

    ## TODO: print some statement where it was downloaded to

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
