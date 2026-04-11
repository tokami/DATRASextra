
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


##' Add species information to CA and HL tables
##'
##' @description
##' Adds one or more columns from `species_info` to the `CA` and/or `HL`
##' elements of a DATRAS-like object by matching `Valid_Aphia` in the table
##' to `WoRMS_AphiaID` in `species_info`.
##'
##' The function preserves the original row order of each table and performs
##' a left join, meaning that rows with no matching species information are
##' retained and receive `NA` in the added columns.
##'
##' For this type of lookup, the function uses [base::match()], which is
##' typically faster and simpler than [base::merge()] when only selected
##' columns need to be appended and the original row order should be kept.
##'
##' @param x A DATRAS-like object containing at least optional `CA` and/or `HL`
##'   data frames.
##' @param vars Character vector giving the names of columns in `species_info`
##'   to add. If `NULL`, all columns except `WoRMS_AphiaID` are added.
##' @param verbose Logical; if `TRUE`, progress messages are printed.
##'
##' @details
##' The lookup is based on the correspondence between:
##' \itemize{
##'   \item `x[["CA"]][["Valid_Aphia"]]` or `x[["HL"]][["Valid_Aphia"]]`
##'   \item `species_info[["WoRMS_AphiaID"]]`
##' }
##'
##' If any requested columns already exist in `CA` or `HL`, they are
##' overwritten.
##'
##' @return
##' The input object `x`, with the requested columns added to the `CA` and/or
##' `HL` elements where present.
##'
##' @examples
##' ## Add all available species information
##' ## x <- add_species_info(x)
##'
##' ## Add only selected columns
##' ## x <- add_species_info(x, vars = c("ScientificName", "FishBase"))
##'
##' @export
add_species_info <- function(x, vars = NULL, verbose = TRUE) {

  .check_class_datras(x)

  if (!exists("species_info", inherits = TRUE)) {
    stop("'species_info' was not found. Did you load DATRASextra? (library(DATRASextra) or try to run data('species_info').")
  }

  if (!is.data.frame(species_info)) {
    stop("'species_info' must be a data.frame.")
  }

  if (!"WoRMS_AphiaID" %in% names(species_info)) {
    stop("'species_info' must contain a column named 'WoRMS_AphiaID'.")
  }

  if (is.null(vars)) {
    vars <- setdiff(names(species_info), "WoRMS_AphiaID")
    if (verbose) {
      message(
        "No variables selected. Adding all columns of species_info except ",
        "'WoRMS_AphiaID'."
      )
    }
  }

  if (!is.character(vars)) {
    stop("'vars' must be a character vector or NULL.")
  }

  missing_vars <- setdiff(vars, names(species_info))
  if (length(missing_vars) > 0) {
    stop(
      "The following 'vars' are not found in 'species_info': ",
      paste(missing_vars, collapse = ", ")
    )
  }

  ## Internal helper to add species information to one table
  add_to_table <- function(tab, tab_name) {

    if (!is.data.frame(tab) || nrow(tab) == 0) {
      return(tab)
    }

    if (!"Valid_Aphia" %in% names(tab)) {
      warning("Skipping ", tab_name, ": column 'Valid_Aphia' not found.")
      return(tab)
    }

    ind <- match(tab[["Valid_Aphia"]], species_info[["WoRMS_AphiaID"]])

    ## Assign matched columns directly to preserve row order and avoid
    ## rebuilding the full data frame unnecessarily
    tab[vars] <- species_info[ind, vars, drop = FALSE]

    if (verbose) {
      message("Added ", paste(vars, collapse = ", "), " to ", tab_name, ".")
    }

    tab
  }

  if ("CA" %in% names(x)) {
    x[["CA"]] <- add_to_table(x[["CA"]], "CA")
  }

  if ("HL" %in% names(x)) {
    x[["HL"]] <- add_to_table(x[["HL"]], "HL")
  }

  x
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
