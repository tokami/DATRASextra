## Main functions ----------------------------------------------------------------


##' Versions of the bundled reference tables
##'
##' Report which reference tables are distributed with the package, when they
##' were generated, what they were generated from, and whether they still match
##' the versions that were registered.
##'
##' The package ships lookup tables for species and life-history information,
##' survey coverage, spawning times and ICES area assignment. These are
##' snapshots of external sources taken at a particular time, so an analysis can
##' depend on how old they are. This function makes that visible, in the same
##' way [extraction()] does for the survey data itself.
##'
##' @param check Logical. If `TRUE` (default), hash each table and compare it
##'   with the hash recorded in the registry. Set to `FALSE` to skip hashing,
##'   which is faster for large tables.
##'
##' @details
##' Two kinds of table are reported. Tables marked `"exported"` are documented
##' data sets that users can load directly, such as [species_info]. Tables
##' marked `"internal"` are used by the package but not exported, such as the
##' statistical-rectangle to ICES-area lookup used by [add_ices_areas()].
##'
##' The example survey data sets (`dab`, `mini`, `wolffish`) are not reference
##' tables and are not reported here; use [extraction()] on those.
##'
##' When `check = TRUE`, the `status` column takes one of:
##' \itemize{
##'   \item `"ok"`: the table matches the registered hash,
##'   \item `"changed"`: the table has been regenerated since the registry was
##'     written, so `generated` and `source` may be out of date,
##'   \item `"unregistered"`: the table is present but absent from the registry,
##'   \item `"missing"`: the registry lists a table that is not available.
##' }
##'
##' Hashes are taken over the serialised object and are comparable within an
##' installation and between installations of the same package version. They are
##' intended to detect that a table has been regenerated, not as a
##' cryptographic guarantee across R versions.
##'
##' @return A data frame with one row per reference table and the columns
##'   `table`, `kind`, `rows`, `columns`, `generated`, `script`, `source`, and,
##'   when `check = TRUE`, `hash` and `status`.
##'
##' @seealso [extraction()], [verify_extraction()], [add_species_info()]
##'
##' @examples
##' ## Which reference tables are bundled, and how old are they
##' reference_tables()
##'
##' ## Skip hashing
##' reference_tables(check = FALSE)
##'
##' @export
reference_tables <- function(check = TRUE) {

  reg <- .read_reference_registry()
  live <- .reference_objects()

  nms <- union(reg$table, names(live))
  if (length(nms) == 0) return(.reference_empty())

  out <- data.frame(
    table = nms,
    kind = NA_character_,
    rows = NA_integer_,
    columns = NA_integer_,
    generated = as.Date(NA),
    script = NA_character_,
    source = NA_character_,
    stringsAsFactors = FALSE
  )

  i <- match(out$table, reg$table)
  for (nm in c("kind", "script", "source")) out[[nm]] <- reg[[nm]][i]
  out$generated <- reg$generated[i]

  for (k in seq_len(nrow(out))) {
    obj <- live[[out$table[k]]]
    if (is.null(obj)) next
    out$rows[k] <- if (!is.null(nrow(obj))) nrow(obj) else length(obj)
    out$columns[k] <- if (!is.null(ncol(obj))) ncol(obj) else NA_integer_
  }

  if (isTRUE(check)) {
    algo <- .hash_algo()
    out$hash <- NA_character_
    out$status <- NA_character_
    for (k in seq_len(nrow(out))) {
      obj <- live[[out$table[k]]]
      if (is.null(obj)) {
        out$status[k] <- "missing"
        next
      }
      out$hash[k] <- .hash_object(obj, algo)
      reg_hash <- if (is.na(i[k])) NA_character_ else reg$hash[i[k]]
      out$status[k] <- if (is.na(reg_hash)) {
        "unregistered"
      } else if (identical(reg_hash, out$hash[k])) {
        "ok"
      } else {
        "changed"
      }
    }
  }

  out <- out[order(out$kind, out$table), , drop = FALSE]
  rownames(out) <- NULL
  out
}



## Internal functions -----------------------------------------------------


.reference_empty <- function() {
  data.frame(
    table = character(0),
    kind = character(0),
    rows = integer(0),
    columns = integer(0),
    generated = as.Date(character(0)),
    script = character(0),
    source = character(0),
    hash = character(0),
    status = character(0),
    stringsAsFactors = FALSE
  )
}


## Descriptive metadata for each bundled reference table. Kept in code rather
## than in the registry file so that the registry can be regenerated from
## scratch; the generation date and hash are measured, not declared.
.reference_meta <- function() {
  list(
    species_info = list(
      kind = "exported",
      file = "data/species_info.rda",
      script = "data-raw/make_species_info.R",
      source = paste("WoRMS via the worrms package; FishBase via rfishbase;",
                     "DATRAS length-weight table (August 2023); functional",
                     "groups from Walker et al. (2017), van Denderen et al.",
                     "(2020) and Mildenberger et al. (2025)")
    ),
    survey_info = list(
      kind = "exported",
      file = "data/survey_info.rda",
      script = "data-raw/make_survey_info.R",
      source = "ICES DATRAS web service (getSurveyList and related endpoints)"
    ),
    survey_info_full_raw = list(
      kind = "exported",
      file = "data/survey_info_full_raw.rda",
      script = "data-raw/make_survey_info_full.R",
      source = "ICES DATRAS web service, haul positions by survey and year"
    ),
    spawning_info = list(
      kind = "exported",
      file = "data/spawning_info.rda",
      script = "data-raw/make_spawning_info.R",
      source = paste("length_at_maturity repository (GoFish and WKMAT),",
                     "https://github.com/federico-maioli/length_at_maturity")
    ),
    ices_area_lookup = list(
      kind = "internal",
      file = "R/sysdata.rda",
      script = "data-raw/make_ices_area_lookup.R",
      source = "ICES statistical rectangle and area shapefiles, https://gis.ices.dk"
    ),
    spread_models = list(
      kind = "internal",
      file = "R/sysdata.rda",
      script = "data-raw/spread_models.R",
      source = "Gear spread models fitted to DATRAS haul data by survey"
    )
  )
}


## Resolve the live objects. Exported data sets are lazy-loaded from the
## package namespace; internal tables live in sysdata.rda.
.reference_objects <- function() {
  meta <- .reference_meta()
  out <- lapply(names(meta), function(nm) {
    tryCatch(get(nm, envir = asNamespace("DATRASextra")),
             error = function(e) NULL)
  })
  names(out) <- names(meta)
  out[!vapply(out, is.null, logical(1))]
}


## Hash an R object by serialising it with a fixed format, so that the result
## does not depend on incidental session state.
.hash_object <- function(x, algo = .hash_algo()) {
  unname(algo$fun(bytes = serialize(x, NULL, version = 3L, xdr = TRUE)))
}


.reference_registry_path <- function() {
  system.file("reference_tables.dcf", package = "DATRASextra")
}


.read_reference_registry <- function(path = .reference_registry_path()) {

  empty <- data.frame(
    table = character(0), kind = character(0), script = character(0),
    source = character(0), generated = as.Date(character(0)),
    hash = character(0), algo = character(0), datrasextra = character(0),
    stringsAsFactors = FALSE
  )

  if (is.null(path) || !nzchar(path) || !file.exists(path)) return(empty)

  d <- tryCatch(as.data.frame(read.dcf(path), stringsAsFactors = FALSE),
                error = function(e) NULL)
  if (is.null(d) || nrow(d) == 0) return(empty)

  names(d) <- tolower(names(d))
  for (nm in names(empty)) if (!nm %in% names(d)) d[[nm]] <- NA_character_

  d$generated <- as.Date(d$generated)
  ## DCF folds long fields across lines; collapse the indentation back out.
  d$source <- gsub("\n[[:space:]]*", " ", d$source)

  d[names(empty)]
}


## Regenerate inst/reference_tables.dcf from the tables as they currently
## stand. Run from the package source tree after rebuilding any reference
## table, so that the recorded generation date and hash stay truthful.
.write_reference_registry <- function(pkg = ".",
                                      file = file.path(pkg, "inst",
                                                       "reference_tables.dcf")) {

  meta <- .reference_meta()
  live <- .reference_objects()
  algo <- .hash_algo()

  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)
  con <- file(file, open = "wt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)

  writeLines(c(
    "## Registry of the reference tables bundled with DATRASextra.",
    "## Regenerate with DATRASextra:::.write_reference_registry() after",
    "## rebuilding any table in data-raw/. Read with reference_tables().",
    ""), con)

  for (nm in names(meta)) {
    obj <- live[[nm]]
    if (is.null(obj)) next
    m <- meta[[nm]]

    rec <- c(
      Table = nm,
      Kind = m$kind,
      Script = m$script,
      Source = m$source,
      Generated = format(.file_date(file.path(pkg, m$file))),
      Hash = .hash_object(obj, algo),
      Algo = algo$name,
      Datrasextra = as.character(utils::packageVersion("DATRASextra"))
    )
    write.dcf(t(as.matrix(rec)), con, width = 76, indent = 2)
    writeLines("", con)
  }

  message("Wrote reference registry: ", file)
  invisible(file)
}


## Best available evidence for when a built table entered the package: the date
## of the commit that last touched it, falling back to the file's modification
## time when git is unavailable.
.file_date <- function(path) {

  if (!file.exists(path)) return(as.Date(NA))

  d <- tryCatch({
    out <- suppressWarnings(system2(
      "git", c("-C", shQuote(dirname(path)), "log", "-1", "--format=%ad",
               "--date=short", "--", shQuote(basename(path))),
      stdout = TRUE, stderr = FALSE))
    if (length(out) == 0 || !nzchar(out[1])) NA else as.Date(out[1])
  }, error = function(e) as.Date(NA))

  if (is.na(d)) d <- as.Date(file.info(path)$mtime)
  d
}
