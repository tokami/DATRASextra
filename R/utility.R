
## Main functions ----------------------------------------------------------------


##' @title List all surveys in the DATRAS data base
##'
##' @return A vector with survey names.
##'
##' @export
list_surveys <- function() {

    survey_info <- get("survey_info", envir = asNamespace("DATRASextra"))

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
    fname <- if (scale == 110) "land_nea_110m.rds" else "land_nea_50m.rds"
    path <- system.file("extdata", fname, package = "DATRASextra")
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



##' Get WoRMS AphiaIDs from species names
##'
##' @description
##' Retrieves WoRMS AphiaIDs for one or more scientific species names.
##' By default, the function matches names against the internal
##' `species_info` table. Optionally, it can query the \pkg{worrms}
##' package to look up AphiaIDs directly from WoRMS.
##'
##' @param x A character vector of scientific species names.
##' @param use_worrms Logical; if `TRUE`, AphiaIDs are retrieved using
##'   [worrms::wm_name2id()]. If `FALSE` (default), names are matched against
##'   the internal `species_info` table.
##'
##' @return
##' If `use_worrms = FALSE`, an integer vector of WoRMS AphiaIDs with the same
##' length and order as `x`. Names not found in `species_info` return `NA`.
##'
##' If `use_worrms = TRUE`, the value returned by [worrms::wm_name2id()], which
##' may differ in structure from the internal lookup result depending on the
##' queried names and the response from WoRMS.
##'
##' @details
##' Using the internal `species_info` table provides a fast offline lookup, but
##' only for names included in that table. Using `use_worrms = TRUE` allows
##' direct lookup from WoRMS, but requires the \pkg{worrms} package to be
##' installed and may depend on internet access.
##'
##' @examples
##' get_aphia("Gadus morhua")
##'
##' get_aphia(c("Gadus morhua", "Melanogrammus aeglefinus"))
##'
##' \dontrun{
##' get_aphia("Gadus morhua", use_worrms = TRUE)
##' }
##'
##' @seealso [worrms::wm_name2id()]
##' @export
get_aphia <- function(x, use_worrms = FALSE) {

  if (isTRUE(use_worrms)) {

    if (!requireNamespace("worrms", quietly = TRUE)) {
      stop("Package 'worrms' is required to get the aphia ID from a species name. Please install it or use the species_info table to get the aphia ID (use_worrms = FALSE).")
    }

    return(worrms::wm_name2id(x))

  } else {

    ind <- match(x, species_info$ScientificName_WoRMS)

    if (any(is.na(ind))) stop("At last one latin name not found in species_info table. Please check your input or try using use_worrms = TRUE.")

    return(species_info$WoRMS_AphiaID[ind])

  }
}



##' Get scientific names from WoRMS AphiaIDs
##'
##' @description
##' Retrieves scientific names for one or more WoRMS AphiaIDs. By default,
##' the function matches AphiaIDs against the internal `species_info` table.
##' Optionally, it can query WoRMS directly via the \pkg{worrms} package.
##'
##' @param x A vector of WoRMS AphiaIDs.
##' @param use_worrms Logical; if `TRUE`, scientific names are retrieved using
##'   [worrms::wm_id2name()]. If `FALSE` (default), AphiaIDs are matched against
##'   the internal `species_info` table.
##'
##' @return
##' If `use_worrms = FALSE`, a character vector of scientific names with the
##' same length and order as `x`. AphiaIDs not found in `species_info` return
##' `NA`, unless `x` has length 0, in which case an error is thrown.
##'
##' If `use_worrms = TRUE`, the value returned by [worrms::wm_id2name()], which
##' may differ in structure depending on the queried AphiaIDs and the response
##' from WoRMS.
##'
##' @details
##' Using the internal `species_info` table provides a fast offline lookup, but
##' only for AphiaIDs included in that table. Using `use_worrms = TRUE` allows
##' direct lookup from WoRMS, but requires the \pkg{worrms} package to be
##' installed and may depend on internet access.
##'
##' @examples
##' get_latin(126436)
##'
##' get_latin(c(126436, 126437))
##'
##' \dontrun{
##' get_latin(126436, use_worrms = TRUE)
##' }
##'
##' @seealso [worrms::wm_id2name()]
##' @export
get_latin <- function(x, use_worrms = FALSE) {

  if (isTRUE(use_worrms)) {

    if (!requireNamespace("worrms", quietly = TRUE)) {
      stop("Package 'worrms' is required to get the latin name from an aphia ID. Please install it or use the species_info table to get the latin name (use_worrms = FALSE).")
    }

    return(worrms::wm_id2name(x))

  } else {

    ind <- match(x, species_info$WoRMS_AphiaID)

    if (any(is.na(ind))) stop("At last one aphia ID not found in species_info table. Please check your input or try using use_worrms = TRUE.")

    return(species_info$ScientificName_WoRMS[ind])

  }
}




## Internal functions ------------------------------------------------------------

.colours_datrasextra_continuous <- function(n, rev = FALSE) {
  if (length(n) != 1L || is.na(n) || !is.numeric(n) || n < 1) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  n <- as.integer(n)

  anchors <- c(
    "#f0e2c0", # sand (low)
    "#A1C181", # soft algae
    "#4DAF7C", # sea green
    "#16A085", # turquoise-green
    "#117A8B", # teal
    "#0B3C5D" # deep ocean blue
    ## "#6D597A"  # dusk purple (high)
  )

  pal <- grDevices::colorRampPalette(anchors)(n)
  if (isTRUE(rev)) pal <- rev(pal)
  pal
}

.colours_datrasextra_discrete <- function(n, rev = FALSE) {
  if (length(n) != 1L || is.na(n) || !is.numeric(n) || n < 1) {
    stop("`n` must be a single positive integer.", call. = FALSE)
  }
  n <- as.integer(n)

  base_cols <- c(
    "#f0e2c0", # sand (low)
    "#A1C181",
    "#4DAF7C",
    "#16A085",
    "#117A8B",
    "#0B3C5D"
    ## "#6D597A"  # high
  )

  if (isTRUE(rev)) base_cols <- rev(base_cols)

  if (n <= length(base_cols)) return(base_cols[seq_len(n)])
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


##' @export
##' @method print datras_raw
print.datras_raw <- function(x, ...) {
  hh <- x[["HH"]]
  hl <- x[["HL"]]
  ca <- x[["CA"]]

  cat("Object of class 'datras_raw'\n")
  cat("===========================\n")
  cat("Number of hauls:", nrow(hh), "\n")

  n_sp <- if ("Valid_Aphia" %in% names(hl))
    length(unique(hl$Valid_Aphia[!is.na(hl$Valid_Aphia)]))
  else if ("Species" %in% names(hl)) nlevels(hl$Species) else 0L
  cat("Number of species:", n_sp, "\n")

  if ("Country" %in% names(hh))
    cat("Number of countries:", length(unique(as.character(hh$Country))), "\n")

  cat("Years:", paste(levels(hh$Year), collapse = " "), "\n")
  cat("Quarters:", paste(levels(hh$Quarter), collapse = " "), "\n")
  cat("Gears:", paste(levels(factor(as.character(hh$Gear))), collapse = " "), "\n")

  numNa <- sum(is.na(hh$HaulDur))
  cat(paste("Haul duration:", paste(unique(range(hh$HaulDur, na.rm = TRUE)), collapse = " - "), "minutes"))
  if (numNa) { cat(" ("); cat(numNa, "NAs removed)") }
  cat("\n")

  if ("HaulVal" %in% names(hh)) {
    n_valid   <- sum(as.character(hh$HaulVal) == "V", na.rm = TRUE)
    n_invalid <- nrow(hh) - n_valid
    cat("Valid hauls:", n_valid)
    if (n_invalid > 0) cat(" (", n_invalid, " invalid)", sep = "")
    cat("\n")
  }

  if ("lon" %in% names(hh) && "lat" %in% names(hh)) {
    lon_r <- round(range(hh$lon, na.rm = TRUE), 2)
    lat_r <- round(range(hh$lat, na.rm = TRUE), 2)
    cat("Longitude range:", lon_r[1], "-", lon_r[2], "\n")
    cat("Latitude range:", lat_r[1], "-", lat_r[2], "\n")
  }

  if ("Depth" %in% names(hh)) {
    d_r <- range(hh$Depth, na.rm = TRUE)
    cat("Depth range:", d_r[1], "-", d_r[2], "m\n")
  }

  sa_cols <- grep("SweptArea", names(hh), value = TRUE, ignore.case = TRUE)
  if (length(sa_cols) > 0) {
    v <- hh[[sa_cols[1]]]
    r <- signif(range(v, na.rm = TRUE), 3)
    cat("Swept area: ", r[1], " - ", r[2], "\n", sep = "")
  }

  hn_cols <- grep("^HaulN$|^HaulN\\.", names(hh), value = TRUE, perl = TRUE)
  if (length(hn_cols) > 0) {
    if (!is.null(colnames(hh[[hn_cols]]))) {
      cat("HaulN by length:", paste(colnames(hh[[hn_cols]]), collapse = ", "), "\n")
    } else {
      cat("HaulN present\n")
    }
  }

  hn_cols <- grep("^HaulWgt$|^HaulWgt\\.", names(hh), value = TRUE, perl = TRUE)
  if (length(hn_cols) > 0) {
    if (!is.null(colnames(hh[[hn_cols]]))) {
      cat("HaulWgt by length:", paste(colnames(hh[[hn_cols]]), collapse = ", "), "\n")
    } else {
      cat("HaulWgt present\n")
    }
  }

  rpt <- attr(x, "outlier_report")
  if (!is.null(rpt)) {
    n_flagged <- length(attr(x, "outlier_hauls"))
    if (n_flagged > 0) {
      cat("Outlier check:", n_flagged, "flagged haul(s) -- see summary() for details.\n")
    } else {
      cat("Outlier check: no flagged hauls.\n")
    }
  }

  invisible(x)
}


##' @export
##' @method summary datras_raw
summary.datras_raw <- function(object, ...) {
  x  <- object
  hh <- x[["HH"]]
  hl <- x[["HL"]]

  print(x)

  cat("Number of hauls by year and quarter:\n")
  print(xtabs(~Year + Quarter, data = hh))

  cat("Haul duration:\n")
  print(summary(hh$HaulDur))

  base_hh <- c("RecordType","Survey","Quarter","Country","Ship","Gear","SweepLngt","GearEx",
                "DoorType","StNo","HaulNo","Year","Month","Day","TimeShot","DepthStratum",
                "HaulDur","DayNight","ShootLat","ShootLong","HaulLat","HaulLong","StatRec",
                "Depth","HaulVal","HydroStNo","StdSpecRecCode","BySpecRecCode","DataType",
                "Netopening","Rigging","Tickler","Distance","Warplngt","Warpdia","WarpDen",
                "DoorSurface","DoorWgt","DoorSpread","WingSpread","Buoyancy","KiteDim",
                "WgtGroundRope","TowDir","GroundSpeed","SpeedWater","SurCurDir","SurCurSpeed",
                "BotCurDir","BotCurSpeed","WindDir","WindSpeed","SwellDir","SwellHeight",
                "SurTemp","BotTemp","SurSal","BotSal","ThermoCline","ThClineDepth",
                "CodendMesh","SecchiDepth","Turbidity","TidePhase","TideSpeed","PelSampType",
                "MinTrawlDepth","MaxTrawlDepth","DateofCalculation","haul.id","abstime",
                "timeOfYear","TimeShotHour","lon","lat","Roundfish")
  added_hh <- setdiff(names(hh), base_hh)
  if (length(added_hh) > 0)
    cat("Extra columns in HH:", paste(added_hh, collapse = ", "), "\n")

  sp_ids <- if ("Valid_Aphia" %in% names(hl))
    sort(unique(hl$Valid_Aphia[!is.na(hl$Valid_Aphia)])) else integer(0)
  if (length(sp_ids) > 0) {
    cat("Species:\n")
    if ("Species" %in% names(hl)) {
      m <- match(sp_ids, hl$Valid_Aphia)
      sp_names <- as.character(hl$Species[m])
      cat(paste(paste0("  ", sp_names, " (AphiaID ", sp_ids, ")"), collapse = "\n"), "\n")
    } else {
      cat(paste0("  AphiaID ", sp_ids, collapse = "\n"), "\n")
    }
  }

  rpt <- attr(x, "outlier_report")
  if (!is.null(rpt)) {
    cat("---\nOutlier report:\n")
    n_invalid <- length(attr(x, "outlier_hauls_invalid"))
    n_extreme <- length(attr(x, "outlier_hauls_extreme"))
    n_all     <- length(attr(x, "outlier_hauls"))
    cat("  Flagged hauls:", n_all,
        paste0("(", n_invalid, " rule-based, ", n_extreme, " percentile-based)\n"))
    if (nrow(rpt) > 0) {
      tmp <- transform(rpt, n = 1L)
      tmp$severity <- ifelse(is.na(tmp$severity), "unknown", tmp$severity)
      tbl <- stats::aggregate(n ~ table + var + severity, data = tmp, FUN = sum)
      print(tbl, row.names = FALSE)
    }
  }

  invisible(x)
}


.map2bar <- function(value, midL, bar.x) {
    if (length(midL) > 1) {
        approx(midL, bar.x, xout = value, rule = 2)$y
    } else {
        midL
    }
}



.quarter2months <- function(quarter) ((quarter - 1) * 3 + 1) : (quarter * 3)
