## require(DATRASextra); require(testthat)

.fake_index <- function(year = 1990:2000, scale = 1e6) {
  data.frame(
    Year = as.character(year),
    group = "all",
    cpue_method = "per_swept_area",
    index = seq_along(year) * scale,
    ci_lower = seq_along(year) * scale * 0.8,
    ci_upper = seq_along(year) * scale * 1.2,
    stringsAsFactors = FALSE
  )
}

.fake_cog <- function(year = 1990:2000) {
  data.frame(
    Year = factor(year),
    group = "all",
    cpue_method = "per_swept_area",
    n_hauls = 10L,
    cog_lat = 55 + seq_along(year) / 10,
    cog_lon = 4 + seq_along(year) / 10,
    stringsAsFactors = FALSE
  )
}

test_that("numeric grouping columns are restored", {
  df <- data.frame(Year = factor(c(2001, 2002)), Survey = c("NS-IBTS", "BITS"),
                   Quarter = c("1", "3"), stringsAsFactors = FALSE)
  out <- .restore_numeric_cols(df, c("Year", "Survey", "Quarter"))
  expect_type(out$Year, "double")
  expect_identical(out$Year, c(2001, 2002))
  expect_type(out$Quarter, "double")
  ## genuinely categorical columns are left untouched
  expect_identical(out$Survey, df$Survey)
})

test_that("scale exponent follows the magnitude of the data", {
  expect_identical(.auto_scale_exponent(c(1, 500, 9999)), 0L)
  expect_identical(.auto_scale_exponent(c(0, 5e4)), 3L)
  expect_identical(.auto_scale_exponent(c(NA, 2e6, Inf)), 6L)
  expect_identical(.auto_scale_exponent(c(-8e9, 1)), 9L)
  expect_identical(.auto_scale_exponent(numeric(0)), 0L)
  expect_identical(.auto_scale_exponent(c(0, 0)), 0L)
})

test_that("calc_spatial_indicators returns a numeric year", {
  skip_if_not(exists("dab"))
  data(dab, envir = environment())
  x <- suppressWarnings(add_total_numbers_by_haul(add_swept_area(dab, verbose = FALSE)))
  res <- calc_spatial_indicators(x, by = "Year")
  expect_true(is.numeric(res$Year))
})

test_that("index plot honours y_scale", {
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  x <- .fake_index()
  expect_silent(plot_stratified_index(x, legend = FALSE))
  expect_silent(plot_stratified_index(x, legend = FALSE, y_scale = "none"))
  expect_silent(plot_stratified_index(x, legend = FALSE, y_scale = 3))
  expect_silent(plot_stratified_index(x, legend = FALSE, log_scale = TRUE))
  expect_error(plot_stratified_index(x, legend = FALSE, y_scale = "millions"),
               "must be")
})

test_that("index plot accepts ylim in the original units", {
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  x <- .fake_index()
  plot_stratified_index(x, legend = FALSE, ylim = c(0, 2e7))
  ## the y axis is drawn in units of 1e6, so the requested limit shows as 20
  expect_equal(par("usr")[4] > 19, TRUE)
  expect_equal(par("usr")[4] < 25, TRUE)
})

test_that("CoG plot uses a continuous axis for numeric years", {
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  cog <- .fake_cog(1990:2000)
  plot_spatial_indicators(cog, vars = "cog_lat", legend = FALSE)
  ## a continuous year axis spans the years themselves, not 1..n
  expect_gt(par("usr")[1], 1900)
  expect_lt(par("usr")[2], 2100)
})

test_that("CoG plot still treats non-numeric x as categorical", {
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  cog <- .fake_cog(1990:1993)
  cog$Survey <- rep(c("NS-IBTS", "BITS"), each = 2)
  plot_spatial_indicators(cog, vars = "cog_lat", x_var = "Survey", legend = FALSE)
  expect_lt(par("usr")[2], 10)
})
