
## Main functions ----------------------------------------------------------------

.default_hh_vars <- c(
  "Survey", "Gear", "Country", "Ship", "Year",
  "Quarter", "Month", "Day", "lon", "lat",
  "timeOfYear", "abstime", "DayNight",
  "TimeShotHour", "HaulDur"
)

.prep_hh_vars <- function(x, vars, add_vars, remove_vars) {
  hh <- x[["HH"]]

  if (!is.null(remove_vars)) vars <- setdiff(vars, remove_vars)
  if (!is.null(add_vars))    vars <- unique(c(vars, add_vars))

  auto_candidates <- c("HaulN", "HaulWgt", "SweptArea")
  auto_add <- setdiff(intersect(auto_candidates, names(hh)), vars)
  if (!is.null(remove_vars)) auto_add <- setdiff(auto_add, remove_vars)
  vars <- unique(c(vars, auto_add))

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
##' Convert a `datras_raw` / `DATRASraw` object to either long or wide tabular
##' format using haul-level (`HH`) variables only.
##'
##' This is a convenience wrapper around [as_long_format()] and
##' [as_wide_format()].
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
##'   (default) or `"wide"`.
##'
##' @details
##' Both functions only use columns from the `HH` table. In addition to
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
##' @export
as_table <- function(x,
                     vars = .default_hh_vars,
                     add_vars = NULL,
                     remove_vars = NULL,
                     type = "long") {

  .check_class_datras(x)

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
