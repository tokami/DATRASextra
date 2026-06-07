
## Main functions ----------------------------------------------------------------

##' Format a `datras_raw` object as a table
##'
##' Convert a `datras_raw` / `DATRASraw` object to either long or wide tabular
##' format.
##'
##' This is a convenience wrapper around [as_long_format()] and
##' [as_wide_format()].
##'
##' @param x A `datras_raw` object.
##' @param type Character string specifying the output format. Must be either
##'   `"long"` (default) or `"wide"`.
##' @param ... Additional arguments passed to [as_long_format()] or
##'   [as_wide_format()].
##'
##' @details
##' If `type = "long"`, the object is converted using [as_long_format()].
##' If `type = "wide"`, the object is converted using [as_wide_format()].
##'
##' When `type = "long"`, columns `HaulN`, `HaulWgt`, and `SweptArea` are
##' included automatically whenever they are present in `HH`. If `HaulN` or
##' `HaulWgt` is a matrix (produced by passing `length_cuts` to
##' [add_total_numbers_by_haul()] or [add_total_weight_by_haul()]), the output
##' is expanded to one row per haul x length group and a `LengthGroup` column is
##' added.
##'
##' @return A data frame in the requested format.
##'
##' @seealso [as_long_format()], [as_wide_format()]
##'
##' @examples
##' \dontrun{
##' ## Long-format table
##' tab_long <- as_table(x, type = "long")
##'
##' ## Wide-format table
##' tab_wide <- as_table(x, type = "wide")
##' }
##'
##' @export
as_table <- function(x, type = "long", ...) {

  .check_class_datras(x)

  if (type == "long") {

    x <- as_long_format(x, ...)

  } else if (type == "wide") {

    x <- as_wide_format(x, ...)

  } else {
    stop("Unknown type. Use 'long' or 'wide'.")
  }

  return(x)
}



##' Convert a `datras_raw` object to a long-format table
##'
##' Create a long-format data frame from a `datras_raw` / `DATRASraw` object,
##' using `HH` as the main haul-level table and, when needed, adding variables
##' from `HL` matched by `haul.id`.
##'
##' If species-level variables such as `Species` or `Valid_Aphia` are requested,
##' the output contains one row per haul-species combination. Variables that are
##' not found in either `HH` or `HL` are omitted with a warning.
##'
##' @param x A `datras_raw` object.
##' @param vars Character vector of variable names to include in the output.
##'   Variables found in `HH` are taken directly from `HH`. Variables not found
##'   in `HH` but present in `HL` are joined by `haul.id`. Defaults to a set of
##'   common haul-level variables.
##'
##' @details
##' The function starts from the `HH` table and adds requested variables from
##' `HL` only when needed. If one or more requested variables come from `HL`,
##' the output is expanded to one row per unique `haul.id` and combination of
##' requested `HL` variables.
##'
##' This is particularly useful for creating haul-species tables, for example
##' when requesting `Species` or `Valid_Aphia` together with haul-level
##' covariates such as year, quarter, gear, or position.
##'
##' Variables requested in `vars` that are not present in either `HH` or `HL`
##' are ignored and reported with a warning.
##'
##' In addition to the explicitly requested `vars`, the function automatically
##' appends `HaulN`, `HaulWgt`, and `SweptArea` to the
##' output whenever those columns are present in `HH` (e.g., after calling
##' [add_total_numbers_by_haul()], [add_total_weight_by_haul()], or
##' [add_swept_area()]).
##'
##' If `HaulN` or `HaulWgt` is a matrix (created by passing `length_cuts` to
##' [add_total_numbers_by_haul()] or [add_total_weight_by_haul()]), the output
##' is automatically expanded to one row per haul × length group. A
##' `LengthGroup` column is added that identifies the length bin, and `HaulN`
##' / `HaulWgt` become scalar columns containing the per-bin values.
##'
##' @return A data frame in long format.
##'
##' @seealso [read_datras()], [clean_datras()]
##'
##' @examples
##' \dontrun{
##' ## Haul-level long table
##' tab <- as_long_format(x)
##'
##' ## Haul-species table
##' tab <- as_long_format(x, vars = c("Survey", "Year", "haul.id",
##'                                   "Species", "Valid_Aphia"))
##'
##' ## Request variables from both HH and HL
##' tab <- as_long_format(x, vars = c("Survey", "Gear", "Year",
##'                                   "Species", "Valid_Aphia"))
##'
##' ## HaulN/HaulWgt/SweptArea included automatically when present
##' x <- add_total_numbers_by_haul(x, length_cuts = c(0, 20, Inf))
##' x <- add_total_weight_by_haul(x, length_cuts = c(0, 20, Inf))
##' x <- add_swept_area(x)
##' tab <- as_long_format(x)  ## one row per haul x length group; LengthGroup column added
##' }
##'
##' @export
as_long_format <- function(
    x,
    vars = c("Survey", "Gear", "Country", "Ship", "Year",
             "Quarter", "Month", "Day", "lon", "lat",
             "timeOfYear", "abstime", "DayNight",
             "TimeShotHour", "HaulDur")
) {

  .check_class_datras(x)

  if (is.null(x[["HH"]]) || nrow(x[["HH"]]) == 0) {
    stop("x[['HH']] is missing or empty.")
  }

  hh <- x[["HH"]]
  hl <- x[["HL"]]

  ## allow a few common aliases
  var_map <- c(
    Aphia_ID = "Valid_Aphia",
    AphiaID = "Valid_Aphia",
    aphia_id = "Valid_Aphia",
    Species = "Species",
    species = "Species",
    haul_id = "haul.id"
  )

  vars_in <- vars
  vars_std <- ifelse(vars %in% names(var_map), unname(var_map[vars]), vars)

  ## variables available in each table
  hh_vars <- vars_std[vars_std %in% names(hh)]
  hl_vars <- character(0)

  if (!is.null(hl) && nrow(hl) > 0) {
    hl_vars <- vars_std[vars_std %in% names(hl) & !vars_std %in% names(hh)]
  }

  missing_vars <- vars_std[!vars_std %in% c(names(hh), names(hl))]

  if (length(missing_vars) > 0) {
    warning(
      "These variables were not found in HH or HL and were omitted: ",
      paste(unique(missing_vars), collapse = ", ")
    )
  }

  ## auto-include HaulN, HaulWgt, SweptArea if present in HH
  auto_candidates <- c("HaulN", "HaulWgt", "SweptArea")
  auto_add <- intersect(auto_candidates, names(hh))
  auto_add <- setdiff(auto_add, hh_vars)
  hh_vars <- unique(c(hh_vars, auto_add))

  ## start from HH
  res <- hh[, unique(c("haul.id", hh_vars)), drop = FALSE]

  ## add HL variables if requested
  if (length(hl_vars) > 0) {

    if (is.null(hl) || nrow(hl) == 0) {
      warning("HL is missing or empty, so HL variables were omitted: ",
              paste(hl_vars, collapse = ", "))
    } else {

      ## keep only required HL columns plus haul.id for matching
      hl_sub <- hl[, unique(c("haul.id", hl_vars)), drop = FALSE]

      ## remove duplicate haul-species (or more general haul-HL-variable) rows
      hl_sub <- unique(hl_sub)

      ## merge creates one row per unique haul.id + HL combination
      res <- merge(res, hl_sub, by = "haul.id", all.x = TRUE)
    }
  }

  ## restore original requested names where aliases were used
  out_names <- names(res)
  alias_back <- c(
    Valid_Aphia = if ("Aphia_ID" %in% vars_in) "Aphia_ID" else
      if ("AphiaID" %in% vars_in) "AphiaID" else
        if ("aphia_id" %in% vars_in) "aphia_id" else "Valid_Aphia",
    Species = if ("species" %in% vars_in) "species" else "Species",
    "haul.id" = if ("haul_id" %in% vars_in) "haul_id" else "haul.id"
  )

  for (nm in names(alias_back)) {
    if (nm %in% out_names) {
      names(res)[names(res) == nm] <- alias_back[[nm]]
    }
  }

  ## keep output order close to requested vars; auto-added columns go at end
  wanted <- c(
    if ("haul.id" %in% names(res) && !("haul.id" %in% vars_std) && !("haul_id" %in% vars_in)) "haul.id",
    vars_in[vars_std %in% c(names(hh), names(hl))],
    auto_add
  )

  wanted <- wanted[wanted %in% names(res)]
  res <- res[, unique(wanted), drop = FALSE]

  ## expand matrix columns (HaulN / HaulWgt with length_cuts) to long format
  mat_cols <- names(res)[vapply(names(res), function(nm) is.matrix(res[[nm]]), logical(1))]

  if (length(mat_cols) > 0) {
    bin_names <- colnames(res[[mat_cols[1]]])
    n_bins <- length(bin_names)
    n_hauls <- nrow(res)

    idx <- rep(seq_len(n_hauls), each = n_bins)
    scalar_cols <- setdiff(names(res), mat_cols)
    res_exp <- res[idx, scalar_cols, drop = FALSE]
    res_exp$LengthGroup <- rep(bin_names, times = n_hauls)

    for (mc in mat_cols) {
      ## as.vector(t(mat)) gives row-major order: haul1-bin1, haul1-bin2, haul2-bin1, ...
      res_exp[[mc]] <- as.vector(t(res[[mc]]))
    }

    ## put LengthGroup just before the matrix-derived columns
    other_cols <- setdiff(names(res_exp), c("LengthGroup", mat_cols))
    res <- res_exp[, c(other_cols, "LengthGroup", mat_cols), drop = FALSE]
  }

  rownames(res) <- NULL
  return(res)
}



##' Convert a `datras_raw` object to a wide-format table
##'
##' Create a wide-format data frame from a `datras_raw` / `DATRASraw` object,
##' using `HH` as the main haul-level table and spreading selected `HL`
##' variables into species-specific columns.
##'
##' The output contains one row per haul. Requested haul-level variables from
##' `HH` are kept as ordinary columns, while requested variables from `HL` are
##' expanded into columns of the form `"<variable><sep><species>"`.
##'
##' @param x A `datras_raw` object.
##' @param vars_hh Character vector of haul-level variables to keep from `HH`.
##' @param vars_hl Character vector of variables from `HL` to spread wide across
##'   species. Defaults to `"Count"`.
##' @param species_var Character scalar giving the `HL` variable that defines the
##'   species-specific column names. Defaults to `"Species"`. Can also be set to
##'   `"Valid_Aphia"` or another grouping variable present in `HL`.
##' @param id_var Character scalar giving the haul identifier variable used to
##'   match `HH` and `HL`. Defaults to `"haul.id"`.
##' @param sep Character scalar used to separate the `HL` variable name from the
##'   species name in wide column names. Defaults to `"__"`.
##' @param fill Value used to replace missing values in the wide `HL` columns.
##'   Defaults to `0`.
##' @param sanitize_names Logical. If `TRUE` (default), species names used in
##'   wide column names are converted to lower case and non-alphanumeric
##'   characters are replaced with underscores.
##' @param verbose Logical. If `TRUE` (default), warnings are issued for
##'   requested variables that are not found.
##'
##' @details
##' The function starts from the `HH` table and adds requested variables from
##' `HL` after aggregating them to unique `haul.id` x `species_var`
##' combinations.
##'
##' Numeric `HL` variables are summed within haul-species combinations before
##' reshaping wide. Non-numeric variables are reduced by taking the first
##' non-missing value.
##'
##' Variables requested in `vars_hh` or `vars_hl` that are not found in the
##' relevant table are omitted and reported with a warning.
##'
##' @return A data frame in wide format with one row per haul.
##'
##' @seealso [as_long_format()]
##'
##' @examples
##' \dontrun{
##' ## One row per haul, species-specific count columns
##' tab <- as_wide_format(x)
##'
##' ## Add more HL variables
##' tab <- as_wide_format(
##'   x,
##'   vars_hl = c("Count", "CatCatchWgt")
##' )
##'
##' ## Use Aphia IDs instead of species names in column names
##' tab <- as_wide_format(
##'   x,
##'   vars_hl = c("Count"),
##'   species_var = "Valid_Aphia"
##' )
##' }
##'
##' @export
as_wide_format <- function(
    x,
    vars_hh = c("Survey", "Gear", "Country", "Ship", "Year",
                "Quarter", "Month", "Day", "lon", "lat",
                "timeOfYear", "abstime", "DayNight",
                "TimeShotHour", "HaulDur"),
    vars_hl = "Count",
    species_var = "Species",
    id_var = "haul.id",
    sep = "__",
    fill = 0,
    sanitize_names = TRUE,
    verbose = TRUE
) {

  .check_class_datras(x)

  hh <- x[["HH"]]
  hl <- x[["HL"]]

  if (is.null(hh) || nrow(hh) == 0) {
    stop("x[['HH']] is missing or empty.")
  }

  ## Keep HH as base, one row per haul
  hh_keep <- unique(c(id_var, vars_hh))
  missing_hh <- setdiff(hh_keep, names(hh))
  hh_keep <- intersect(hh_keep, names(hh))

  if (length(missing_hh) > 0 && verbose) {
    warning(
      "These HH variables were not found and were omitted: ",
      paste(missing_hh, collapse = ", ")
    )
  }

  res <- unique(hh[, hh_keep, drop = FALSE])
  res$.row_id_tmp__ <- seq_len(nrow(res))

  ## No HL variables requested
  if (length(vars_hl) == 0) {
    res <- res[order(res$.row_id_tmp__), , drop = FALSE]
    res$.row_id_tmp__ <- NULL
    rownames(res) <- NULL
    return(res)
  }

  ## No HL available
  if (is.null(hl) || nrow(hl) == 0) {
    if (verbose) {
      warning("x[['HL']] is missing or empty, so no wide HL columns were added.")
    }
    res <- res[order(res$.row_id_tmp__), , drop = FALSE]
    res$.row_id_tmp__ <- NULL
    rownames(res) <- NULL
    return(res)
  }

  ## Check requested HL variables
  needed_hl <- unique(c(id_var, species_var, vars_hl))
  missing_hl <- setdiff(needed_hl, names(hl))
  vars_hl_ok <- intersect(vars_hl, names(hl))

  if (length(missing_hl) > 0 && verbose) {
    warning(
      "These HL variables were not found and were omitted: ",
      paste(missing_hl, collapse = ", ")
    )
  }

  if (!(id_var %in% names(hl))) {
    stop("'", id_var, "' is not present in HL.")
  }
  if (!(species_var %in% names(hl))) {
    stop("'", species_var, "' is not present in HL.")
  }
  if (length(vars_hl_ok) == 0) {
    res <- res[order(res$.row_id_tmp__), , drop = FALSE]
    res$.row_id_tmp__ <- NULL
    rownames(res) <- NULL
    return(res)
  }

  hl_sub <- hl[, unique(c(id_var, species_var, vars_hl_ok)), drop = FALSE]
  hl_sub <- hl_sub[!is.na(hl_sub[[id_var]]) & !is.na(hl_sub[[species_var]]), , drop = FALSE]

  if (nrow(hl_sub) == 0) {
    res <- res[order(res$.row_id_tmp__), , drop = FALSE]
    res$.row_id_tmp__ <- NULL
    rownames(res) <- NULL
    return(res)
  }

  ## Prepare names used in wide columns
  species_names <- as.character(hl_sub[[species_var]])
  if (sanitize_names) {
    species_names <- tolower(trimws(species_names))
    species_names <- gsub("[^[:alnum:]]+", "_", species_names)
    species_names <- gsub("^_+|_+$", "", species_names)
  }
  hl_sub[[species_var]] <- species_names

  first_non_na <- function(z) {
    z <- z[!is.na(z)]
    if (length(z) == 0) return(NA)
    z[1]
  }

  wide_list <- vector("list", length(vars_hl_ok))

  for (i in seq_along(vars_hl_ok)) {
    v <- vars_hl_ok[i]

    tmp <- hl_sub[, c(id_var, species_var, v), drop = FALSE]

    ## Aggregate within haul x species
    if (is.numeric(tmp[[v]])) {
      tmp <- aggregate(
        tmp[[v]],
        by = tmp[c(id_var, species_var)],
        FUN = function(z) sum(z, na.rm = TRUE)
      )
    } else {
      tmp <- aggregate(
        tmp[[v]],
        by = tmp[c(id_var, species_var)],
        FUN = first_non_na
      )
    }
    names(tmp)[3] <- v

    ## Reshape wide
    wide_v <- reshape(
      tmp,
      idvar = id_var,
      timevar = species_var,
      direction = "wide"
    )

    ## Rename columns: Count.cod -> Count__cod
    names(wide_v) <- sub(
      paste0("^", v, "\\."),
      paste0(v, sep),
      names(wide_v)
    )

    ## Fill NAs in wide columns
    new_cols <- setdiff(names(wide_v), id_var)
    if (length(new_cols) > 0) {
      for (j in seq_along(new_cols)) {
        sel <- is.na(wide_v[[new_cols[j]]])
        if (any(sel)) wide_v[[new_cols[j]]][sel] <- fill
      }
    }

    wide_list[[i]] <- wide_v
  }

  ## Merge all HL-wide blocks
  wide_hl <- wide_list[[1]]
  if (length(wide_list) > 1) {
    for (i in 2:length(wide_list)) {
      wide_hl <- merge(wide_hl, wide_list[[i]], by = id_var, all = TRUE, sort = FALSE)
    }
  }

  ## Merge with HH base table
  res <- merge(res, wide_hl, by = id_var, all.x = TRUE, sort = FALSE)
  res <- res[order(res$.row_id_tmp__), , drop = FALSE]
  res$.row_id_tmp__ <- NULL

  rownames(res) <- NULL
  return(res)
}
