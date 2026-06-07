
## Main functions ----------------------------------------------------------------


##' Add ICES area information to a `datras_raw` object
##'
##' @description
##' Appends ICES area columns to the `HH` table of a `datras_raw` object by
##' matching `HH$StatRec` (ICES statistical rectangle codes, e.g. `"39F0"`)
##' against an internal lookup table derived from the official ICES shapefiles.
##'
##' The lookup is purely table-based and requires no spatial packages at
##' runtime.
##'
##' @param x A `datras_raw` object with a `StatRec` column in `HH`.
##' @param vars Character vector naming which area columns to add. Allowed
##'   values are any subset of `"Area_Full"`, `"Area_27"`, `"SubArea"`,
##'   `"Division"`, `"SubDivisio"`, `"Ecoregion"`. Defaults to
##'   `c("Area_Full", "Area_27", "Ecoregion")`.
##' @param verbose Logical; if `TRUE` (default), prints a message summarising
##'   how many hauls were matched.
##'
##' @details
##' The function matches on the `StatRec` column of `HH`. Hauls whose
##' `StatRec` code is not found in the lookup table (e.g. for surveys outside
##' the ICES area) receive `NA` in the added columns.
##'
##' If a requested column already exists in `HH`, it is overwritten.
##'
##' @return The input object `x` with the requested columns added (or
##'   overwritten) in `HH`.
##'
##' @examples
##' ## Add default columns (Area_Full, Area_27, Ecoregion)
##' dab2 <- add_ices_areas(dab)
##' head(dab2$HH[, c("StatRec", "Area_Full", "Area_27", "Ecoregion")])
##'
##' ## Add only Area_27
##' dab3 <- add_ices_areas(dab, vars = "Area_27")
##'
##' @seealso [add_species_info()]
##' @export
add_ices_areas <- function(x,
                           vars = c("Area_Full", "Area_27", "Ecoregion"),
                           verbose = TRUE) {

  .check_class_datras(x)

  allowed <- c("Area_Full", "Area_27", "SubArea", "Division",
               "SubDivisio", "Ecoregion")
  bad <- setdiff(vars, allowed)
  if (length(bad) > 0) {
    stop(
      "Unknown variable(s): ", paste(bad, collapse = ", "),
      ". Must be one of: ", paste(allowed, collapse = ", ")
    )
  }

  hh <- x[["HH"]]

  if (!"StatRec" %in% names(hh)) {
    stop("'HH' does not contain a 'StatRec' column.")
  }

  lookup <- get("ices_area_lookup", envir = asNamespace("DATRASextra"))

  idx <- match(as.character(hh[["StatRec"]]), lookup[["StatRec"]])

  hh[vars] <- lookup[idx, vars, drop = FALSE]
  rownames(hh) <- NULL

  if (verbose) {
    n_matched <- sum(!is.na(idx))
    n_total <- nrow(hh)
    message(
      "Matched ", n_matched, " of ", n_total, " hauls to ICES areas",
      if (n_matched < n_total)
        paste0(" (", n_total - n_matched, " unmatched -> NA)")
      else
        "."
    )
  }

  x[["HH"]] <- hh
  x
}
