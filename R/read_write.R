
## Main functions ----------------------------------------------------------------

##' Read ICES DATRAS survey data from zipped exchange files
##'
##' Read one or more ICES DATRAS exchange files, or all zipped exchange files in
##' one or more directories, into a single `datras_raw` / `DATRASraw` object.
##'
##' The function can read:
##' \itemize{
##'   \item one or more individual `.zip` files,
##'   \item one or more directories containing `.zip` files,
##'   \item optionally only files matching selected years.
##' }
##'
##' Small zip files can be excluded using `min_file_size`, as unusually small
##' files are often incomplete or corrupted and may fail in the underlying
##' DATRAS reader functions.
##'
##' @param path A character vector of file or directory paths. Each element can
##'   point either to an individual DATRAS `.zip` exchange file or to a directory
##'   containing such files.
##' @param surveys Optional character vector of survey acronyms to read (e.g.
##'   `c("NS-IBTS", "BITS")`). When supplied and `path` contains directories,
##'   only zip files whose **immediate parent folder name** exactly matches one
##'   of the specified strings are read. This avoids false matches between
##'   similarly named folders (e.g. `"NS-IBTS"` will not match `"NS-IBTS_old"`).
##'   Matching is case-sensitive.
##' @param years Optional integer vector of years to read. When supplied and
##'   `path` contains directories, only zip files matching those years are
##'   read.
##' @param recursive logical. Should the listing recurse into directories?
##'   (Default: `TRUE`).
##' @param min_file_size Minimum file size in bytes. Files smaller than this
##'   threshold are excluded because they are likely incomplete or invalid and
##'   may cause errors when being read. Defaults to `1e4`.
##' @param prune Logical. If `TRUE`, only core columns are retained using
##'   [prune_datras()] before combining files. This can substantially reduce
##'   memory use when reading many files.
##' @param drop_hl Logical. If `TRUE`, the `HL` (length-frequency) table is set
##'   to `NULL` after reading each file. Use this when only haul metadata is
##'   needed, as `HL` is often the largest table. Can be combined with `prune`.
##' @param drop_ca Logical. If `TRUE`, the `CA` (biological sampling) table is
##'   set to `NULL` after reading each file. Can be combined with `prune` and
##'   `drop_hl`.
##' @param strict Logical. Controls how records in `CA` without a haul
##'   identifier are matched back to a haul by [DATRAS::readICES()]. If
##'   `FALSE`, a record that matches several candidate hauls is
##'   assigned one of them at random. If `TRUE` (default), such ambiguous records are
##'   left as `NA` and are dropped by any subsequent subsetting. Use
##'   `strict = TRUE` when individual biological records must not be attributed
##'   to an arbitrary haul.
##' @param verbose Logical. If `TRUE` (default), progress messages are printed.
##' @param ncores Integer. Number of parallel workers to use when reading zip
##'   files. Defaults to `1` (sequential). Values greater than 1 use
##'   [parallel::mclapply()] and are only effective on non-Windows systems.
##'
##' @details
##' DATRAS zip archives are typically much larger than a few kilobytes, so very
##' small files are often suspicious and may represent failed downloads or
##' damaged archives.
##'
##' Reading a large number of DATRAS files into R can require substantial memory,
##' especially when combining multiple surveys or many years. The following
##' options can substantially reduce peak memory use:
##'
##' \itemize{
##'   \item `drop_hl = TRUE` drops the length-frequency table (`HL`) immediately
##'     after each file is read. `HL` is typically the largest table and can be
##'     omitted when only haul-level metadata is needed.
##'   \item `drop_ca = TRUE` drops the biological sampling table (`CA`) in the
##'     same way.
##'   \item `prune = TRUE` trims all three tables to a compact set of core
##'     columns. Can be combined with `drop_hl` / `drop_ca`.
##' }
##'
##' When loading a very large database (many surveys, many years) in a single
##' call still exceeds available memory even after using the options above,
##' consider loading in parts and combining with [c()]:
##'
##' ```r
##' x1 <- read_datras("~/data/DATRAS", surveys = c("NS-IBTS", "BITS"),
##'                   drop_ca = TRUE)
##' x2 <- read_datras("~/data/DATRAS", surveys = c("EVHOE", "IBTS-MED"),
##'                   drop_ca = TRUE)
##' x_all <- c(x1, x2)
##' rm(x1, x2)
##' ```
##'
##' If you need a different set of retained columns than provided by
##' [prune_datras()], you may wish to apply your own pruning function after
##' reading or adapt the pruning code.
##'
##' Records in the `CA` table frequently lack the station and haul numbers that
##' make up `haul.id`, and are matched back to a haul by survey, year, quarter,
##' country, ship, and statistical rectangle. When that match is not unique, the
##' `strict` argument decides what happens: `strict = FALSE` picks
##' one of the candidate hauls at random, whereas the default `strict = TRUE` leaves the
##' record unmatched. The number of records affected can be checked afterwards
##' with `sum(is.na(x[["CA"]]$haul.id))`. Note that
##' [download_datras()] uses the equivalent of `strict = TRUE` when downloading
##' data directly from the ICES web service.
##'
##' @return A combined DATRAS survey object with classes `datras_raw` and
##'   `DATRASraw`.
##'
##' @seealso [download_datras()], [prune_datras()]
##'
##' @examples
##' \dontrun{
##' ## Read all zip files from a survey folder
##' x <- read_datras("data/NS-IBTS")
##'
##' ## Read selected years from a folder
##' x <- read_datras("data/NS-IBTS", years = 2018:2020)
##'
##' ## Read selected surveys from a folder containing the whole database
##' x <- read_datras("data/DATRAS", surveys = c("NS-IBTS", "BITS"))
##'
##' ## Combine survey and year filtering
##' x <- read_datras("data/DATRAS", surveys = "NS-IBTS", years = 2018:2020)
##'
##' ## Read multiple zip files directly
##' files <- c("data/NS-IBTS/NS-IBTS_2020.zip",
##'            "data/NS-IBTS/NS-IBTS_2021.zip")
##' x <- read_datras(path = files)
##'
##' ## Read and prune to reduce memory use
##' x <- read_datras("data/NS-IBTS", prune = TRUE)
##'
##' ## Load only haul metadata (HH) -- drop HL and CA to minimise memory use
##' x <- read_datras("data/DATRAS", drop_hl = TRUE, drop_ca = TRUE)
##'
##' ## Prune columns and also drop the CA table
##' x <- read_datras("data/NS-IBTS", prune = TRUE, drop_ca = TRUE)
##'
##' ## Attribute ambiguous CA records to an arbitrary haul
##' x <- read_datras("data/NS-IBTS", strict = FALSE)
##' }
##'
##' @importFrom DATRAS downloadExchange
##' @importFrom utils unzip
##'
##' @export
read_datras <- function(path,
                        surveys = NULL,
                        years = NULL,
                        recursive = TRUE,
                        min_file_size = 1e4,
                        prune = FALSE,
                        drop_hl = FALSE,
                        drop_ca = FALSE,
                        strict = TRUE,
                        verbose = TRUE,
                        ncores = 1) {

  path0 <- path

  if (any(dir.exists(path))) {

    if (!is.null(years) || !is.null(surveys)) {

      path <- dir(path0,
                  full.names = TRUE,
                  recursive = recursive)
      path <- path[grep("\\.zip$", path)]
      if (length(path) == 0) stop("No zip files found in the specified path. Did you specify the correct path? Consider setting recursive = TRUE and run again.")

      if (!is.null(surveys)) {
        path <- path[basename(dirname(path)) %in% surveys]
        if (length(path) == 0) stop("No zip files found matching the specified surveys.")
      }

      if (!is.null(years)) {
        path <- path[sort(unlist(lapply(years,
                                        function(x)
                                          grep(as.character(x), path))))]
        if (length(path) == 0) stop("No zip files found matching the specified years.")
      }

      ind <- which(file.size(path) <= min_file_size)
      if (length(ind) > 0 && verbose) {
        writeLines(paste0("These files are suspiciously small, are you sure that they were downloaded correctly? They will be removed from the list as they likely give errors. Please check the files or change the 'min_file_size' argument!\n",
                          paste(path[ind], collapse = "\n")))
      }
      path <- path[file.size(path) > min_file_size]

      np <- length(path)
      use_parallel <- ncores > 1
      if (verbose && np > 100) {
        message(
          "You are about to load ", np, " zip files. This may take several ",
          "minutes and could crash the R session if memory is insufficient.\n",
          "Consider reducing memory use with one or more of:\n",
          "  prune = TRUE     -- drop non-essential columns in all tables\n",
          "  drop_ca = TRUE   -- omit the CA (biological sampling) table\n",
          "  drop_hl = TRUE   -- omit the HL (length-frequency) table\n",
          "  surveys = ...    -- load only the surveys you need\n",
          "  years   = ...    -- load only the years you need\n",
          "  ncores  = 1     -- if using ncores > 1, try ncores = 1: the\n",
          "                     sequential path combines files incrementally\n",
          "                     and uses less peak memory than parallel loading\n",
          "You can also load the data in parts and combine them with c()."
        )
      }
      if (verbose) {
        if (use_parallel) {
          message("Reading in ", np, " zip files using ", ncores, " cores...")
        } else {
          message("Reading in zip files...")
        }
      }

      ## Each call gets its own temp subdirectory so parallel workers do not
      ## overwrite each other's extracted CSV (all zips contain "DATRAS.csv").
      ## Pruning and table dropping happen inside the reader so that every
      ## worker (sequential or parallel) returns an already-reduced object,
      ## minimising the data held in memory or serialised back from workers.
      .reader <- function(p) {
        tryCatch({
          td <- tempfile(pattern = "datras_")
          dir.create(td, showWarnings = FALSE)
          on.exit(unlink(td, recursive = TRUE), add = TRUE)
          csvfile <- unzip(p, exdir = td)[1]
          invisible(capture.output(
            res <- DATRAS::readICES(csvfile, strict = strict)
          ))
          if (isTRUE(prune))   res <- prune_datras(res)
          if (isTRUE(drop_hl)) res["HL"] <- list(NULL)
          if (isTRUE(drop_ca)) res["CA"] <- list(NULL)
          res
        }, error = function(err) NULL)
      }

      if (use_parallel) {
        if (.Platform$OS.type == "windows") {
          cl <- parallel::makeCluster(ncores, type = "PSOCK")
          on.exit(parallel::stopCluster(cl), add = TRUE)
          ## Load DATRASextra on each worker so prune_datras() is available.
          parallel::clusterEvalQ(cl, library(DATRASextra))
          parallel::clusterExport(cl, ".reader", envir = environment())
          tmp <- parallel::parLapply(cl, path, .reader)
        } else {
          tmp <- parallel::mclapply(path, .reader, mc.cores = ncores)
        }

        idx <- which(sapply(tmp, is.null))
        if (length(idx) > 0) {
          if (verbose) message("One or more loaded files are NULL. Removing these. Check your files!")
          tmp <- tmp[-idx]
        }

        tmp <- .remove_duplicated_haul_id(tmp, verbose = verbose)

        if (verbose) message("Combining files")
        surv0 <- do.call(c.datras_raw, tmp)

      } else {

        ## Incremental combine: reduce and merge one file at a time so that no
        ## more than ~2 objects are live in memory simultaneously.
        if (verbose) pb <- txtProgressBar(min = 0, max = np, style = 3)
        seen_ids <- character(0)
        surv0 <- NULL
        for (i in seq_len(np)) {
          xi <- .reader(path[i])
          if (is.null(xi)) {
            if (verbose) message("\nError with: ", path[i])
          } else {
            new_ids <- as.character(xi[["HH"]][["haul.id"]])
            dup <- new_ids[new_ids %in% seen_ids]
            if (length(dup) > 0) {
              if (verbose) {
                survey_nm <- unique(xi[["HH"]][["Survey"]])[1]
                message("\nDuplicated haul IDs (", survey_nm, ") removed: ",
                        paste(dup, collapse = ", "),
                        "\nPlease check your files!")
              }
              xi <- subset(xi, !haul.id %in% dup)
            }
            seen_ids <- c(seen_ids, setdiff(new_ids, dup))
            xi <- .add_class_datras(xi)
            surv0 <- if (is.null(surv0)) xi else c(surv0, xi)
            rm(xi)
          }
          if (verbose) setTxtProgressBar(pb, i)
        }
        if (verbose) close(pb)
        if (is.null(surv0)) stop("No valid files could be read.")

      }

    } else {

      ## TODO what if the path includes R files and and can it be the mother folder with the surveys as children?

      invisible(capture.output({
        surv0 <- DATRAS::readExchangeDir(path,
                                         pattern = ".zip",
                                         strict = strict)
      }))
    }

  } else if (any(file.exists(path))) {

    path <- path[grep("\\.zip$", path)]
    invisible(capture.output({
      surv0 <- DATRAS::readExchange(path, strict = strict)
    }))

  } else {

    stop(paste0("Cannot find a file or folder under path: ",
                paste(path, collapse = ", ")))

  }

  surv0 <- .add_class_datras(surv0)
  return(surv0)
}



##' Write a `datras_raw` object to a DATRAS exchange zip file
##'
##' Write the contents of a `datras_raw` / `DATRASraw` object to a temporary CSV
##' file in DATRAS exchange format and compress it into a zip archive.
##'
##' The function writes the available DATRAS components in the order `HH`, `HL`,
##' and `CA`. For each component, the column names are written as a header line,
##' followed by the corresponding data rows.
##'
##' @param x A `datras_raw` object to be written.
##' @param zip_file Character string giving the path and name of the output zip
##'   file. Defaults to `"DATRAS.zip"`.
##'
##' @return Invisibly returns the path to the created zip file.
##'
##' @details
##' The exchange file is first written to a temporary CSV file and then zipped
##' using [utils::zip()]. If `zip_file` already exists, it is overwritten.
##'
##' Empty or missing components among `HH`, `HL`, and `CA` are skipped.
##'
##' @examples
##' \dontrun{
##' ## Write a DATRAS object to a zip archive
##' write_datras(x, "NS-IBTS_2020.zip")
##' }
##'
##' @export
write_datras <- function(x,
                           zip_file = "DATRAS.zip") {

  .check_class_datras(x)

  td <- tempdir()
  csvfile <- file.path(td, "DATRAS.csv")

  con <- file(csvfile, open = "wt", encoding = "UTF-8")
  on.exit({
    ## Only attempt to close if we still hold a connection object
    if (!is.null(con) && inherits(con, "connection")) {
      try(close(con), silent = TRUE)
    }
  }, add = TRUE)

  for (comp in c("HH", "HL", "CA")) {
    if (!comp %in% names(x)) next
    df <- x[[comp]]
    if (is.null(df) || nrow(df) == 0) next

    ## header once per block, then append the rows
    writeLines(paste(names(df), collapse = ","), con)
    write.table(df, con, sep = ",", row.names = FALSE, col.names = FALSE,
                append = TRUE, na = "", quote = FALSE, eol = "\n")
  }

  ## Flush and close before zipping, then null the handle so on.exit() does nothing
  close(con); con <- NULL

  if (file.exists(zip_file)) unlink(zip_file)
  utils::zip(zip_file, files = csvfile, flags = "-j")

  message("Created zip file: ", zip_file)
  invisible(zip_file)
}






## Internal functions -----------------------------------------------------


.remove_duplicated_haul_id <- function(args, verbose = TRUE) {
  x <- lapply(args, function(x) as.character(x$haul.id))
  x2 <- lapply(args, function(x) x[["HH"]]$Survey)
  ind <- which(duplicated(unlist(x)))
  ids <- unlist(x)[ind]
  if (length(ind) > 0) {
    if(verbose){
      message(paste0("These hauls are duplicated:\n",
                     paste(paste0(unlist(x2)[ind],": ",ids),
                           collapse = "\n")))
      message("Removing these hauls in order to continue. Please look into these surveys and hauls and find out why they are duplicated!")
    }
    args <- lapply(args, function(x) subset(x, !haul.id %in% ids))
  }
  return(args)
}
