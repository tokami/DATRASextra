
## require(DATRASextra); require(testthat)


test_that("checkOutliers works", {

  out <- checkOutliers(dab)

  out <- checkOutliers(mini)

  attr(out, "outlier_report")

  attr(out, "outlier_hauls")

  out <- checkOutliers(dab, pct = TRUE)

  head(attr(out, "outlier_report"))

})
