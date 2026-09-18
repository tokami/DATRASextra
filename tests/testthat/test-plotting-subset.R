## require(DATRASextra); require(testthat)

.subset_hh <- function() {
  data.frame(
    Survey = c("DYFS", "DYFS", "SNS", "BITS", "BITS"),
    Year = c("2015", "2016", "2015", "2015", "2016"),
    Quarter = c(1L, 3L, 4L, 1L, 4L),
    lon = c(4, 5, 6, 15, 16),
    lat = c(53, 54, 53, 55, 56),
    stringsAsFactors = FALSE
  )
}

test_that("subset accepts an unquoted expression", {
  hh <- .subset_hh()
  out <- .apply_subset(hh, quote(Survey %in% c("DYFS", "SNS")), environment())
  expect_equal(nrow(out), 3L)
  expect_setequal(out$Survey, c("DYFS", "SNS"))
})

test_that("subset sees variables from the calling environment", {
  hh <- .subset_hh()
  surveys <- c("DYFS", "SNS")
  out <- .apply_subset(hh, quote(Survey %in% surveys), environment())
  expect_equal(nrow(out), 3L)
})

test_that("subset accepts a character expression", {
  hh <- .subset_hh()
  out <- .apply_subset(hh, "Survey == 'BITS' & Quarter == 4", environment())
  expect_equal(nrow(out), 1L)
  expect_equal(out$Year, "2016")
  ## the same string held in a variable
  flt <- "Survey == 'BITS' & Quarter == 4"
  expect_equal(nrow(.apply_subset(hh, quote(flt), environment())), 1L)
})

test_that("subset accepts a logical vector and treats NA as FALSE", {
  hh <- .subset_hh()
  keep <- c(TRUE, NA, TRUE, FALSE, FALSE)
  expect_equal(nrow(.apply_subset(hh, quote(keep), environment())), 2L)
})

test_that("NULL subset returns the data unchanged", {
  hh <- .subset_hh()
  expect_identical(.apply_subset(hh, NULL, environment()), hh)
  expect_identical(.apply_subset(hh, quote(NULL), environment()), hh)
})

test_that("invalid subset inputs give informative errors", {
  hh <- .subset_hh()
  expect_error(.apply_subset(hh, quote(Surve %in% "DYFS"), environment()),
               "could not be evaluated")
  expect_error(.apply_subset(hh, quote(Survey), environment()),
               "logical vector")
  expect_error(.apply_subset(hh, quote(c(TRUE, FALSE)), environment()),
               "haul table has")
  expect_error(.apply_subset(hh, quote(Survey == "NOPE"), environment()),
               "No rows left")
})

test_that("plot_datras_overview subsets the bundled survey overview", {
  skip_if_not(requireNamespace("DATRASextra", quietly = TRUE))
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  out <- plot_datras_overview(subset = Survey %in% c("DYFS", "SNS"), by_survey = TRUE)
  expect_setequal(unique(out$data$Survey), c("DYFS", "SNS"))
})

test_that("years filter works for character Year columns", {
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  out <- plot_datras_overview(subset = Survey == "DYFS", years = 2015:2016)
  expect_setequal(unique(as.character(out$data$Year)), c("2015", "2016"))
})
