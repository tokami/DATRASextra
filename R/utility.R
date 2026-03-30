
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
##' package (Natural Earth 1:50m), used for offline plotting.
##'
##' @param download_map Logical. If `FALSE` the download map included in
##'   DATRASextra is used for plotting (with 1:50m scale). If `TRUE`, a map is
##'   downloaded with [rnaturalearth::ne_download()] and the specified scale.
##' @param scale Scale of the map to be downloaded by
##'   [rnaturalearth::ne_download()]. (Only used if download_map = TRUE).
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

.cols_datrasextra <- function(n) {

  if (length(n) != 1L || is.na(n) || !is.numeric(n) || n < 1) {
    stop("`n` must be a single positive integer.")
  }

  n <- as.integer(n)

  ## Marine-inspired package palette
  base_cols <- c(
    "#0B3C5D", ## deep ocean blue
    "#117A8B", ## teal
    "#16A085", ## turquoise-green
    "#4DAF7C", ## sea green
    "#A1C181", ## soft algae
    "#F1C27D", ## sand
    "#E07A5F", ## coral
    "#B56576", ## muted rose
    "#6D597A"  ## dusk purple
  )

  if (n <= length(base_cols)) {
    return(base_cols[seq_len(n)])
  }

  grDevices::colorRampPalette(base_cols)(n)
}


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




.map2bar <- function(value, midL, bar.x) {
    if (length(midL) > 1) {
        approx(midL, bar.x, xout = value, rule = 2)$y
    } else {
        midL
    }
}



.quarter2months <- function(quarter) ((quarter - 1) * 3 + 1) : (quarter * 3)
