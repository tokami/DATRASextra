
## require(DATRASextra); require(testthat)

test_that("long format", {

  ## should work
  out <- as_long_format(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))

  str(out, 1)

  ## should give warning:
  out <- as_long_format(mini, vars = c("Survey", "Year", "foo", "Species"))

  expect_warning(out)

})




test_that("wide format", {

  ## if only one species wide format == long format
  out1 <- as_long_format(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))
  out2 <- as_wide_format(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))

  expect_equal(out1, out2)

  ## not the same for multiple species
  out1 <- as_long_format(mini, vars = c("Survey", "Year", "Species", "Aphia_ID"))
  out2 <- as_wide_format(mini, vars = c("Survey", "Year", "Species", "Aphia_ID"))

  ## TODO: not equal
  ## expect_equal(out1, out2)


})
