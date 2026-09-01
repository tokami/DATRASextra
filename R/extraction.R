## Main functions ----------------------------------------------------------------


##' Extraction record of a `datras_raw` object
##'
##' Return the table describing where the data in a `datras_raw` /
##' `DATRASraw` object came from, when it was extracted from ICES DATRAS, and
##' which software produced it.
##'
##' The record has one row per source unit, that is per survey, year and
##' quarter. This is the granularity at which ICES calculates and revises the
##' database, and the granularity at which survey-year files can be downloaded
##' on different dates.
##'
##' @param x A `datras_raw` object.
##'
##' @details
##' The most important column is `date_of_calculation`, taken from the DATRAS
##' field `DateofCalculation`. It records when ICES last recalculated that block
##' of records and is therefore the only reliable indicator that data have been
##' revised upstream. Because it is supplied by ICES rather than generated
##' locally, it can be compared between two extractions made at any time. The
##' field is not populated for every survey-year-quarter, most often for
##' historical data; where it is missing, an upstream revision can only be
##' detected through the file checksum.
##'
##' The remaining columns fall into three groups:
##' \itemize{
##'   \item identification: `survey`, `year`, `quarter`, `file`,
##'   \item extraction: `extracted` (when the data were retrieved), `source`
##'     (`"api"`, `"php"` or `"file"`) and `endpoint`,
##'   \item verification and software: `payload_hash`, `zip_hash`, `algo`,
##'     `read`, `datrasextra`, `datras`, `icesdatras` and `r_version`.
##' }
##'
##' When an object was created before this information was recorded, or read
##' from an archive without a manifest, the identification columns and
##' `date_of_calculation` are still reconstructed from the data themselves and
##' the remaining columns are `NA`.
##'
##' `survey` and `extracted` are the two fields required by the ICES citation
##' format, so the record can be formatted directly into a data citation.
##'
##' @return A data frame with one row per survey, year and quarter. A zero-row
##'   data frame with the same columns is returned when no information is
##'   available.
##'
##' @seealso [write_manifest()], [read_manifest()], [verify_extraction()],
##'   [read_datras()], [download_datras()]. For the age of the lookup tables
##'   bundled with the package rather than of the survey data, see
##'   [reference_tables()].
##'
##' @examples
##' ## Reconstructed from the data even for objects created before this
##' ## information was recorded
##' extraction(mini)
##'
##' \dontrun{
##' ## Format an ICES data citation
##' e <- extraction(x)
##' sprintf("ICES Database of Trawl Surveys (DATRAS), Extraction %s of %s. ICES, Copenhagen",
##'         format(max(e$extracted), "%d %B %Y"),
##'         paste(unique(e$survey), collapse = ", "))
##' }
##'
##' @export
extraction <- function(x) {
  .check_class_datras(x)

  out <- attr(x, "extraction")

  ## Objects created before extraction records existed, or read from an archive
  ## without a manifest, can still be described from the data themselves.
  if (is.null(out) || !is.data.frame(out) || nrow(out) == 0) {
    return(.extraction_from_data(x))
  }

  ## Subsetting a DATRAS object does not touch its attributes, so a stored
  ## record can outlive the data it describes. Reconcile it with what is
  ## actually present rather than reporting sources the object no longer holds.
  .extraction_restrict(out, x)
}


##' Write a manifest for an archive of DATRAS exchange files
##'
##' Scan a directory of zipped DATRAS exchange files, compute a checksum for
##' each, read the ICES calculation date from each, and write the result to
##' `DATRAS_manifest.csv` in the root of the archive.
##'
##' The manifest makes a local snapshot verifiable: two users can confirm that
##' they hold identical data without anyone hosting anything, and a later
##' comparison shows which survey-year files ICES has revised since the archive
##' was created.
##'
##' @param path Character string giving the root directory of the archive.
##' @param recursive Logical. If `TRUE` (default), search subdirectories. A
##'   standard archive written by [download_datras()] stores files in
##'   survey-specific subdirectories.
##' @param file Character string giving the name of the manifest file, relative
##'   to `path`. Defaults to `"DATRAS_manifest.csv"`.
##' @param verbose Logical. If `TRUE` (default), show a progress bar.
##'
##' @details
##' The checksum is computed over the *contents* of the exchange file inside the
##' zip archive, not over the zip archive itself. Zip archives embed the
##' modification time of the file they contain, so re-writing identical data
##' produces a different zip archive but the same payload checksum. The checksum
##' of the zip archive is recorded as well, as a check on file transfer.
##'
##' SHA-256 is used where available and MD5 otherwise; the algorithm used is
##' recorded in the `algo` column so that manifests remain self-describing.
##'
##' Scanning is not free, since each file must be decompressed and read. Expect
##' on the order of a minute for a complete DATRAS archive of around 650 files.
##'
##' @return The manifest, invisibly, as a data frame with one row per survey,
##'   year and quarter.
##'
##' @seealso [read_manifest()], [verify_extraction()], [extraction()]
##'
##' @examples
##' \dontrun{
##' ## Create a manifest for an existing archive
##' write_manifest("data/datras")
##' }
##'
##' @export
write_manifest <- function(path,
                           recursive = TRUE,
                           file = "DATRAS_manifest.csv",
                           verbose = TRUE) {

  path <- normalizePath(path.expand(path), mustWork = TRUE)

  zips <- dir(path, pattern = "\\.zip$", recursive = recursive,
              full.names = TRUE)
  if (length(zips) == 0) {
    stop("No zip files found under: ", path)
  }

  algo <- .hash_algo()
  out <- vector("list", length(zips))

  if (verbose) pb <- txtProgressBar(min = 0, max = length(zips), style = 3)
  for (i in seq_along(zips)) {
    out[[i]] <- .scan_exchange_zip(zips[i], root = path, algo = algo)
    if (verbose) setTxtProgressBar(pb, i)
  }
  if (verbose) close(pb)

  man <- do.call(rbind, out)
  if (is.null(man)) man <- .extraction_empty()

  man$source <- "file"
  man$read <- as.POSIXct(NA)
  man <- .extraction_fill_versions(man)

  target <- file.path(path, file)
  utils::write.csv(man, target, row.names = FALSE, na = "")
  if (verbose) message("Wrote manifest with ", nrow(man), " entries: ", target)

  invisible(man)
}


##' Read the manifest of a DATRAS archive
##'
##' @param path Character string giving the root directory of the archive.
##' @param file Character string giving the name of the manifest file, relative
##'   to `path`. Defaults to `"DATRAS_manifest.csv"`.
##'
##' @return A data frame with one row per survey, year and quarter. A zero-row
##'   data frame with the same columns is returned when no manifest is present.
##'
##' @seealso [write_manifest()], [verify_extraction()]
##'
##' @examples
##' \dontrun{
##' read_manifest("data/datras")
##' }
##'
##' @export
read_manifest <- function(path, file = "DATRAS_manifest.csv") {

  target <- file.path(path.expand(path), file)
  if (!file.exists(target)) return(.extraction_empty())

  man <- utils::read.csv(target, stringsAsFactors = FALSE,
                         colClasses = "character")

  .extraction_coerce(man)
}


##' Verify a DATRAS archive against its manifest
##'
##' Recompute the checksum of every exchange file in an archive and compare it
##' with the manifest, reporting files that have changed, are missing, or are
##' not listed.
##'
##' @param path Character string giving the root directory of the archive.
##' @param manifest Optional manifest to compare against, as returned by
##'   [read_manifest()]. If `NULL` (default), the manifest stored in `path` is
##'   used.
##' @param recursive Logical. If `TRUE` (default), search subdirectories.
##' @param verbose Logical. If `TRUE` (default), print a summary and show a
##'   progress bar.
##'
##' @details
##' Two kinds of difference are distinguished, because they have different
##' causes and different remedies:
##' \itemize{
##'   \item a changed `payload_hash` with an unchanged `date_of_calculation`
##'     indicates a local problem, such as a corrupted or partially transferred
##'     file,
##'   \item a changed `date_of_calculation` indicates that ICES has revised the
##'     data upstream. This is the case that silently changes results and is the
##'     reason the manifest is worth keeping.
##' }
##'
##' @return A data frame, invisibly, with one row per file and a `status`
##'   column taking the values `"ok"`, `"changed"`, `"revised"`, `"missing"` or
##'   `"new"`.
##'
##' @seealso [write_manifest()], [read_manifest()], [extraction()]
##'
##' @examples
##' \dontrun{
##' ## Check that an archive still matches its manifest
##' verify_extraction("data/datras")
##' }
##'
##' @export
verify_extraction <- function(path,
                              manifest = NULL,
                              recursive = TRUE,
                              verbose = TRUE) {

  path <- normalizePath(path.expand(path), mustWork = TRUE)

  if (is.null(manifest)) manifest <- read_manifest(path)
  if (nrow(manifest) == 0) {
    stop("No manifest found in ", path,
         ". Create one with write_manifest().")
  }

  zips <- dir(path, pattern = "\\.zip$", recursive = recursive,
              full.names = TRUE)

  algo <- .hash_algo()
  cur <- vector("list", length(zips))
  if (verbose && length(zips) > 0) {
    pb <- txtProgressBar(min = 0, max = length(zips), style = 3)
  }
  for (i in seq_along(zips)) {
    cur[[i]] <- .scan_exchange_zip(zips[i], root = path, algo = algo)
    if (verbose) setTxtProgressBar(pb, i)
  }
  if (verbose && length(zips) > 0) close(pb)

  cur <- do.call(rbind, cur)
  if (is.null(cur)) cur <- .extraction_empty()

  ## Compare on the survey-year-quarter key
  key <- function(d) paste(d$survey, d$year, d$quarter, sep = ":")
  manifest$.key <- key(manifest)
  cur$.key <- key(cur)

  res <- merge(manifest[c(".key", "file", "payload_hash", "date_of_calculation")],
               cur[c(".key", "payload_hash", "date_of_calculation")],
               by = ".key", all = TRUE, suffixes = c("_manifest", "_current"))

  res$status <- ifelse(
    is.na(res$payload_hash_current), "missing",
    ifelse(is.na(res$payload_hash_manifest), "new",
           ifelse(!.same(res$date_of_calculation_manifest,
                         res$date_of_calculation_current), "revised",
                  ifelse(.same(res$payload_hash_manifest,
                               res$payload_hash_current), "ok", "changed"))))

  res$.key <- NULL
  res <- res[order(match(res$status, c("revised", "changed", "missing", "new", "ok")),
                   res$file), , drop = FALSE]
  rownames(res) <- NULL

  if (verbose) {
    tab <- table(factor(res$status,
                        levels = c("ok", "revised", "changed", "missing", "new")))
    message("Verified ", nrow(res), " entries against the manifest:")
    message(paste(paste0("  ", names(tab), ": ", as.integer(tab)),
                  collapse = "\n"))
    if (tab[["revised"]] > 0) {
      message("\nRevised entries have a different ICES calculation date, ",
              "meaning the data were changed upstream. Re-download to update.")
    }
    if (tab[["changed"]] > 0) {
      message("\nChanged entries have the same ICES calculation date but ",
              "different contents, which usually indicates a local file problem.")
    }
  }

  invisible(res)
}



## Internal functions -----------------------------------------------------


## The empty template. Every function that returns an extraction record returns
## these columns in this order, so that rbind() across sources always works.
.extraction_empty <- function() {
  data.frame(
    survey = character(0),
    year = integer(0),
    quarter = integer(0),
    date_of_calculation = as.Date(character(0)),
    extracted = as.POSIXct(character(0)),
    source = character(0),
    endpoint = character(0),
    file = character(0),
    payload_hash = character(0),
    zip_hash = character(0),
    algo = character(0),
    read = as.POSIXct(character(0)),
    datrasextra = character(0),
    datras = character(0),
    icesdatras = character(0),
    r_version = character(0),
    stringsAsFactors = FALSE
  )
}


## SHA-256 where available, MD5 otherwise. tools::sha256sum() is not present in
## older R versions, and the package supports R >= 4.0, so the function is
## looked up rather than referenced directly.
.hash_algo <- function() {
  ns <- asNamespace("tools")
  if (exists("sha256sum", envir = ns, inherits = FALSE)) {
    list(fun = get("sha256sum", envir = ns), name = "sha256")
  } else {
    list(fun = tools::md5sum, name = "md5")
  }
}


## Hash the exchange file inside a zip archive, and the archive itself.
##
## The payload hash is the meaningful one: utils::zip() stores the modification
## time of the file it compresses, so writing identical data twice produces
## different zip bytes but an identical payload.
.hash_payload <- function(zipfile, algo = .hash_algo()) {

  out <- c(payload_hash = NA_character_, zip_hash = NA_character_)
  if (!file.exists(zipfile)) return(out)

  out[["zip_hash"]] <- unname(algo$fun(zipfile))

  td <- tempfile(pattern = "datras_hash_")
  dir.create(td, showWarnings = FALSE)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  csv <- tryCatch(utils::unzip(zipfile, exdir = td)[1],
                  error = function(e) NA_character_)
  if (!is.na(csv) && file.exists(csv)) {
    out[["payload_hash"]] <- unname(algo$fun(csv))
  }

  out
}


## Parse the DATRAS DateofCalculation field, stored as a YYYYMMDD integer.
## Historical files can leave it empty.
.parse_date_of_calculation <- function(v) {
  s <- trimws(as.character(v))
  s[!nzchar(s) | s %in% c("NA", "-9")] <- NA_character_
  as.Date(s, format = "%Y%m%d")
}


## Derive what can be known from the data alone: which survey, year and quarter
## the records belong to, and when ICES last calculated them. This is what makes
## the feature work on archives and objects that predate it.
.extraction_from_data <- function(x, file = NA_character_) {

  need <- c("Survey", "Year", "Quarter")

  ## Prefer a table that also carries DateofCalculation; prune_datras() keeps it
  ## in HH only, and older objects may not have it at all.
  d <- NULL
  for (want_doc in c(TRUE, FALSE)) {
    for (tab in c("HH", "HL", "CA")) {
      cand <- x[[tab]]
      if (is.null(cand) || !is.data.frame(cand) || nrow(cand) == 0) next
      if (!all(need %in% names(cand))) next
      if (want_doc && !"DateofCalculation" %in% names(cand)) next
      d <- cand
      break
    }
    if (!is.null(d)) break
  }

  if (is.null(d)) return(.extraction_empty())

  doc <- if ("DateofCalculation" %in% names(d)) {
    .parse_date_of_calculation(d$DateofCalculation)
  } else {
    rep(as.Date(NA), nrow(d))
  }

  out <- unique(data.frame(
    survey = as.character(d$Survey),
    year = suppressWarnings(as.integer(as.character(d$Year))),
    quarter = suppressWarnings(as.integer(as.character(d$Quarter))),
    date_of_calculation = doc,
    stringsAsFactors = FALSE
  ))

  out <- out[order(out$survey, out$year, out$quarter), , drop = FALSE]
  rownames(out) <- NULL

  .extraction_pad(out, file = file)
}


## Add the columns of the template that a partial record does not supply.
.extraction_pad <- function(d, ...) {

  tmpl <- .extraction_empty()
  extra <- list(...)

  ## Assigning a scalar into a zero-row data frame is an error, and a record
  ## with no rows has nothing to pad anyway.
  if (nrow(d) == 0) return(tmpl)

  for (nm in names(tmpl)) {
    if (nm %in% names(d)) next
    d[[nm]] <- if (nm %in% names(extra)) extra[[nm]] else tmpl[[nm]][NA_integer_]
  }

  d[names(tmpl)]
}


## Record the software that produced the object.
.extraction_fill_versions <- function(d) {
  if (nrow(d) == 0) return(d)
  d$datrasextra <- as.character(utils::packageVersion("DATRASextra"))
  d$datras <- tryCatch(as.character(utils::packageVersion("DATRAS")),
                       error = function(e) NA_character_)
  d$icesdatras <- tryCatch(as.character(utils::packageVersion("icesDatras")),
                           error = function(e) NA_character_)
  d$r_version <- paste(R.version$major, R.version$minor, sep = ".")
  d
}


## Read one zip archive far enough to describe it: checksums plus the survey,
## year, quarter and ICES calculation date it contains.
.scan_exchange_zip <- function(zipfile, root = NULL, algo = .hash_algo()) {

  rel <- if (is.null(root)) basename(zipfile) else {
    sub(paste0("^", .escape_regex(root), .Platform$file.sep), "", zipfile)
  }

  td <- tempfile(pattern = "datras_scan_")
  dir.create(td, showWarnings = FALSE)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  csv <- tryCatch(utils::unzip(zipfile, exdir = td)[1],
                  error = function(e) NA_character_)
  if (is.na(csv) || !file.exists(csv)) {
    return(.extraction_pad(.extraction_empty(), file = rel))
  }

  hashes <- c(payload_hash = unname(algo$fun(csv)),
              zip_hash = unname(algo$fun(zipfile)))

  keys <- .exchange_keys(csv)
  if (nrow(keys) == 0) {
    return(.extraction_pad(.extraction_empty(), file = rel))
  }

  .extraction_pad(keys,
                  file = rel,
                  payload_hash = hashes[["payload_hash"]],
                  zip_hash = hashes[["zip_hash"]],
                  algo = algo$name)
}


## Extract the distinct survey / year / quarter / DateofCalculation
## combinations from an exchange CSV.
##
## The file holds several stacked blocks, each with its own header line. All
## three blocks carry the same calculation date for a given survey, year and
## quarter, so only the first block is needed and reading stops as soon as it
## ends. That matters: HH is a few hundred rows where HL can be over a hundred
## thousand, and reading whole files would make scanning an archive slow.
.exchange_keys <- function(csvfile, chunk = 5000L, max_lines = 5e6) {

  con <- file(csvfile, open = "rt")
  on.exit(close(con), add = TRUE)

  buf <- character(0)
  hdr <- integer(0)

  ## Read until a second header appears, marking the end of the first block.
  while (length(hdr) < 2L && length(buf) < max_lines) {
    lines <- readLines(con, n = chunk, warn = FALSE)
    if (length(lines) == 0) break
    buf <- c(buf, lines)
    hdr <- grep("^RecordType", buf)
  }

  if (length(hdr) == 0) return(.extraction_empty()[1:4])

  first <- hdr[1]
  last <- if (length(hdr) > 1) hdr[2] - 1L else length(buf)
  if (last <= first) return(.extraction_empty()[1:4])

  nms <- strsplit(buf[first], ",", fixed = TRUE)[[1]]
  want <- c("Survey", "Year", "Quarter", "DateofCalculation")
  idx <- match(want, nms)
  if (any(is.na(idx[1:3]))) return(.extraction_empty()[1:4])

  block <- strsplit(buf[(first + 1L):last], ",", fixed = TRUE)
  pick <- function(j) {
    if (is.na(j)) return(rep(NA_character_, length(block)))
    vapply(block, function(p) if (length(p) >= j) p[j] else NA_character_,
           character(1))
  }

  res <- unique(data.frame(
    survey = pick(idx[1]),
    year = suppressWarnings(as.integer(pick(idx[2]))),
    quarter = suppressWarnings(as.integer(pick(idx[3]))),
    date_of_calculation = .parse_date_of_calculation(pick(idx[4])),
    stringsAsFactors = FALSE
  ))

  ## Drop rows that carry no usable key. Trailing blank lines and truncated
  ## records both produce these, and they are not sources in any real sense.
  ok <- !is.na(res$survey) & nzchar(trimws(res$survey)) &
    !is.na(res$year) & !is.na(res$quarter)
  res <- res[ok, , drop = FALSE]

  res <- res[order(res$survey, res$year, res$quarter), , drop = FALSE]
  rownames(res) <- NULL
  res
}


## The ICES DATRAS web service base address, recorded so that an extraction can
## be traced to the service it came from.
.datras_endpoint <- function() {
  "https://datras.ices.dk/WebServices/DATRASWebService.asmx/"
}


## Locate an archive manifest. read_datras() may be pointed at the archive root
## or at a single survey subdirectory within it, so both are checked.
.find_manifest <- function(root, file = "DATRAS_manifest.csv") {

  if (is.null(root) || is.na(root) || !nzchar(root)) return(.extraction_empty())

  for (dir in unique(c(root, dirname(root)))) {
    if (file.exists(file.path(dir, file))) return(read_manifest(dir, file = file))
  }

  .extraction_empty()
}


## Build the record attached by read_datras(). Deriving the keys from the data
## is essentially free; checksums are taken from the manifest rather than
## recomputed, so that reading stays fast.
.extraction_on_read <- function(x, root = NULL) {

  rec <- tryCatch(.extraction_from_data(x), error = function(e) NULL)
  if (is.null(rec) || nrow(rec) == 0) return(x)

  man <- tryCatch(.find_manifest(root), error = function(e) .extraction_empty())

  if (nrow(man) > 0) {
    key <- function(d) paste(d$survey, d$year, d$quarter, sep = ":")
    i <- match(key(rec), key(man))
    for (nm in c("extracted", "source", "endpoint", "file",
                 "payload_hash", "zip_hash", "algo")) {
      rec[[nm]] <- man[[nm]][i]
    }
  }

  rec$read <- Sys.time()
  rec <- .extraction_fill_versions(rec)

  attr(x, "extraction") <- rec
  x
}


## Reconcile a stored record with the survey-year-quarters still present in the
## data: drop rows describing records that have been filtered out, and add rows
## for data that the stored record does not cover.
.extraction_restrict <- function(record, x) {

  present <- tryCatch(.extraction_from_data(x), error = function(e) NULL)
  if (is.null(present) || nrow(present) == 0) return(record)

  key <- function(d) paste(d$survey, d$year, d$quarter, sep = ":")
  keep <- record[key(record) %in% key(present), , drop = FALSE]

  missing <- present[!key(present) %in% key(keep), , drop = FALSE]
  if (nrow(missing) > 0) {
    tmpl <- names(.extraction_empty())
    keep <- rbind(keep[tmpl], .extraction_pad(missing)[tmpl])
  }

  if (nrow(keep) == 0) return(record)

  keep <- keep[order(keep$survey, keep$year, keep$quarter), , drop = FALSE]
  rownames(keep) <- NULL
  keep
}


## Combine extraction records from several objects, as when survey-year files
## are read separately and combined with c().
.extraction_merge <- function(...) {

  args <- list(...)
  recs <- lapply(args, function(a) {
    if (is.null(a)) return(NULL)
    r <- attr(a, "extraction")
    if (is.null(r) || !is.data.frame(r) || nrow(r) == 0) {
      r <- tryCatch(.extraction_from_data(a), error = function(e) NULL)
    }
    r
  })

  recs <- recs[!vapply(recs, is.null, logical(1))]
  recs <- recs[vapply(recs, nrow, integer(1)) > 0]
  if (length(recs) == 0) return(.extraction_empty())

  tmpl <- names(.extraction_empty())
  recs <- lapply(recs, function(r) .extraction_pad(r)[tmpl])

  out <- do.call(rbind, recs)
  out <- unique(out)
  out <- out[order(out$survey, out$year, out$quarter), , drop = FALSE]
  rownames(out) <- NULL
  out
}


## Build an extraction record for an object, overriding derived columns with
## anything supplied by the caller.
.extraction_record <- function(x, record = NULL, ...) {

  if (is.null(record)) record <- .extraction_from_data(x)
  record <- .extraction_pad(record, ...)

  if (nrow(record) > 0) {
    extra <- list(...)
    for (nm in names(extra)) {
      if (nm %in% names(record)) record[[nm]] <- extra[[nm]]
    }
    record <- .extraction_fill_versions(record)
  }

  record
}


## Attach an extraction record, merging with anything already present.
.extraction_stamp <- function(x, record = NULL, ...) {

  record <- .extraction_record(x, record = record, ...)

  existing <- attr(x, "extraction")
  if (!is.null(existing) && is.data.frame(existing) && nrow(existing) > 0) {
    tmpl <- names(.extraction_empty())
    record <- unique(rbind(.extraction_pad(existing)[tmpl], record[tmpl]))
    rownames(record) <- NULL
  }

  attr(x, "extraction") <- record
  x
}


## Combine already-built records and fold them into the manifest of an archive,
## replacing any earlier entry for the same survey, year and quarter.
.update_manifest <- function(path, records, file = "DATRAS_manifest.csv",
                             verbose = TRUE) {

  records <- records[vapply(records, function(r) !is.null(r) && nrow(r) > 0,
                            logical(1))]
  if (length(records) == 0) return(invisible(.extraction_empty()))

  tmpl <- names(.extraction_empty())
  new <- do.call(rbind, lapply(records, function(r) r[tmpl]))

  old <- tryCatch(read_manifest(path, file = file),
                  error = function(e) .extraction_empty())

  key <- function(d) paste(d$survey, d$year, d$quarter, sep = ":")
  if (nrow(old) > 0) {
    old <- old[!key(old) %in% key(new), , drop = FALSE]
    new <- rbind(old[tmpl], new)
  }

  new <- new[order(new$survey, new$year, new$quarter), , drop = FALSE]
  rownames(new) <- NULL

  target <- file.path(path, file)
  utils::write.csv(new, target, row.names = FALSE, na = "")
  if (verbose) message("Updated manifest (", nrow(new), " entries): ", target)

  invisible(new)
}


## Restore column types after a round trip through CSV.
.extraction_coerce <- function(d) {

  tmpl <- .extraction_empty()
  for (nm in names(tmpl)) {
    if (!nm %in% names(d)) d[[nm]] <- NA
    v <- d[[nm]]
    d[[nm]] <- switch(
      nm,
      year = suppressWarnings(as.integer(v)),
      quarter = suppressWarnings(as.integer(v)),
      date_of_calculation = as.Date(.blank_to_na(v)),
      extracted = as.POSIXct(.blank_to_na(v)),
      read = as.POSIXct(.blank_to_na(v)),
      .blank_to_na(as.character(v))
    )
  }

  d[names(tmpl)]
}


.blank_to_na <- function(v) {
  v <- as.character(v)
  v[!nzchar(trimws(v))] <- NA_character_
  v
}


## NA-safe equality, used when comparing a manifest against a rescan.
.same <- function(a, b) {
  (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
}


.escape_regex <- function(x) {
  gsub("([.\\\\|()\\[\\]{}^$*+?])", "\\\\\\1", x, perl = TRUE)
}
