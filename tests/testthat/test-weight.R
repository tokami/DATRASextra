
## require(DATRASextra); require(testthat)


## helpers ---------------------------------------------------------------------

dab_n <- add_numbers_at_length(dab)
mini_n <- add_numbers_at_length(mini)


## add_weight_at_length: lw_pars (single species) -------------------------------

testthat::test_that("lw_pars named vector produces weight matrix", {
  out <- add_weight_at_length(dab_n, lw_pars = c(a = 0.00832, b = 3.09))
  testthat::expect_true(is.matrix(out[["HH"]][["Wgt"]]))
  testthat::expect_true(all(out[["HH"]][["Wgt"]] >= 0))
})

testthat::test_that("lw_pars named list produces weight matrix", {
  out <- add_weight_at_length(dab_n, lw_pars = list(a = 0.00832, b = 3.09))
  testthat::expect_true(is.matrix(out[["HH"]][["Wgt"]]))
})

testthat::test_that("lw_pars data frame without aphia column works for single species", {
  out <- add_weight_at_length(dab_n,
                              lw_pars = data.frame(a = 0.00832, b = 3.09))
  testthat::expect_true(is.matrix(out[["HH"]][["Wgt"]]))
})

testthat::test_that("lw_pars produces same result as manual a*L^b calculation", {
  a <- 0.00832; b <- 3.09
  out_custom <- add_weight_at_length(dab_n, lw_pars = c(a = a, b = b))
  out_lookup <- add_weight_at_length(dab_n, lw_pars = list(a = a, b = b))
  testthat::expect_equal(out_custom[["HH"]][["Wgt"]],
                         out_lookup[["HH"]][["Wgt"]])
})

testthat::test_that("lw_pars errors when aphia column absent and multiple species present", {
  testthat::expect_error(
    add_weight_at_length(mini_n, lw_pars = c(a = 0.00832, b = 3.09)),
    "Valid_Aphia"
  )
})

testthat::test_that("lw_pars missing 'a' or 'b' raises an informative error", {
  testthat::expect_error(
    add_weight_at_length(dab_n, lw_pars = c(a = 0.01)),
    "'a' and 'b'"
  )
})


## add_weight_at_length: lw_pars with aphia column (multi-species) -------------

testthat::test_that("lw_pars data frame with Valid_Aphia works for multi-species", {
  aphia_ids <- unique(mini[["HL"]]$Valid_Aphia)
  pars <- data.frame(
    Valid_Aphia = aphia_ids,
    a = rep(0.008, length(aphia_ids)),
    b = rep(3.1,   length(aphia_ids))
  )
  out <- add_weight_at_length(mini_n, lw_pars = pars)
  testthat::expect_true(is.matrix(out[["HH"]][["Wgt"]]))
  testthat::expect_true(all(out[["HH"]][["Wgt"]] >= 0))
})

testthat::test_that("lw_pars with aphia alias column is accepted", {
  pars <- data.frame(aphia = 127139L, a = 0.00832, b = 3.09)
  out <- add_weight_at_length(dab_n, lw_pars = pars)
  testthat::expect_true(is.matrix(out[["HH"]][["Wgt"]]))
})

testthat::test_that("lw_pars partial coverage emits a message and still produces output", {
  aphia_ids <- unique(mini[["HL"]]$Valid_Aphia)
  pars <- data.frame(
    Valid_Aphia = aphia_ids[1],
    a = 0.008,
    b = 3.1
  )
  testthat::expect_message(
    out <- add_weight_at_length(mini_n, lw_pars = pars,
                                lw_source = "lookup"),
    "lw_pars does not cover all species"
  )
  testthat::expect_true(is.matrix(out[["HH"]][["Wgt"]]))
})


## add_total_weight_by_haul: lw_pars passthrough --------------------------------

testthat::test_that("add_total_weight_by_haul passes lw_pars through", {
  out <- add_total_weight_by_haul(dab_n, lw_pars = c(a = 0.00832, b = 3.09))
  testthat::expect_true(!is.null(out[["HH"]][["HaulWgt"]]))
  testthat::expect_true(all(out[["HH"]][["HaulWgt"]] >= 0))
})
