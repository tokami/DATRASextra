
## require(DATRASextra); require(testthat)


test_that("reference_tables reports the bundled tables", {

  r <- reference_tables()

  expect_s3_class(r, "data.frame")
  expect_true(all(c("table", "kind", "rows", "columns", "generated",
                    "script", "source", "hash", "status") %in% names(r)))

  expect_true(all(c("species_info", "survey_info", "survey_info_full_raw",
                    "spawning_info", "ices_area_lookup",
                    "spread_models") %in% r$table))

  expect_s3_class(r$generated, "Date")
  expect_true(all(!is.na(r$generated)))
  expect_true(all(r$rows > 0))
  expect_true(all(r$kind %in% c("exported", "internal")))

  ## Every table must be described by the shipped registry
  expect_false(any(r$status %in% c("missing", "unregistered")))
})


test_that("the registry matches the tables actually shipped", {

  r <- reference_tables()
  changed <- r$table[r$status != "ok"]

  ## A failure here means a reference table was regenerated without updating
  ## the registry. Re-run DATRASextra:::.write_reference_registry() from the
  ## package source tree.
  expect_equal(changed, character(0))
})


test_that("check = FALSE skips hashing", {

  r <- reference_tables(check = FALSE)

  expect_false("hash" %in% names(r))
  expect_false("status" %in% names(r))
  expect_true(all(c("table", "generated", "source") %in% names(r)))
})


test_that("object hashes are stable and discriminating", {

  a <- data.frame(x = 1:5, y = letters[1:5], stringsAsFactors = FALSE)
  b <- a
  b$y[3] <- "z"

  expect_equal(.hash_object(a), .hash_object(a))
  expect_false(identical(.hash_object(a), .hash_object(b)))
  expect_true(nchar(.hash_object(a)) %in% c(32L, 64L))
})


test_that("the registry reads back with folded fields unwrapped", {

  reg <- .read_reference_registry()

  expect_true(nrow(reg) > 0)
  expect_s3_class(reg$generated, "Date")

  ## write.dcf folds long values across indented continuation lines; those
  ## must not survive into the returned value
  expect_false(any(grepl("\n", reg$source)))
  expect_false(any(grepl("  ", reg$source)))

  src <- reg$source[reg$table == "species_info"]
  expect_true(grepl("WoRMS", src))
  expect_true(grepl("Walker", src))
})


test_that("a missing registry degrades to an empty table", {

  reg <- .read_reference_registry(file.path(tempdir(), "no-such-registry.dcf"))

  expect_s3_class(reg, "data.frame")
  expect_equal(nrow(reg), 0L)
  expect_true(all(c("table", "generated", "hash") %in% names(reg)))
})
