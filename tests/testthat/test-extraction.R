
## require(DATRASextra); require(testthat)


test_that("extraction is reconstructed from the data alone", {

  e <- extraction(mini)

  expect_s3_class(e, "data.frame")
  expect_true(nrow(e) > 0)
  expect_true(all(c("survey", "year", "quarter", "date_of_calculation",
                    "extracted", "payload_hash", "algo") %in% names(e)))

  ## One row per survey, year and quarter
  key <- paste(e$survey, e$year, e$quarter)
  expect_equal(length(key), length(unique(key)))

  expect_s3_class(e$date_of_calculation, "Date")
  expect_true(all(!is.na(e$date_of_calculation)))

  ## The keys must match what is actually in the data
  hh <- mini[["HH"]]
  expect_setequal(
    unique(paste(hh$Survey, hh$Year, hh$Quarter)),
    paste(e$survey, e$year, e$quarter)
  )
})


test_that("DateofCalculation is parsed from the YYYYMMDD field", {

  expect_equal(.parse_date_of_calculation(20240409L), as.Date("2024-04-09"))
  expect_equal(.parse_date_of_calculation("20240409"), as.Date("2024-04-09"))

  ## Historical files leave the field empty
  expect_true(is.na(.parse_date_of_calculation("")))
  expect_true(is.na(.parse_date_of_calculation(NA)))
})


test_that("the extraction record survives the processing pipeline", {

  x <- mini
  attr(x, "extraction") <- extraction(mini)
  n <- nrow(extraction(x))
  expect_true(n > 0)

  expect_equal(nrow(extraction(clean_datras(x, verbose = FALSE))), n)
  expect_equal(nrow(extraction(suppressWarnings(prune_datras(x, verbose = FALSE)))), n)
  expect_equal(nrow(extraction(correct_species(x))), n)
  expect_equal(nrow(extraction(check_outliers(x, verbose = FALSE))), n)

  ## Removal rebuilds the object with lapply(), which used to drop every
  ## attribute of the object.
  expect_equal(nrow(extraction(check_outliers(x, action = "remove",
                                              verbose = FALSE))), n)
})


test_that("check_outliers keeps other attributes when removing hauls", {

  x <- suppressWarnings(add_numbers_at_length(subset(mini, Valid_Aphia == 127137)))
  x <- add_swept_area(x, verbose = FALSE)

  out <- check_outliers(x, action = "remove", verbose = FALSE)

  expect_equal(class(out), class(x))
  expect_false(is.null(attr(out, "cm.breaks")))
  expect_false(is.null(attr(out, "swept_area_summary")))
  expect_false(is.null(attr(out, "swept_area_unit")))
})


test_that("combining objects merges their extraction records", {

  x <- mini
  attr(x, "extraction") <- extraction(mini)

  a <- subset(x, Year == 2022)
  b <- subset(x, Year == 2023)

  expect_true(nrow(extraction(a)) > 0)
  expect_true(nrow(extraction(b)) > 0)

  ab <- c(a, b)
  expect_equal(nrow(extraction(ab)),
               nrow(extraction(a)) + nrow(extraction(b)))
})


test_that("extraction is reconciled with the data still present", {

  x <- mini
  attr(x, "extraction") <- extraction(mini)

  ## Subsetting does not touch attributes, so the record must be reconciled
  ## against the data rather than reported verbatim.
  sub <- subset(x, Year == 2023)
  e <- extraction(sub)

  expect_true(nrow(e) < nrow(extraction(x)))
  expect_true(all(e$year == 2023))
})


test_that("prune_datras keeps the ICES calculation date", {

  out <- suppressWarnings(prune_datras(mini, verbose = FALSE))

  expect_true("DateofCalculation" %in% names(out[["HH"]]))
  expect_true(all(!is.na(extraction(out)$date_of_calculation)))
})


test_that("payload checksums are stable across writes but zip checksums are not", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-hash-test")
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  x <- .remove_extra_variables(subset(mini, Survey == "EVHOE"))

  z1 <- suppressMessages(write_datras(x, file.path(d, "a.zip")))
  Sys.sleep(1.1)
  z2 <- suppressMessages(write_datras(x, file.path(d, "b.zip")))

  ## Identical data must give an identical payload hash ...
  expect_equal(attr(z1, "payload_hash"), attr(z2, "payload_hash"))
  expect_true(nchar(attr(z1, "payload_hash")) %in% c(32L, 64L))

  ## ... while the zip archives differ, because utils::zip() stores the
  ## modification time of the file it compresses. This is why the manifest
  ## records the payload hash rather than the archive hash.
  expect_false(identical(attr(z1, "zip_hash"), attr(z2, "zip_hash")))
})


test_that("a write and read round trip preserves the extraction keys", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-roundtrip-test")
  unlink(d, recursive = TRUE)
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  x <- subset(mini, Survey == "EVHOE")
  before <- extraction(x)

  suppressMessages(
    write_datras(.remove_extra_variables(x), file.path(d, "EVHOE_2022.zip"))
  )
  y <- suppressMessages(read_datras(d))
  after <- extraction(y)

  expect_equal(after$survey, before$survey)
  expect_equal(after$year, before$year)
  expect_equal(after$quarter, before$quarter)
  expect_equal(after$date_of_calculation, before$date_of_calculation)

  ## read_datras() stamps the software that produced the object
  expect_true(all(!is.na(after$read)))
  expect_equal(unique(after$datrasextra),
               as.character(utils::packageVersion("DATRASextra")))
})


test_that("a manifest verifies an archive and detects changes", {

  skip_on_cran()

  d <- file.path(tempdir(), "datrasextra-manifest-test")
  unlink(d, recursive = TRUE)
  dir.create(file.path(d, "EVHOE"), showWarnings = FALSE, recursive = TRUE)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  x <- .remove_extra_variables(subset(mini, Survey == "EVHOE"))
  zip_path <- file.path(d, "EVHOE", "EVHOE_2022.zip")
  suppressMessages(write_datras(x, zip_path))

  man <- suppressMessages(write_manifest(d, verbose = FALSE))
  expect_true(nrow(man) > 0)
  expect_true(all(!is.na(man$payload_hash)))
  expect_true(file.exists(file.path(d, "DATRAS_manifest.csv")))

  ## Types survive the round trip through CSV
  back <- read_manifest(d)
  expect_s3_class(back$date_of_calculation, "Date")
  expect_equal(back$payload_hash, man$payload_hash)

  ## An untouched archive verifies clean
  v <- verify_extraction(d, verbose = FALSE)
  expect_true(all(v$status == "ok"))

  ## A different ICES calculation date is reported as an upstream revision,
  ## not as local corruption
  man2 <- man
  man2$date_of_calculation <- man2$date_of_calculation - 1
  v2 <- verify_extraction(d, manifest = man2, verbose = FALSE)
  expect_true(all(v2$status == "revised"))

  ## A missing file is reported as missing
  unlink(zip_path)
  v3 <- verify_extraction(d, verbose = FALSE)
  expect_true(all(v3$status == "missing"))
})


test_that("read_manifest returns the empty template when none exists", {

  e <- read_manifest(tempdir(), file = "no-such-manifest.csv")

  expect_s3_class(e, "data.frame")
  expect_equal(nrow(e), 0L)
  expect_true(all(c("survey", "year", "quarter", "date_of_calculation") %in% names(e)))
})
