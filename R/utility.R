
## Main functions ----------------------------------------------------------------


##' @title List all surveys in the DATRAS data base
##'
##' @return A vector with survey names.
##'
##' @export
list_surveys <- function() {

    survey_info_full <- get("survey_info", envir = asNamespace("DATRASextra"))

    return(survey_info)
}


##' Load dissolved Natural Earth land polygon
##'
##' If download_map = FALSE, loads a dissolved land polygon shipped with the
##' package (Natural Earth 1:10m), used for offline plotting.
##'
##' @return An sf object (single MULTIPOLYGON) in EPSG:4326.
##' @source Natural Earth via rnaturalearth.
get_land <- function(download_map = FALSE, scale = 50) {

  if (!download_map) {
    path <- system.file("extdata", "land_nea_50m.rds", package = "DATRASextra")
    if (nzchar(path)) return(readRDS(path))
  }

  if (!requireNamespace("rnaturalearth", quietly = TRUE)) {
    stop("To download land polygons, install 'rnaturalearth'.")
  }

  rnaturalearth::ne_download(
    scale = scale, type = "land", category = "physical", returnclass = "sf"
  )
}





## Internal functions ------------------------------------------------------------

.add_class_datras <- function(x) {
  class(x) <- c("datras_raw", "DATRASraw")
  x
}


.check_class_datras <- function(x, strict = FALSE) {
  if (strict) {
    stopifnot(inherits(x, "datras_raw"))
  } else {
    stopifnot(inherits(x, "datras_raw") || inherits(x, "DATRASraw"))
  }
}




map2bar <- function(value, midL, bar.x) {
    if (length(midL) > 1) {
        approx(midL, bar.x, xout = value, rule = 2)$y
    } else {
        midL
    }
}



quarter2months <- function(quarter) ((quarter - 1) * 3 + 1) : (quarter * 3)
