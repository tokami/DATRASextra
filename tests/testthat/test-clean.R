
## require(DATRASextra); require(testthat)


test_that("clean_datras imputes missing depths", {
  skip_if_not_installed("mgcv")

  expect_true(any(is.na(mini[["HH"]]$Depth)))

  out <- clean_datras(mini, impute_missing_depth = TRUE, verbose = FALSE)

  expect_equal(class(out), class(mini))
  expect_false(any(is.na(out[["HH"]]$Depth)))
  expect_true(all(out[["HH"]]$Depth > 0))
})


## mini with the HL records of one survey-year-quarter removed, as for the test
## entries left in DATRAS (ices-tools-prod/icesDatras#59)
mini_without_hl <- function() {
  x <- mini
  hl <- x[["HL"]]
  x[["HL"]] <- hl[!(hl$Survey == "EVHOE" & hl$Year == "2023"), ]
  x
}


test_that("survey-year-quarters with hauls but no HL records are found", {

  expect_equal(nrow(.groups_without_hl(mini)), 0)

  x <- mini_without_hl()
  g <- .groups_without_hl(x)
  expect_equal(g$Survey, "EVHOE")
  expect_equal(g$Year, 2023L)
  expect_equal(g$Quarter, 4L)
  expect_equal(g$n_hauls, sum(x[["HH"]]$Survey == "EVHOE" & x[["HH"]]$Year == "2023"))

  ## Nothing to check against without HL
  x[["HL"]] <- NULL
  expect_null(.groups_without_hl(x))
})


test_that("clean_datras reports survey-year-quarters without HL by default", {

  x <- mini_without_hl()
  expect_message(out <- clean_datras(x, correct_species = FALSE),
                 "EVHOE 2023 Q4")
  expect_true(any(out[["HH"]]$Survey == "EVHOE" & out[["HH"]]$Year == "2023"))

  ## Silent with verbose = FALSE, and no report for complete data
  expect_silent(clean_datras(x, correct_species = FALSE, verbose = FALSE))
  msgs <- testthat::capture_messages(clean_datras(mini, correct_species = FALSE))
  expect_false(any(grepl("no length data", msgs)))
})


test_that("clean_datras drops survey-year-quarters without HL when asked", {

  x <- mini_without_hl()
  out <- clean_datras(x, correct_species = FALSE, verbose = FALSE,
                      drop_without_hl = TRUE)
  ref <- clean_datras(x, correct_species = FALSE, verbose = FALSE)

  is_gone <- function(d) d$Survey == "EVHOE" & d$Year == "2023"
  expect_false(any(is_gone(out[["HH"]])))
  expect_false(any(is_gone(out[["CA"]])))
  expect_true(any(is_gone(ref[["CA"]])))

  ## Everything else is untouched
  expect_equal(nrow(out[["HH"]]), sum(!is_gone(ref[["HH"]])))
  expect_equal(nrow(out[["HL"]]), nrow(ref[["HL"]]))
})


test_that("the check runs before the species filter", {

  ## A survey-year-quarter where the selected species was not caught must keep
  ## its hauls (zero catch), not be taken for one without length data
  hl <- mini[["HL"]]
  grp <- paste(hl$Survey, hl$Year, hl$Quarter)
  by_aphia <- tapply(grp, as.character(hl$Valid_Aphia), function(g) length(unique(g)))
  aphia <- names(by_aphia)[by_aphia < length(unique(grp))][1]
  skip_if(is.na(aphia), "every species occurs in every survey-year-quarter")
  absent <- setdiff(unique(grp), grp[as.character(hl$Valid_Aphia) == aphia])

  out <- clean_datras(mini, aphias = aphia, correct_species = FALSE,
                      verbose = FALSE, drop_without_hl = TRUE)
  hh <- out[["HH"]]
  expect_true(all(absent %in% paste(hh$Survey, hh$Year, hh$Quarter)))
})
