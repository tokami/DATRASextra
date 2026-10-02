
## Main functions ----------------------------------------------------------------

.default_hh_vars <- c(
  "Survey", "Gear", "Country", "Ship", "Year",
  "Quarter", "Month", "Day", "lon", "lat",
  "timeOfYear", "abstime", "DayNight",
  "TimeShotHour", "HaulDur"
)

.prep_hh_vars <- function(x, vars, add_vars, remove_vars, auto_add = TRUE) {
  hh <- x[["HH"]]

  if (!is.null(remove_vars)) vars <- setdiff(vars, remove_vars)
  if (!is.null(add_vars))    vars <- unique(c(vars, add_vars))

  if (auto_add) {
    auto_candidates <- c("HaulN", "HaulWgt", "SweptArea")
    auto <- setdiff(intersect(auto_candidates, names(hh)), vars)
    if (!is.null(remove_vars)) auto <- setdiff(auto, remove_vars)
    vars <- unique(c(vars, auto))
  }

  missing_vars <- setdiff(vars, names(hh))
  if (length(missing_vars) > 0) {
    warning(
      "These variables were not found in HH and were omitted: ",
      paste(missing_vars, collapse = ", ")
    )
  }
  vars <- intersect(vars, names(hh))

  res <- hh[, unique(c("haul.id", vars)), drop = FALSE]
  rownames(res) <- NULL
  res
}


##' Format a `datras_raw` object as a table
##'
##' Convert a `datras_raw` / `DATRASraw` object to a single data frame in long
##' or wide format: the hauls (`HH`), the numbers at length by species (`HL`), or
##' the individual biological records (`CA`), each with the selected haul-level
##' variables attached.
##'
##' For `table = "HH"` this is a convenience wrapper around [as_long_format()]
##' and [as_wide_format()].
##'
##' @param x A `datras_raw` object.
##' @param vars Character vector of `HH` variable names to include. Defaults to
##'   15 common haul-level columns: `Survey`, `Gear`, `Country`, `Ship`,
##'   `Year`, `Quarter`, `Month`, `Day`, `lon`, `lat`, `timeOfYear`,
##'   `abstime`, `DayNight`, `TimeShotHour`, `HaulDur`.
##' @param add_vars Character vector of additional `HH` variable names to
##'   append to `vars`. Applied after `remove_vars`.
##' @param remove_vars Character vector of variable names to drop from `vars`.
##'   Applied before `add_vars`.
##' @param type Character string specifying the output format: `"long"`
##'   (default) or `"wide"`. See Details for what each means per `table`.
##' @param table Character string naming the table to export: `"HH"` (default)
##'   for one row per haul, `"HL"` for numbers at length by haul and species,
##'   or `"CA"` for one row per individual record.
##' @param hl_by Character vector of `HL` columns that define a row for `table =
##'   "HL"`, in addition to the haul. Default `c("Valid_Aphia", "LngtCm")`:
##'   species x length class, summed over sex and catch category. Add `"Sex"` to
##'   keep sexes apart. Must contain `"Valid_Aphia"`.
##' @param zeros Logical. For `table = "HL"`: if `TRUE` (default), add a row
##'   with `Count = 0` for every haul in `HH` and species in `HL` without a
##'   record, so that averages over hauls include the hauls where a species was
##'   not caught.
##' @param ca_vars Character vector of `CA` columns to include for `table =
##'   "CA"`. Columns not found are omitted with a warning.
##'
##' @details
##' `vars`, `add_vars` and `remove_vars` always select `HH` variables; for
##' `table = "HL"` and `"CA"` they are attached to each row by `haul.id`. Columns
##' that exist in both tables (e.g. `Survey`, `Year`, `Quarter`) are taken once,
##' from `HH`.
##'
##' **`table = "HH"`.** In addition to
##' explicitly requested `vars`, `HaulN`, `HaulWgt`, and `SweptArea` are
##' always appended when present in `HH` (e.g. after calling
##' [add_total_numbers_by_haul()], [add_total_weight_by_haul()], or
##' [add_swept_area()]).
##'
##' Matrix columns such as `HaulN` or `HaulWgt` produced by passing
##' `length_cuts` to [add_total_numbers_by_haul()] or
##' [add_total_weight_by_haul()] are handled differently by each format:
##'
##' \itemize{
##'   \item `type = "long"`: matrix columns are expanded to one row per haul x
##'     length group. A `LengthGroup` column is added identifying the bin.
##'     All matrix columns must share the same bin structure.
##'   \item `type = "wide"`: matrix columns are expanded to one column per
##'     length bin, named `<variable>_<bin>` (e.g. `HaulN_(0-20]`).
##' }
##'
##' **`table = "HL"`.** `Count` is the raised number per haul computed by
##' DATRAS when the data are read (`HLNoAtLngt` times the sub-sampling factor,
##' and for `DataType = "C"` times `HaulDur / 60`), summed within each `hl_by`
##' group. The numbers are not rounded. [add_numbers_at_length()] (via
##' `DATRAS::addSpectrum()`) rounds each length class to whole fish, so the
##' `HaulN` of [add_total_numbers_by_haul()] can differ slightly from the sum
##' of `Count` over a haul. Records without a length (`LngtCm` NA, e.g.
##' catch-only records) are kept as rows with `LngtCm = NA`; their `Count` is NA
##' when no raised number is available, as the numbers are unknown rather than
##' zero. With `zeros = TRUE` the zero rows have `NA` in the other `hl_by`
##' columns, and the table has a row for every haul x species, which can be
##' large for many hauls and species: select species first, e.g. with
##' `clean_datras(aphias = )`.
##' \itemize{
##'   \item `type = "long"`: one row per haul x `hl_by` group.
##'   \item `type = "wide"`: one row per haul x species (x any other `hl_by`
##'     columns), with one column per length class named `Count_<LngtCm>`
##'     (e.g. `Count_25.5`) and 0 where no fish of that length was recorded.
##'     Records without a length go to a column `Count_NA`.
##' }
##' For a single species, the full haul x length grid is also available as
##' `as_table(x, add_vars = "N")` after [add_numbers_at_length()], with the
##' numbers rounded as described above.
##'
##' **`table = "CA"`.** One row per `CA` record. Records that could not be
##' matched to a haul (`haul.id` NA, see `strict` in [read_datras()]) are kept,
##' with the `HH` variables taken from the record where it has them and `NA`
##' otherwise, and their number is reported in a message. `type = "wide"` is
##' not available.
##'
##' For `table = "HL"` and `"CA"`, matrix columns of `HH` (`N`, or `HaulN` and
##' `HaulWgt` with `length_cuts`) are omitted with a warning, and `HaulN`,
##' `HaulWgt` and `SweptArea` are only included when requested in `vars` or
##' `add_vars`: a haul total repeated on every row is easily counted twice.
##'
##' @return A data frame in the requested format.
##'
##' @seealso [as_long_format()], [as_wide_format()]
##'
##' @examples
##' dab <- add_numbers_at_length(dab)
##' dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))
##'
##' ## Long format - one row per haul x length group
##' tab_long <- as_table(dab, type = "long")
##'
##' ## Wide format - one column per length group
##' tab_wide <- as_table(dab, type = "wide")
##'
##' ## Adjust the default column set
##' tab <- as_table(dab, add_vars = "Depth", remove_vars = "Ship")
##'
##' ## Numbers at length by haul and species, including zero catches
##' tab_hl <- as_table(dab, table = "HL", vars = c("Survey", "Year", "lon", "lat"))
##'
##' ## One row per haul and species, one column per length class
##' tab_hl_wide <- as_table(dab, table = "HL", type = "wide")
##'
##' ## Individual records with the haul position
##' tab_ca <- as_table(dab, table = "CA", vars = c("Year", "lon", "lat"))
##'
##' @export
as_table <- function(x,
                     vars = .default_hh_vars,
                     add_vars = NULL,
                     remove_vars = NULL,
                     type = "long",
                     table = c("HH", "HL", "CA"),
                     hl_by = c("Valid_Aphia", "LngtCm"),
                     zeros = TRUE,
                     ca_vars = .default_ca_vars) {

  .check_class_datras(x)
  table <- match.arg(table)

  if (!type %in% c("long", "wide")) stop("Unknown type. Use 'long' or 'wide'.")

  if (table == "HL") {
    return(.as_table_hl(x, vars = vars, add_vars = add_vars,
                        remove_vars = remove_vars, type = type,
                        hl_by = hl_by, zeros = zeros))
  }
  if (table == "CA") {
    if (type == "wide") stop("type = \"wide\" is not available for table = \"CA\".")
    return(.as_table_ca(x, vars = vars, add_vars = add_vars,
                        remove_vars = remove_vars, ca_vars = ca_vars))
  }

  if (type == "long") {
    x <- as_long_format(x, vars = vars, add_vars = add_vars,
                        remove_vars = remove_vars)
  } else if (type == "wide") {
    x <- as_wide_format(x, vars = vars, add_vars = add_vars,
                        remove_vars = remove_vars)
  } else {
    stop("Unknown type. Use 'long' or 'wide'.")
  }

  return(x)
}



##' Convert a `datras_raw` object to a long-format table
##'
##' Create a long-format data frame from the `HH` table of a
##' `datras_raw` / `DATRASraw` object. Matrix columns (e.g. `HaulN` or
##' `HaulWgt` produced with `length_cuts`) are expanded to one row per haul x
##' length group.
##'
##' @param x A `datras_raw` object.
##' @param vars Character vector of `HH` variable names to include. Defaults to
##'   15 common haul-level columns: `Survey`, `Gear`, `Country`, `Ship`,
##'   `Year`, `Quarter`, `Month`, `Day`, `lon`, `lat`, `timeOfYear`,
##'   `abstime`, `DayNight`, `TimeShotHour`, `HaulDur`.
##' @param add_vars Character vector of additional `HH` variable names to
##'   append to `vars`. Applied after `remove_vars`.
##' @param remove_vars Character vector of variable names to drop from `vars`.
##'   Applied before `add_vars`.
##'
##' @details
##' Only `HH` columns are used. In addition to the explicitly requested `vars`,
##' `HaulN`, `HaulWgt`, and `SweptArea` are always appended when present in
##' `HH`. Variables not found in `HH` are omitted with a warning.
##'
##' If any selected `HH` columns are matrices (produced by passing `length_cuts`
##' to [add_total_numbers_by_haul()] or [add_total_weight_by_haul()]), the
##' output is expanded to one row per haul x length group. A `LengthGroup`
##' column is added identifying the bin, and the matrix columns become scalar
##' columns. All matrix columns must share the same bin structure; an error is
##' raised if they differ.
##'
##' @return A data frame with one row per haul, or one row per haul x length
##'   group when matrix columns are present.
##'
##' @seealso [as_wide_format()], [as_table()]
##'
##' @examples
##' dab <- add_numbers_at_length(dab)
##' dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))
##'
##' ## Default columns plus auto-added HaulN, expanded to long
##' tab <- as_long_format(dab)
##'
##' ## Adjust columns
##' tab <- as_long_format(dab, add_vars = "Depth", remove_vars = "Ship")
##'
##' ## Scalar HaulN only (no length_cuts)
##' dab2 <- add_total_numbers_by_haul(dab)
##' tab <- as_long_format(dab2)
##'
##' @export
as_long_format <- function(x,
                           vars = .default_hh_vars,
                           add_vars = NULL,
                           remove_vars = NULL) {

  .check_class_datras(x)

  if (is.null(x[["HH"]]) || nrow(x[["HH"]]) == 0) {
    stop("x[['HH']] is missing or empty.")
  }

  res <- .prep_hh_vars(x, vars, add_vars, remove_vars)

  mat_cols <- names(res)[vapply(names(res),
                                function(nm) is.matrix(res[[nm]]), logical(1))]

  if (length(mat_cols) > 0) {

    bin_names_list <- lapply(mat_cols, function(mc) colnames(res[[mc]]))
    identical_bins <- length(unique(lapply(bin_names_list,
                                          paste, collapse = "\r"))) == 1L
    if (!identical_bins) {
      stop(
        "Matrix columns have different length-bin structures and cannot be ",
        "combined in long format: ",
        paste(mat_cols, collapse = ", "),
        ". Either select only one matrix column or ensure all use the same ",
        "length_cuts."
      )
    }

    bin_names <- bin_names_list[[1]]
    n_bins    <- length(bin_names)
    n_hauls   <- nrow(res)

    idx         <- rep(seq_len(n_hauls), each = n_bins)
    scalar_cols <- setdiff(names(res), mat_cols)
    res_exp     <- res[idx, scalar_cols, drop = FALSE]
    res_exp$LengthGroup <- rep(bin_names, times = n_hauls)

    for (mc in mat_cols) {
      res_exp[[mc]] <- as.vector(t(res[[mc]]))
    }

    other_cols <- setdiff(names(res_exp), c("LengthGroup", mat_cols))
    res <- res_exp[, c(other_cols, "LengthGroup", mat_cols), drop = FALSE]
  }

  rownames(res) <- NULL
  return(res)
}



##' Convert a `datras_raw` object to a wide-format table
##'
##' Create a wide-format data frame from the `HH` table of a
##' `datras_raw` / `DATRASraw` object. Matrix columns (e.g. `HaulN` or
##' `HaulWgt` produced with `length_cuts`) are expanded to one column per
##' length bin.
##'
##' @param x A `datras_raw` object.
##' @param vars Character vector of `HH` variable names to include. Defaults to
##'   15 common haul-level columns: `Survey`, `Gear`, `Country`, `Ship`,
##'   `Year`, `Quarter`, `Month`, `Day`, `lon`, `lat`, `timeOfYear`,
##'   `abstime`, `DayNight`, `TimeShotHour`, `HaulDur`.
##' @param add_vars Character vector of additional `HH` variable names to
##'   append to `vars`. Applied after `remove_vars`.
##' @param remove_vars Character vector of variable names to drop from `vars`.
##'   Applied before `add_vars`.
##'
##' @details
##' Only `HH` columns are used. In addition to the explicitly requested `vars`,
##' `HaulN`, `HaulWgt`, and `SweptArea` are always appended when present in
##' `HH`. Variables not found in `HH` are omitted with a warning.
##'
##' If any selected `HH` columns are matrices (produced by passing `length_cuts`
##' to [add_total_numbers_by_haul()] or [add_total_weight_by_haul()]), each
##' matrix is expanded to one column per length bin. Columns are named
##' `<variable>_<bin>`, e.g. `HaulN_(0-20]` and `HaulN_(20-Inf]`. Unlike
##' [as_long_format()], matrix columns with different bin structures are
##' permitted.
##'
##' @return A data frame with one row per haul.
##'
##' @seealso [as_long_format()], [as_table()]
##'
##' @examples
##' dab <- add_numbers_at_length(dab)
##' dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))
##'
##' ## Default columns plus auto-added HaulN, one column per length group
##' tab <- as_wide_format(dab)
##'
##' ## Adjust columns
##' tab <- as_wide_format(dab, add_vars = "Depth", remove_vars = "Ship")
##'
##' @export
as_wide_format <- function(x,
                           vars = .default_hh_vars,
                           add_vars = NULL,
                           remove_vars = NULL) {

  .check_class_datras(x)

  if (is.null(x[["HH"]]) || nrow(x[["HH"]]) == 0) {
    stop("x[['HH']] is missing or empty.")
  }

  res <- .prep_hh_vars(x, vars, add_vars, remove_vars)

  mat_cols <- names(res)[vapply(names(res),
                                function(nm) is.matrix(res[[nm]]), logical(1))]

  if (length(mat_cols) > 0) {

    scalar_cols <- setdiff(names(res), mat_cols)
    res_wide    <- res[, scalar_cols, drop = FALSE]

    for (mc in mat_cols) {
      mat      <- res[[mc]]
      new_cols <- paste0(mc, "_", colnames(mat))
      for (j in seq_along(new_cols)) {
        res_wide[[new_cols[j]]] <- mat[, j]
      }
    }

    res <- res_wide
  }

  rownames(res) <- NULL
  return(res)
}



##' Convert a `datras_raw` object to a tibble
##'
##' Method for [tibble::as_tibble()]: the same table as [as_table()], returned
##' as a tibble, so that `as_tibble(x)` and `x |> as_tibble()` work in tidyverse
##' workflows. All arguments of [as_table()] are available, including `table`
##' for the length (`HL`) and individual (`CA`) data.
##'
##' The method is registered when the tibble package is installed; tibble is
##' not required otherwise.
##'
##' @param x A `datras_raw` object.
##' @param ... Passed to [tibble::as_tibble()] for the converted table, e.g.
##'   `.name_repair`.
##' @inheritParams as_table
##'
##' @return A tibble. See [as_table()] for the rows and columns of each
##'   `table` and `type`.
##'
##' @seealso [as_table()], [as_long_format()], [as_wide_format()]
##'
##' @examples
##' if (requireNamespace("tibble", quietly = TRUE)) {
##'   dab <- add_numbers_at_length(dab)
##'   dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))
##'
##'   tibble::as_tibble(dab)
##'   tibble::as_tibble(dab, type = "wide", add_vars = "Depth")
##'   tibble::as_tibble(dab, table = "HL", vars = c("Year", "lon", "lat"))
##' }
##'
##' @exportS3Method tibble::as_tibble
as_tibble.datras_raw <- function(x,
                                 ...,
                                 vars = .default_hh_vars,
                                 add_vars = NULL,
                                 remove_vars = NULL,
                                 type = "long",
                                 table = c("HH", "HL", "CA"),
                                 hl_by = c("Valid_Aphia", "LngtCm"),
                                 zeros = TRUE,
                                 ca_vars = .default_ca_vars) {
  tab <- as_table(x, vars = vars, add_vars = add_vars,
                  remove_vars = remove_vars, type = type, table = table,
                  hl_by = hl_by, zeros = zeros, ca_vars = ca_vars)
  tibble::as_tibble(tab, ...)
}




## Internal functions for as_table(table = "HL" / "CA") ---------------------


.default_ca_vars <- c("Valid_Aphia", "Species", "LngtCm", "Sex", "Maturity",
                      "MaturityScale", "Age", "IndWgt", "NoAtALK")


## HH variables to attach to HL or CA rows: no auto-added haul totals, and no
## matrix columns, which have no meaning on a length or individual row.
.hh_vars_for_join <- function(x, vars, add_vars, remove_vars) {
  hh <- .prep_hh_vars(x, vars, add_vars, remove_vars, auto_add = FALSE)
  is_mat <- vapply(hh, is.matrix, logical(1))
  if (any(is_mat)) {
    warning("Matrix columns of HH cannot be attached to HL or CA rows and were ",
            "omitted: ", paste(names(hh)[is_mat], collapse = ", "))
    hh <- hh[, !is_mat, drop = FALSE]
  }
  hh
}


## Attach the HH variables to the rows of `d` by haul.id, keeping the row
## order of `d`. Columns in both are taken from HH; where a row has no haul in
## HH (unmatched CA records), they are taken from the row itself.
.join_hh <- function(hh, d) {
  idx <- match(as.character(d$haul.id), as.character(hh$haul.id))
  out <- hh[idx, , drop = FALSE]

  miss <- is.na(idx)
  shared <- setdiff(intersect(names(hh), names(d)), "haul.id")
  if (any(miss)) {
    out$haul.id <- d$haul.id
    for (k in shared) {
      v <- out[[k]]
      w <- d[[k]]
      if (is.factor(v) || is.factor(w)) {
        v <- as.character(v)
        v[miss] <- as.character(w[miss])
        out[[k]] <- factor(v)
      } else {
        v[miss] <- w[miss]
        out[[k]] <- v
      }
    }
  }

  own <- setdiff(names(d), c(names(hh), "haul.id"))
  out <- cbind(out, d[, own, drop = FALSE])
  rownames(out) <- NULL
  out
}


.as_table_hl <- function(x, vars, add_vars, remove_vars, type, hl_by, zeros) {

  hl <- x[["HL"]]
  if (is.null(hl)) stop("x has no HL table (was it read with drop_hl = TRUE?).")
  if (is.null(x[["HH"]]) || nrow(x[["HH"]]) == 0) stop("x[['HH']] is missing or empty.")
  if (!"Valid_Aphia" %in% hl_by) stop("hl_by must contain \"Valid_Aphia\".")
  missing_by <- setdiff(c(hl_by, "Count"), names(hl))
  if (length(missing_by) > 0) {
    stop("Columns not found in HL: ", paste(missing_by, collapse = ", "))
  }
  if ("LngtCm" %in% hl_by && nrow(hl) > 0 && !any(is.finite(hl$LngtCm))) {
    stop("HL has no lengths (LngtCm is all NA). Use hl_by = \"Valid_Aphia\" ",
         "for catch-only data.")
  }
  if (type == "wide" && !"LngtCm" %in% hl_by) {
    stop("type = \"wide\" for table = \"HL\" needs \"LngtCm\" in hl_by.")
  }

  hh <- .hh_vars_for_join(x, vars, add_vars, remove_vars)

  ## Sum the raised numbers within haul x hl_by groups. A group whose Count
  ## is NA throughout keeps NA: its numbers are unknown, not zero.
  keys <- c("haul.id", hl_by)
  g <- do.call(paste, c(lapply(hl[keys], as.character), sep = "\r"))
  first <- !duplicated(g)
  cnt <- as.numeric(hl$Count)
  total <- rowsum(cnt, g, reorder = FALSE, na.rm = TRUE)[, 1]
  n_ok <- rowsum(as.integer(!is.na(cnt)), g, reorder = FALSE)[, 1]
  agg <- hl[first, keys, drop = FALSE]
  agg$Count <- ifelse(n_ok > 0, total, NA_real_)
  rownames(agg) <- NULL

  ## Zero rows for hauls in HH where a species has no record
  if (isTRUE(zeros)) {
    hauls <- as.character(hh$haul.id)
    aphias <- unique(hl$Valid_Aphia)
    have <- paste(as.character(agg$haul.id), agg$Valid_Aphia, sep = "\r")
    grid <- expand.grid(haul = hauls, aphia = seq_along(aphias),
                        stringsAsFactors = FALSE)
    grid <- grid[!paste(grid$haul, aphias[grid$aphia], sep = "\r") %in% have, ]
    if (nrow(grid) > 0) {
      z <- agg[rep(NA_integer_, nrow(grid)), , drop = FALSE]
      z$haul.id <- factor(grid$haul, levels = levels(factor(hl$haul.id, levels = hauls)))
      z$Valid_Aphia <- aphias[grid$aphia]
      z$Count <- 0
      agg$haul.id <- factor(as.character(agg$haul.id), levels = levels(z$haul.id))
      agg <- rbind(agg, z)
    }
  }

  ## Species name for every row, including the zero rows
  if ("Species" %in% names(hl) && !"Species" %in% hl_by) {
    sp <- hl$Species[match(agg$Valid_Aphia, hl$Valid_Aphia)]
    agg <- data.frame(agg[, keys, drop = FALSE], Species = sp,
                      Count = agg$Count, stringsAsFactors = FALSE,
                      check.names = FALSE)
  }

  ## Hauls in HH order, then species and length
  ord_haul <- match(as.character(agg$haul.id), as.character(hh$haul.id))
  ord_cols <- c(list(ord_haul),
                lapply(agg[setdiff(hl_by, "LngtCm")], function(v) xtfrm(v)),
                if ("LngtCm" %in% hl_by) list(agg$LngtCm))
  agg <- agg[do.call(order, c(ord_cols, list(na.last = TRUE))), , drop = FALSE]
  rownames(agg) <- NULL

  if (type == "wide") agg <- .hl_wide(agg, hl_by)

  .join_hh(hh, agg)
}


## One row per haul x hl_by group without LngtCm, one Count_<LngtCm> column
## per length class (0 where none was recorded).
.hl_wide <- function(agg, hl_by) {
  keys <- c("haul.id", setdiff(hl_by, "LngtCm"))
  g <- do.call(paste, c(lapply(agg[keys], as.character), sep = "\r"))
  rows <- !duplicated(g)
  out <- agg[rows, setdiff(names(agg), c("LngtCm", "Count")), drop = FALSE]

  lens <- sort(unique(agg$LngtCm[!is.na(agg$LngtCm)]))
  has_na <- any(is.na(agg$LngtCm) & agg$Count != 0, na.rm = TRUE) ||
    any(is.na(agg$LngtCm) & is.na(agg$Count))
  col_of <- match(agg$LngtCm, lens)
  if (has_na) col_of[is.na(agg$LngtCm)] <- length(lens) + 1L

  m <- matrix(0, nrow = sum(rows), ncol = length(lens) + has_na)
  keep <- !is.na(col_of)
  m[cbind(match(g, g[rows])[keep], col_of[keep])] <- agg$Count[keep]
  colnames(m) <- paste0("Count_", c(format(lens, trim = TRUE, drop0trailing = TRUE),
                                    if (has_na) "NA"))

  out <- cbind(out, as.data.frame(m, check.names = FALSE))
  rownames(out) <- NULL
  out
}


.as_table_ca <- function(x, vars, add_vars, remove_vars, ca_vars) {

  ca <- x[["CA"]]
  if (is.null(ca)) stop("x has no CA table (was it read with drop_ca = TRUE?).")
  if (is.null(x[["HH"]]) || nrow(x[["HH"]]) == 0) stop("x[['HH']] is missing or empty.")

  missing_vars <- setdiff(ca_vars, names(ca))
  if (length(missing_vars) > 0) {
    warning("These variables were not found in CA and were omitted: ",
            paste(missing_vars, collapse = ", "))
  }
  ca_vars <- intersect(ca_vars, names(ca))

  hh <- .hh_vars_for_join(x, vars, add_vars, remove_vars)

  ## The HH columns are also needed from CA itself for unmatched records
  shared <- intersect(setdiff(names(hh), "haul.id"), names(ca))
  d <- ca[, unique(c("haul.id", shared, ca_vars)), drop = FALSE]

  n_unmatched <- sum(is.na(d$haul.id))
  if (n_unmatched > 0) {
    message(n_unmatched, " CA record(s) are not matched to a haul (haul.id NA); ",
            "they are kept with the HH variables available in CA.")
  }

  out <- .join_hh(hh, d)
  out[, unique(c(names(hh), ca_vars)), drop = FALSE]
}
