## The fixtures are rows from the DATRAS Download API for EVHOE 2022, kept as
## delivered (byte order mark, HH header two fields longer than its rows). The
## StationName of the second HH row was changed to "0094" to test leading zeros.
read_fixture <- function(recordtype) {
  .read_download_api_csv(test_path("fixtures", paste0("download_api_", recordtype, ".csv")))
}


test_that("Download API files are read as text without shifting columns", {

  hh <- read_fixture("HH")

  ## EDOM and ReasonHaulDisruption are in the header but not in the rows
  expect_equal(ncol(hh), 70)
  expect_false(any(c("EDOM", "ReasonHaulDisruption") %in% names(hh)))
  expect_equal(names(hh)[1], "RecordHeader")
  expect_equal(hh$DateofCalculation, c("20230425", "20230425"))

  ## Codes are kept exactly: no "18E8" -> 1.8e9, no "0094" -> 94
  expect_true(all(vapply(hh, is.character, logical(1))))
  expect_equal(hh$StatisticalRectangle, c("18E8", "28E0"))
  expect_equal(hh$StationName, c("A1490", "0094"))

  ## Decimal numbers at length are not truncated
  hl <- read_fixture("HL")
  expect_equal(hl$NumberAtLength, c("1.71", "3.42"))
})


test_that("a header and rows of other lengths is an error", {

  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  writeLines(c("A,B,C", "1,2"), f)
  expect_error(.read_download_api_csv(f), "3 columns in its header but 2")
})


test_that("a Download API file without rows gives an empty table", {

  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  writeLines("RecordHeader,Survey,Year", f)
  d <- .read_download_api_csv(f)
  expect_equal(nrow(d), 0)
  expect_equal(names(d), c("RecordHeader", "Survey", "Year"))
})


test_that("Download API fields map to the exchange names written to disk", {

  x <- list(HH = .datras_api_to_exchange(read_fixture("HH"), "HH"),
            HL = .datras_api_to_exchange(read_fixture("HL"), "HL"),
            CA = .datras_api_to_exchange(read_fixture("CA"), "CA"))
  x <- .remove_extra_variables(.add_class_datras(x))

  ## Every exchange column of the web service route is present, in the same
  ## order; LiverWeight, SurveyIndexArea and ScientificName_WoRMS are exchange
  ## fields the web service does not deliver
  ref <- .remove_extra_variables(subset(mini, Survey == "EVHOE"))
  extra <- c("LiverWeight", "SurveyIndexArea", "ScientificName_WoRMS")
  for (r in c("HH", "HL", "CA")) {
    expect_equal(setdiff(names(x[[r]]), extra), names(ref[[r]]), info = r)
  }

  expect_equal(x$HH$StNo, c("A1490", "0094"))
  expect_equal(x$HH$StatRec, c("18E8", "28E0"))
  expect_equal(x$HL$HLNoAtLngt, c("1.71", "3.42"))
  expect_equal(x$HL$LngtClass, c("170", "180"))
  expect_equal(x$CA$ValidAphiaID, c("126438", "126438"))
  expect_equal(x$CA$CANoAtLngt, c("1", "1"))
  expect_equal(x$CA$AgeRings, c("4", "1"))

  ## -9 codes for missing values become NA, written as empty fields
  expect_true(all(is.na(x$HH$DoorType)))
  expect_true(all(is.na(x$CA$LiverWeight)))
  expect_false(any(unlist(lapply(unclass(x)[c("HH", "HL", "CA")], function(d)
    unlist(d) %in% c("-9", "-9.0", "-9.00", "-9.0000")))))
})


test_that("read_datras returns empty fields as NA but keeps haul ids", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-empty-test")
  unlink(d, recursive = TRUE)
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  ## BTS hauls without a station number
  x <- subset(mini, Survey == "BTS" & Year == "2020")
  suppressMessages(write_datras(.remove_extra_variables(x), file.path(d, "BTS_2020.zip")))
  y <- suppressMessages(read_datras(d))

  for (r in c("HH", "HL", "CA")) {
    has_empty <- vapply(y[[r]], function(v) {
      if (is.factor(v)) v <- levels(v)
      is.character(v) && any(!is.na(v) & !nzchar(trimws(v)))
    }, logical(1))
    expect_false(any(has_empty[names(has_empty) != "haul.id"]), info = r)
  }
  expect_true(anyNA(y$HH$StNo))
  expect_setequal(as.character(y$HH$haul.id), as.character(x$HH$haul.id))
  expect_true(any(grepl("::", y$HH$haul.id)))
})


test_that("years are split into contiguous runs of limited length", {

  expect_equal(.year_chunks(c(2001:2003, 2005, 2010:2014), size = 3),
               list(2001:2003, 2005L, 2010:2012, 2013:2014))
  expect_equal(.year_chunks(integer(0)), list())
  expect_equal(.year_range(2010:2014, sep = ":"), "2010:2014")
  expect_equal(.year_range(2010), "2010")
})


test_that("the Download API and the web service give the same data", {

  skip_on_cran()
  skip_if_offline("datras.ices.dk")

  d <- file.path(tempdir(), "datrasextra-download-test")
  unlink(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  ## BTS has hauls without a station number, which make up part of haul.id
  a <- suppressMessages(download_datras(file.path(d, "api"), "BTS", 2022,
                                        method = "api"))
  invisible(utils::capture.output(
    w <- suppressMessages(download_datras(file.path(d, "ws"), "BTS", 2022,
                                          method = "webservice"))
  ))

  for (r in c("HH", "HL", "CA")) expect_equal(nrow(a[[r]]), nrow(w[[r]]), info = r)
  expect_true(anyNA(a$HH$StNo))
  expect_setequal(as.character(a$HH$haul.id), as.character(w$HH$haul.id))
  expect_setequal(as.character(a$CA$haul.id), as.character(w$CA$haul.id))

  counts <- function(x) {
    s <- stats::aggregate(Count ~ haul.id + Valid_Aphia,
                          data = transform(x$HL, haul.id = as.character(haul.id)),
                          FUN = sum)
    s[order(s$haul.id, s$Valid_Aphia), ]
  }
  expect_equal(counts(a)$Count, counts(w)$Count, tolerance = 1e-8)

  man <- utils::read.csv(file.path(d, "api", "DATRAS_manifest.csv"))
  expect_true(all(man$source == "download_api"))
  expect_false(anyNA(man$payload_hash))
  expect_false(anyNA(extraction(a)$date_of_calculation))
})


test_that("download_datras warns about survey-years without length data", {

  skip_on_cran()
  skip_if_offline("datras.ices.dk")

  d <- file.path(tempdir(), "datrasextra-nohl-test")
  unlink(d, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  ## NS-IDPS 2012 Q1 holds a single test haul without HL records
  ## (ices-tools-prod/icesDatras#59). Skip if ICES has removed it. 2013 is
  ## included so that the object has an HL table to check against.
  x <- NULL
  w <- testthat::capture_warnings(
    x <- suppressMessages(download_datras(d, "NS-IDPS", 2012:2013))
  )
  skip_if(nrow(x[["HH"]]) == 0 || any(x[["HL"]]$Year == "2012"),
          "NS-IDPS 2012 no longer lacks length data")

  expect_true(any(grepl("NS-IDPS 2012 Q1", w)))
  expect_true(file.exists(file.path(d, "NS-IDPS", "NS-IDPS_2012.zip")))

  out <- clean_datras(x, correct_species = FALSE, verbose = FALSE,
                      drop_without_hl = TRUE)
  expect_false(any(out[["HH"]]$Year == "2012"))
  expect_true(any(out[["HH"]]$Year == "2013"))
})


test_that("read_datras drops exact duplicate HH rows instead of the whole file", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-duphh-test")
  unlink(d, recursive = TRUE)
  dir.create(file.path(d, "csv"), showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  x <- subset(mini, Survey == "BTS" & Year == "2020")
  zf <- file.path(d, "BTS_2020.zip")
  suppressMessages(write_datras(.remove_extra_variables(x), zf))

  ## Repeat the first HH record, as in the NS-IBTS 1991 file served by ICES
  csv <- utils::unzip(zf, exdir = file.path(d, "csv"))[1]
  lines <- readLines(csv)
  first_hh <- grep('^"?HH"?,', lines)[1]
  writeLines(append(lines, lines[first_hh], after = first_hh), csv)
  unlink(zf)
  zip::zip(zf, csv, mode = "cherry-pick")

  expect_message(y <- read_datras(zf),
                 "1 duplicated HH row\\(s\\) removed")
  expect_setequal(as.character(y$HH$haul.id), as.character(x$HH$haul.id))
  expect_equal(nrow(y$HL), nrow(x$HL))
})


test_that("read_datras reports why a file could not be read", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-badzip-test")
  unlink(d, recursive = TRUE)
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  x <- subset(mini, Survey == "BTS" & Year == "2020")
  good <- file.path(d, "BTS_2020.zip")
  suppressMessages(write_datras(.remove_extra_variables(x), good))
  bad <- file.path(d, "BTS_2021.zip")
  writeLines("not a zip file", bad)

  expect_message(y <- suppressWarnings(read_datras(c(good, bad))),
                 "Could not read .*BTS_2021\\.zip")
  expect_setequal(as.character(y$HH$haul.id), as.character(x$HH$haul.id))
})


test_that("read_datras skips only empty files by default", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-minsize-test")
  unlink(d, recursive = TRUE)
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  x <- subset(mini, Survey == "BTS" & Year == "2020")
  good <- file.path(d, "BTS_2020.zip")
  suppressMessages(write_datras(.remove_extra_variables(x), good))
  empty <- file.path(d, "BTS_2021.zip")
  file.create(empty)

  expect_message(y <- read_datras(d), "Skipping 1 file.*BTS_2021\\.zip")
  expect_setequal(as.character(y$HH$haul.id), as.character(x$HH$haul.id))

  expect_silent(read_datras(d, verbose = FALSE))
  expect_error(suppressMessages(read_datras(d, min_file_size = file.size(good))),
               "Lower 'min_file_size'")
  expect_error(suppressMessages(read_datras(empty)), "All zip files are empty")
})
