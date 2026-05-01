
## Main functions ----------------------------------------------------------------


##' Clean a `datras_raw` object
##'
##' Apply standard cleaning steps to a `datras_raw` / `DATRASraw` object.
##'
##' For standard DATRAS data, the function removes invalid hauls, keeps only
##' records with complete standard-species recording, optionally imputes missing
##' haul depths, optionally corrects species information, and can subset the
##' data by species, year, quarter, or gear.
##'
##' If `do_fishglob = TRUE`, cleaning is delegated to [clean_fishglob()].
##'
##' @param x A `datras_raw` object.
##' @param aphias Optional numeric or character vector of Aphia IDs
##'   (`Valid_Aphia`) to retain.
##' @param years Optional integer vector of years to retain.
##' @param quarters Optional integer vector of quarters to retain.
##' @param gears Optional character vector of gear codes to retain.
##' @param impute_missing_depth Logical. If `TRUE` (default), missing haul depths
##'   are imputed using a smooth spatial GAM fitted to observed depths.
##' @param correct_species Logical. If `TRUE` (default), species information is
##'   corrected using [correct_species()].
##' @param do_fishglob Logical. If `TRUE`, apply [clean_fishglob()] instead of
##'   the standard DATRAS cleaning steps.
##'
##' @details
##' For standard DATRAS data (`do_fishglob = FALSE`), the following filters are
##' applied before any optional subsetting:
##' \itemize{
##'   \item only hauls with `HaulVal %in% c("V", "N")` are retained,
##'   \item only records with `StdSpecRecCode == 1` are retained.
##' }
##'
##' If `impute_missing_depth = TRUE`, missing `Depth` values are predicted from a
##' GAM of `log(Depth)` on a two-dimensional smooth of longitude and latitude.
##'
##' Optional filtering by `aphias`, `years`, `quarters`, and `gears` is applied
##' after cleaning.
##'
##' @return A cleaned `datras_raw` object.
##'
##' @seealso [prune_datras()], [correct_species()], [clean_fishglob()]
##'
##' @examples
##' \dontrun{
##' ## Basic cleaning
##' x_clean <- clean_datras(x)
##'
##' ## Restrict to selected years and quarters
##' x_clean <- clean_datras(x, years = 2018:2020, quarters = c(1, 3))
##'
##' ## Keep only selected species
##' x_clean <- clean_datras(x, aphias = c(126417, 126436))
##' }
##'
##' @importFrom mgcv gam s predict.gam
##'
##' @export
clean_datras <- function(x,
                         aphias = NULL,
                         years = NULL,
                         quarters = NULL,
                         gears = NULL,
                         impute_missing_depth = TRUE,
                         correct_species = TRUE,
                         do_fishglob = FALSE) {

  .check_class_datras(x)

  ## Minimum cleaning ------------------------
  if (!do_fishglob) {

    ## HaulVal (https://vocab.ices.dk/?ref=1)
    x <- subset(x, HaulVal %in% c("V","N"))
    ## A	Additional valid stations not used for index calculations
    ## C	Calibrated (BITS only)
    ## I	Invalid haul
    ## M	Pelagic Midwater Trawl (BITS only)
    ## N	No oxygen (BITS only)
    ## P  Partly valid haul - there is catch, but trawl sensors show problems,
    ##    faulty door distance, or other indications of malfunction
    ## S	Standard haul
    ## V	Valid haul

    ## StdSpecRecCode (https://vocab.ices.dk/?ref=88)
    x <- subset(x, StdSpecRecCode == 1)
    ## 0	No standard species recorded
    ## 1	All standard species recorded
    ## 2	Pelagic standard species recorded
    ## 3	Roundfish standard species recorded
    ## 4	Individual standard species recorded

    ## Only keep TVL and TVS in BITS
    ## x <- subset(x, Survey != "BITS" |
    ##                (Survey == "BITS" & Gear %in% c("TVS","TVL")))

    ## Impute depths ------------------------------
    if (impute_missing_depth && any(is.na(x[[2]]$Depth))) {
      dmodel <- mgcv::gam(log(Depth) ~ s(lon, lat, k = 200), data = x[[2]])
      sel <- subset(x, is.na(Depth))
      sel$Depth <- 0 ## Guard against NA-error
      x$Depth[is.na(x$Depth)] <- exp(mgcv::predict.gam(dmodel, newdata = sel[[2]]))
      sel <- dmodel <- NULL; gc()
    }


    ## Species correction -------------------------
    if (correct_species) {
      x <- correct_species(x)
    }

  } else {

    x <- clean_fishglob(x)

  }


  ## Optional subsetting -----------------------
  if(!is.null(aphias)){
    x <- subset(x,
                Valid_Aphia %in% aphias)
  }
  if(!is.null(years)){
    x <- subset(x,
                Year %in% years)
  }
  if(!is.null(quarters)){
    x <- subset(x,
                Quarter %in% quarters)
  }
  if(!is.null(gears)){
    x <- subset(x,
                Gear %in% gears)
  }

  return(x)
}


##' Default columns used by prune_datras
##'
##' @return A named list with default columns for `HH`, `HL`, and `CA`.
##' @export
list_prune_datras_defaults <- function() {
  list(
    HH = c("RecordType", "haul.id", "Survey", "Quarter", "Country", "Ship",
           "Gear", "SweepLngt", "GearEx", "DoorType", "StNo", "HaulNo", "Year",
           "Month", "Day", "TimeShot", "HaulDur", "DayNight", "StatRec",
           "Depth", "HaulVal", "StdSpecRecCode", "BySpecRecCode", "DataType",
           "Netopening", "Rigging", "Tickler", "Distance", "Warplngt",
           "Warpdia", "WarpDen", "DoorSurface", "DoorWgt", "DoorSpread",
           "WingSpread", "GroundSpeed", "haul.id", "abstime", "timeOfYear",
           "TimeShotHour", "lon", "lat", "Roundfish"),

    HL = c("RecordType", "haul.id", "Survey", "Quarter", "Country", "Ship",
           "Gear", "SweepLngt", "GearEx", "DoorType", "Year", "SpecVal", "Sex",
           "TotalNo", "SubFactor", "SubWgt", "CatCatchWgt", "LngtCode",
           "LngtClas", "HLNoAtLngt", "Valid_Aphia", "LngtCm", "Species",
           "HaulDur", "DataType", "Count"),

    CA = c("RecordType", "haul.id", "Survey", "Quarter", "Country", "Ship",
           "Gear", "SweepLngt", "GearEx", "DoorType", "Year", "LngtCode",
           "LngtClas", "Sex", "Maturity", "PlusGr", "Age", "NoAtALK", "IndWgt",
           "MaturityScale", "Valid_Aphia", "LngtCm", "Species")
  )
}

##' Available columns in a datras_raw object
##'
##' @param x A `datras_raw` object.
##'
##' @return A named list with column names in `HH`, `HL`, and `CA`.
##' @export
list_prune_datras_available <- function(x) {
  .check_class_datras(x)

  out <- lapply(c("HH", "HL", "CA"), function(nm) {
    if (nm %in% names(x)) names(x[[nm]]) else character(0)
  })

  names(out) <- c("HH", "HL", "CA")
  out
}


##' Prune a `datras_raw` object to selected columns
##'
##' Reduce a `datras_raw` / `DATRASraw` object to a smaller set of columns in
##' the `HH`, `HL`, and `CA` tables.
##'
##' This is mainly intended to reduce memory use when working with large DATRAS
##' data sets, while still allowing users to modify which columns are retained.
##'
##' If `do_fishglob = TRUE`, pruning is delegated to [prune_fishglob()].
##'
##' @param x A `datras_raw` object.
##' @param keep Optional named list of columns to keep. List names should be
##'   `HH`, `HL`, and/or `CA`. If supplied, these columns replace the default
##'   columns for the named table(s).
##' @param add Optional named list of columns to add to the default columns.
##'   List names should be `HH`, `HL`, and/or `CA`.
##' @param drop Optional named list of columns to remove from the selected
##'   columns. List names should be `HH`, `HL`, and/or `CA`.
##' @param do_fishglob Logical. If `TRUE`, apply [prune_fishglob()] instead of
##'   the standard DATRAS pruning rules.
##' @param warn_missing Logical. If `TRUE`, warn when requested columns are not
##'   present in the corresponding table.
##'
##' @details
##' By default, the function keeps a predefined set of core columns in each of
##' the `HH`, `HL`, and `CA` tables. These defaults are intended to retain the
##' most commonly used haul metadata, length-frequency data, and biological
##' sampling information.
##'
##' The default columns can be inspected with [list_prune_datras_defaults()]. The
##' available columns in a specific object can be inspected with
##' [list_prune_datras_available()].
##'
##' Column selection can be modified in three ways:
##' \itemize{
##'   \item `keep` replaces the default columns for the named table(s),
##'   \item `add` adds columns to the default or selected columns,
##'   \item `drop` removes columns from the default or selected columns.
##' }
##'
##' Columns listed in `keep`, `add`, or `drop` for tables not present in `x` are
##' ignored. Requested columns that are not present in a table are ignored, with
##' an optional warning controlled by `warn_missing`.
##'
##' @return A pruned `datras_raw` object.
##'
##' @seealso [list_prune_datras_defaults()], [list_prune_datras_available()],
##'   [clean_datras()], [prune_fishglob()]
##'
##' @examples
##' \dontrun{
##' ## Inspect default columns retained by prune_datras()
##' list_prune_datras_defaults()
##'
##' ## Inspect available columns in a specific object
##' list_prune_datras_available(x)
##'
##' ## Reduce a DATRAS object to the default core columns
##' x_small <- prune_datras(x)
##'
##' ## Keep defaults, but retain additional environmental variables in HH
##' x_small <- prune_datras(
##'   x,
##'   add = list(HH = c("SurTemp", "BotTemp", "SurSal", "BotSal"))
##' )
##'
##' ## Keep defaults, but remove selected columns
##' x_small <- prune_datras(
##'   x,
##'   drop = list(HH = c("Roundfish", "timeOfYear"),
##'               HL = "Count")
##' )
##'
##' ## Fully override the columns retained for HH
##' x_small <- prune_datras(
##'   x,
##'   keep = list(HH = c("Survey", "Year", "haul.id", "lon", "lat", "Depth"))
##' )
##' }
##' @export
prune_datras <- function(x,
                         keep = NULL,
                         add = NULL,
                         drop = NULL,
                         do_fishglob = FALSE,
                         warn_missing = TRUE) {

  .check_class_datras(x)

  if (isTRUE(do_fishglob)) {
    return(prune_fishglob(x))
  }

  default_keep <- list_prune_datras_defaults()

  ## If keep is supplied, it replaces the defaults for the named tables.
  cols <- default_keep
  if (!is.null(keep)) {
    cols[names(keep)] <- keep
  }

  ## Add extra columns to selected tables.
  if (!is.null(add)) {
    for (nm in names(add)) {
      cols[[nm]] <- unique(c(cols[[nm]], add[[nm]]))
    }
  }

  ## Remove selected columns from selected tables.
  if (!is.null(drop)) {
    for (nm in names(drop)) {
      cols[[nm]] <- setdiff(cols[[nm]], drop[[nm]])
    }
  }

  for (nm in intersect(names(cols), names(x))) {

    missing_cols <- setdiff(cols[[nm]], names(x[[nm]]))

    if (warn_missing && length(missing_cols) > 0) {
      warning(
        "In ", nm, ", requested columns not found and ignored: ",
        paste(missing_cols, collapse = ", "),
        call. = FALSE
      )
    }

    cols_present <- intersect(cols[[nm]], names(x[[nm]]))
    x[[nm]] <- x[[nm]][cols_present]
  }

  x
}



##' Standardize and correct species information in a `datras_raw` object
##'
##' Correct selected species names, Aphia IDs, and taxonomic ranks in the `CA`
##' and `HL` tables of a `datras_raw` / `DATRASraw` object.
##'
##' The function is intended to harmonize species information for cases where
##' records are better treated at genus level, where synonymous or outdated
##' species names occur, or where taxonomic information is incomplete.
##'
##' @param x A `datras_raw` object.
##'
##' @details
##' The function operates on the `CA` and `HL` components, if present and
##' non-empty.
##'
##' If the column `Rank` is missing, it is added and initialized as
##' `"species"`. Selected taxa are then reassigned to genus level by updating
##' `Species`, `Valid_Aphia`, and `Rank`. In addition, a small number of species
##' name corrections are applied.
##'
##' Examples of corrections include:
##' \itemize{
##'   \item collapsing selected taxa to genus level, for example
##'     `"Dipturus"` or `"Gobius"`,
##'   \item harmonizing alternative or inconsistent taxonomic names,
##'   \item updating corresponding `Valid_Aphia` identifiers,
##'   \item setting `Rank` to either `"species"` or `"genus"` as appropriate.
##' }
##'
##' The function currently modifies only the `CA` and `HL` tables and leaves
##' `HH` unchanged.
##'
##' @return A `datras_raw` object with corrected `Species`, `Valid_Aphia`, and
##'   `Rank` fields in the `CA` and `HL` tables where applicable.
##'
##' @seealso [clean_datras()]
##'
##' @examples
##' \dontrun{
##' ## Correct species information after reading DATRAS data
##' x <- correct_species(x)
##' }
##'
##' @export
correct_species <- function(x) {

  .check_class_datras(x)

  for(i in c("CA","HL")){

    if (is.null(x[[i]]) || nrow(x[[i]]) == 0) next()

    if (!any(colnames(x[[i]]) == "Rank")) {
      x[[i]]$Rank <- "species"
      ## This is not right! get worms function (or later full updated species table to include this!)
    }

    specs <- as.character(x[[i]]$Species)
    aphias <- x[[i]]$Valid_Aphia
    ranks <- x[[i]]$Rank

    ## Some species not robustly identified --------------------------------
    keep.genus <- data.frame(genus = c("Dipturus", "Liparis", "Chelon",
                                       "Mustelus", "Alosa", "Argentina",
                                       "Callionymus", "Ciliata",
                                       "Gaidropsarus", "Sebastes",
                                       "Syngnatus", "Pomatoschistus",
                                       "Gobius"),
                             aphia = c(105762, 126160, 126030, 105732, 125715,
                                       125885, 125930, 125741, 125743, 126175,
                                       126227, 125999, 125988))


    for (j in 1:nrow(keep.genus)) {
      ind <- grep(keep.genus$genus[j], specs)
      if (length(ind) > 0) {
        specs[ind] <- keep.genus$genus[j]
        aphias[ind] <- keep.genus$aphia[j]
        ranks[ind] <- "genus"
      }
    }

    ## Extra for species with different genus names ----------------------
    ind <- grep("Nerophis ophidion", specs)
    if (length(ind) > 0) {
      specs[ind] <- "Syngnatus"
      aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Syngnatus"]
      ranks[ind] <- "genus"
    }
    ind <- grep("Leusueurigobius", specs)
    if (length(ind) > 0) {
      specs[ind] <- "Gobius"
      aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Gobius"]
      ranks[ind] <- "genus"
    }
    ind <- grep("Neogobius", specs)
    if (length(ind) > 0) {
      specs[ind] <- "Gobius"
      aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Gobius"]
      ranks[ind] <- "genus"
    }
    ind <- grep("Argentinidae", specs)
    if (length(ind) > 0) {
      specs[ind] <- "Argentina"
      aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Argentina"]
      ranks[ind] <- "genus"
    }


    ## Species name corrections -----------------------------------------
    ind <- grep("Synaphobranchus kaupi", specs)
    if (length(ind) > 0) {
      specs[ind] <- "Synaphobranchus kaupii"
      aphias[ind] <- 126328
      ranks[ind] <- "species"
    }
    ind <- grep("Dipturus linteus", specs)
    if (length(ind) > 0) {
      specs[ind] <- "Rajella lintea"
      aphias[ind] <- 1019159
      ranks[ind] <- "species"
    }

    x[[i]]$Species <- factor(specs)
    x[[i]]$Valid_Aphia <- aphias
    x[[i]]$Rank <- ranks

  }


  ## BySpecRecCode corrections -----------------------------------------
  ## not used currently - neither in FishGlob
  species.keep0  <- c('Clupea harengus','Sprattus sprattus',
                      'Scomber scombrus','Gadus morhua',
                      'Melanogrammus aeglefinus', 'Merlangius merlangus',
                      'Trisopterus esmarkii')

  species.keep1 <- c("Chelidonichthys cuculus", "Chelidonichthys lucerna",
                     "Eutrigla gurnardus", "Gadus morhua","Limanda limanda",
                     "Lophius piscatorius", "Merlangius merlangus",
                     "Microstomus kitt","Mullus surmuletus",
                     "Mustelus asterias","Pegusa lascaris",
                     "Platichthys flesus", "Pleuronectes platessa",
                     "Raja brachyura","Raja clavata", "Raja montagui",
                     "Scophthalmus maximus", "Scophthalmus rhombus",
                     "Scyliorhinus canicula", "Solea solea",
                     "Trispoterus luscus")

  species.keep2 <- c('Ammodytidae','Anarhichas lupus', 'Argentina silus',
                     'Argentina sphyraena', 'Chelidonichthys cuculus',
                     'Callionymus lyra', 'Eutrigla gurnardus',
                     'Lumpenus lampretaeformis', 'Mullus surmuletus',
                     'Squalus acanthias', 'Trachurus trachurus',
                     'Platichthys flesus', 'Pleuronectes platessa',
                     'Limanda limanda', 'Lepidorhombus whiffiagoni',
                     'Hippoglossus hippoglossus',
                     'Hippoglossoides platessoi',
                     'Glyptocephalus cynoglossu', 'Microstomus kitt',
                     'Scophthalmus maximus', 'Scophthalmus rhombus',
                     'Solea solea', 'Pollachius virens',
                     'Pollachius pollachius', 'Trisopterus luscus',
                     'Trisopterus minutus', 'Micromesistius poutassou',
                     'Molva molva', 'Merluccius merluccius',
                     'Brosme brosme', 'Clupea harengus',
                     'Sprattus sprattus', 'Scomber scombrus',
                     'Gadus morhua', 'Melanogrammus aeglefinus',
                     'Merlangius merlangus','Trisopterus esmarkii')

  species.keep3 <- c('Pollachius virens','Pollachius pollachius',
                     'Trisopterus luscus','Trisopterus minutus',
                     'Micromesistius poutassou','Molva molva',
                     'Merluccius merluccius','Brosme brosme',
                     'Clupea harengus','Sprattus sprattus',
                     'Scomber scombrus','Gadus morhua',
                     'Melanogrammus aeglefinus', 'Merlangius merlangus',
                     'Trisopterus esmarkii')

  species.keep4 <- c('Platichthys flesus','Pleuronectes platessa',
                     'Limanda limanda', 'Lepidorhombus whiffiagoni',
                     'Hippoglossus hippoglossus',
                     'Hippoglossoides platessoi',
                     'Glyptocephalus cynoglossu', 'Microstomus kitt',
                     'Scophthalmus maximus', 'Scophthalmus rhombus',
                     'Solea solea', 'Clupea harengus',
                     'Sprattus sprattus', 'Scomber scombrus',
                     'Gadus morhua', 'Melanogrammus aeglefinus',
                     'Merlangius merlangus', 'Trisopterus esmarkii')

  species.keep5 <- c('Ammodytidae','Anarhichas lupus', 'Argentina silus',
                     'Argentina sphyraena', 'Chelidonichthys cuculus',
                     'Callionymus lyra', 'Eutrigla gurnardus',
                     'Lumpenus lampretaeformis', 'Mullus surmuletus',
                     'Squalus acanthias', 'Trachurus trachurus',
                     'Clupea harengus', 'Sprattus sprattus',
                     'Scomber scombrus', 'Gadus morhua',
                     'Melanogrammus aeglefinus', 'Merlangius merlangus',
                     'Trisopterus esmarkii')

  species.keep6 <- c("Chelidonichthys lucerna","Conger conger",
                     "Eutrigla gurnardus", "Galeus melastomus",
                     "Helicolenus dactylopterus", "Lepidorhombus boscii",
                     "Lepidorhombus whiffiagoni", "Leucoraja circularis",
                     "Leucoraja naevus", "Lophius budegassa",
                     "Lophius piscatorius", "Merluccius merluccius",
                     "Micromesistius poutassou", "Phycis blennoides",
                     "Raja clavata", "Raja montagui", "Scomber scombrus",
                     "Scyliorhinus canicula", "Trachurus trachurus",
                     "Trisopterus luscus", "Zeus faber")

  species.keep7 <- c("Argentina silus","Chelidonichthys lucerna",
                     "Conger conger", "Eutrigla gurnardus",
                     "Gadus morhua","Galeus melastomus",
                     "Glyptocephalus cynoglossu",
                     "Helicolenus dactylopterus", "Hexanchus griseus",
                     "Hippoglossoides platessoi", "Lepidorhombus boscii",
                     "Lepidorhombus whiffiagoni", "Leucoraja circularis",
                     "Leucoraja naevus", "Lophius budegassa",
                     "Lophius piscatorius", "Melanogrammus aeglefinus",
                     "Merluccius merluccius", "Micromesistius poutassou",
                     "Molva dypterygia","Molva molva",
                     "Phycis blennoides","Raja clavata", "Raja montagui",
                     "Scomber scombrus", "Scyliorhinus canicula",
                     "Trachurus trachurus","Zeus faber")

  ## From Anna, what is NS-IBTS1 and NS-IBTS3?  q1 and q3?
  ## data <- subset(data, !(BySpecRecCode==0 & Data %in% c("NS-IBTS1","NS-IBTS3") &
  ##                !Species %in% c("Clupea harengus","Sprattus sprattus","Scomber scombrus","Gadus morhua",
  ##                                "Melanogrammus aeglefinus","Merlangius merlangus","Trisopterus esmarkii")))

  ## Not used here currently, neither in FishGlob ... TODO: quantify how many entries that would be!
  ## out_data <- data[
  ##     !(data$BycSpecRecCode == 0 & data$Survey == "NS-IBTS" &
  ##       !(data$Species %in% species.keep0)) &
  ##     !(data$BycSpecRecCode == 0 & data$Survey == "BTS" &
  ##       !(data$Species %in% species.keep1)) &
  ##     !(data$BycSpecRecCode == 2 & !(data$Species %in% species.keep2)) &
  ##     !(data$BycSpecRecCode == 3 & !(data$Species %in% species.keep3)) &
  ##     !(data$BycSpecRecCode == 4 & !(data$Species %in% species.keep4)) &
  ##     !(data$BycSpecRecCode == 5 & !(data$Species %in% species.keep5)) &
  ##     !(data$BycSpecRecCode == 0 & data$Survey == "SP-NORTH" &
  ##       !(data$Species %in% species.keep6)) &
  ##     !(data$BycSpecRecCode == 0 & data$Survey == "SP-PORC" &
  ##       !(data$Species %in% species.keep7)),
  ##     ]


  return(x)
}
