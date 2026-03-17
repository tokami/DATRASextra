
## require(DATRASextra); require(testthat)


test_that("check_outliers works", {

  out <- check_outliers(dab)

  out <- check_outliers(mini)

  attr(out, "outlier_report")

  attr(out, "outlier_hauls")

  out <- check_outliers(dab, pct = TRUE)

  head(attr(out, "outlier_report"))

})
