test_that("checkLength works", {
    data("dab")
    lpars <- checkLength(dab)
    expect_type(lpars, "list")
    expect_equal(length(lpars), 3)
    expect_true(!is.na(lpars$lPars$min))
    expect_error(checkLength(NULL))
    ## expect_warning(checkLength(NA))
})
