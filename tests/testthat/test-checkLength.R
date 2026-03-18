
## require(DATRASextra); require(testthat)


test_that("check_length works", {

  lpars <- check_length(dab)

  expect_type(lpars, "list")
  expect_equal(length(lpars), 3)
  expect_true(!is.na(lpars$lPars$min))
  expect_error(check_length(NULL))
  ## expect_warning(check_length(NA))
})
