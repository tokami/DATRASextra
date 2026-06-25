
## require(DATRASextra); require(testthat)


## shared setup ----------------------------------------------------------------

dab_n   <- add_numbers_at_length(dab)
dab_cut <- add_total_numbers_by_haul(dab_n, length_cuts = c(0, 20, Inf))
dab_tot <- add_total_numbers_by_haul(dab_n)


## as_long_format --------------------------------------------------------------

testthat::test_that("as_long_format returns a data frame", {
  testthat::expect_s3_class(as_long_format(dab), "data.frame")
})

testthat::test_that("as_long_format includes requested columns", {
  out <- as_long_format(dab, vars = c("Survey", "Year"))
  testthat::expect_true(all(c("Survey", "Year") %in% names(out)))
})

testthat::test_that("as_long_format always keeps haul.id", {
  out <- as_long_format(dab, vars = c("Survey", "Year"))
  testthat::expect_true("haul.id" %in% names(out))
})

testthat::test_that("as_long_format warns and omits missing variables", {
  testthat::expect_warning(
    out <- as_long_format(dab, vars = c("Survey", "foo")),
    "not found in HH"
  )
  testthat::expect_false("foo" %in% names(out))
})

testthat::test_that("as_long_format auto-adds HaulN when present", {
  testthat::expect_true("HaulN" %in% names(as_long_format(dab_tot)))
  testthat::expect_false("HaulN" %in% names(as_long_format(dab)))
})

testthat::test_that("as_long_format expands matrix HaulN to rows", {
  out <- as_long_format(dab_cut)
  n_hauls <- nrow(dab_cut[["HH"]])
  testthat::expect_equal(nrow(out), n_hauls * 2L)
  testthat::expect_true("LengthGroup" %in% names(out))
  testthat::expect_false(is.matrix(out$HaulN))
})

testthat::test_that("as_long_format does not expand scalar HaulN", {
  out <- as_long_format(dab_tot)
  testthat::expect_equal(nrow(out), nrow(dab_tot[["HH"]]))
  testthat::expect_false("LengthGroup" %in% names(out))
})

testthat::test_that("as_long_format errors when matrices have different bin structures", {
  dab_wgt <- add_total_weight_by_haul(dab_cut, length_cuts = c(0, 10, 20, Inf))
  testthat::expect_error(
    as_long_format(dab_wgt),
    "different length-bin structures"
  )
})

testthat::test_that("as_long_format remove_vars can suppress auto-added columns", {
  out <- as_long_format(dab_cut, remove_vars = "HaulN")
  testthat::expect_false("HaulN" %in% names(out))
  testthat::expect_false("LengthGroup" %in% names(out))
  testthat::expect_equal(nrow(out), nrow(dab_cut[["HH"]]))
})

testthat::test_that("as_long_format succeeds when mismatched matrices are resolved via remove_vars", {
  dab_wgt <- add_total_weight_by_haul(dab_cut, length_cuts = c(0, 10, 30, Inf))
  out <- as_long_format(dab_wgt, remove_vars = "HaulWgt")
  testthat::expect_false("HaulWgt" %in% names(out))
  testthat::expect_true("HaulN" %in% names(out))
  testthat::expect_equal(nrow(out), nrow(dab_wgt[["HH"]]) * 2L)
})

testthat::test_that("as_long_format add_vars appends to defaults", {
  out <- as_long_format(dab, add_vars = "Depth")
  testthat::expect_true("Depth" %in% names(out))
  testthat::expect_true("Survey" %in% names(out))
})

testthat::test_that("as_long_format remove_vars drops from defaults", {
  out <- as_long_format(dab, remove_vars = c("Ship", "Country"))
  testthat::expect_false("Ship" %in% names(out))
  testthat::expect_false("Country" %in% names(out))
  testthat::expect_true("Survey" %in% names(out))
})


## as_wide_format --------------------------------------------------------------

testthat::test_that("as_wide_format returns a data frame", {
  testthat::expect_s3_class(as_wide_format(dab), "data.frame")
})

testthat::test_that("as_wide_format has one row per haul", {
  out <- as_wide_format(dab_cut)
  testthat::expect_equal(nrow(out), nrow(dab_cut[["HH"]]))
})

testthat::test_that("as_wide_format includes requested columns", {
  out <- as_wide_format(dab, vars = c("Survey", "Year"))
  testthat::expect_true(all(c("Survey", "Year") %in% names(out)))
})

testthat::test_that("as_wide_format auto-adds HaulN when present", {
  testthat::expect_true(any(grepl("^HaulN", names(as_wide_format(dab_cut)))))
  testthat::expect_false("HaulN" %in% names(as_wide_format(dab)))
})

testthat::test_that("as_wide_format expands matrix HaulN to columns", {
  out <- as_wide_format(dab_cut)
  testthat::expect_true(all(c("HaulN_(0-20]", "HaulN_(20-Inf]") %in% names(out)))
  testthat::expect_false(any(vapply(out, is.matrix, logical(1))))
})

testthat::test_that("as_wide_format handles two matrices with different bins", {
  dab_wgt <- add_total_weight_by_haul(dab_cut, length_cuts = c(0, 10, 20, Inf))
  out <- as_wide_format(dab_wgt)
  testthat::expect_true(any(grepl("^HaulN_", names(out))))
  testthat::expect_true(any(grepl("^HaulWgt_", names(out))))
  testthat::expect_equal(nrow(out), nrow(dab_wgt[["HH"]]))
})

testthat::test_that("as_wide_format warns and omits missing variables", {
  testthat::expect_warning(
    out <- as_wide_format(dab, vars = c("Survey", "foo")),
    "not found in HH"
  )
  testthat::expect_false("foo" %in% names(out))
})

testthat::test_that("as_wide_format handles xtabs N matrix from add_numbers_at_length", {
  out <- as_wide_format(dab_n, add_vars = "N")
  n_bins <- ncol(dab_n[["HH"]][["N"]])
  testthat::expect_equal(nrow(out), nrow(dab_n[["HH"]]))
  testthat::expect_equal(sum(grepl("^N_", names(out))), n_bins)
  testthat::expect_false(any(vapply(out, is.matrix, logical(1))))
})

testthat::test_that("as_long_format handles xtabs N matrix from add_numbers_at_length", {
  out <- as_long_format(dab_n, add_vars = "N", remove_vars = .default_hh_vars)
  n_bins <- ncol(dab_n[["HH"]][["N"]])
  testthat::expect_equal(nrow(out), nrow(dab_n[["HH"]]) * n_bins)
  testthat::expect_true("LengthGroup" %in% names(out))
  testthat::expect_false(is.matrix(out$N))
})

testthat::test_that("as_wide_format handles xtabs Wgt matrix from add_weight_at_length", {
  dab_w <- add_weight_at_length(dab_n)
  out <- as_wide_format(dab_w, add_vars = "Wgt")
  n_bins <- ncol(dab_w[["HH"]][["Wgt"]])
  testthat::expect_equal(nrow(out), nrow(dab_w[["HH"]]))
  testthat::expect_equal(sum(grepl("^Wgt_", names(out))), n_bins)
  testthat::expect_false(any(vapply(out, is.matrix, logical(1))))
})

testthat::test_that("as_wide_format add_vars appends to defaults", {
  out <- as_wide_format(dab, add_vars = "Depth")
  testthat::expect_true("Depth" %in% names(out))
  testthat::expect_true("Survey" %in% names(out))
})

testthat::test_that("as_wide_format remove_vars drops from defaults", {
  out <- as_wide_format(dab, remove_vars = c("Ship", "Country"))
  testthat::expect_false("Ship" %in% names(out))
  testthat::expect_false("Country" %in% names(out))
  testthat::expect_true("Survey" %in% names(out))
})


## as_table --------------------------------------------------------------------

testthat::test_that("as_table type=long matches as_long_format", {
  out1 <- as_table(dab_cut, vars = c("Survey", "Year"))
  out2 <- as_long_format(dab_cut, vars = c("Survey", "Year"))
  testthat::expect_equal(out1, out2)
})

testthat::test_that("as_table type=wide matches as_wide_format", {
  out1 <- as_table(dab_cut, type = "wide", vars = c("Survey", "Year"))
  out2 <- as_wide_format(dab_cut, vars = c("Survey", "Year"))
  testthat::expect_equal(out1, out2)
})
