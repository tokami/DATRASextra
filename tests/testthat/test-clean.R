
## require(DATRASextra); require(testthat)


test_that("clean_datras imputes missing depths", {
  skip_if_not_installed("mgcv")

  expect_true(any(is.na(mini[["HH"]]$Depth)))

  out <- clean_datras(mini, impute_missing_depth = TRUE, verbose = FALSE)

  expect_equal(class(out), class(mini))
  expect_false(any(is.na(out[["HH"]]$Depth)))
  expect_true(all(out[["HH"]]$Depth > 0))
})
