
## require(DATRASextra); require(testthat)


test_that("check_lengths works", {
  out <- check_lengths(dab)
  expect_equal(class(out), class(dab))
  expect_false(is.null(attr(out, "length_check")))
  expect_true(!is.na(attr(out, "length_check")$lPars$min))
  expect_error(check_lengths(NULL))
  ## expect_warning(check_lengths(NA))
})



test_that("add_numbers_at_length adds N to HH", {

  out <- add_numbers_at_length(dab)

  expect_equal(class(out), class(dab))
  expect_true("N" %in% names(out[["HH"]]))
  expect_true(is.matrix(out[["HH"]][["N"]]))

  ## one row per haul
  expect_equal(nrow(out[["HH"]][["N"]]), nrow(out[["HH"]]))

  ## should have at least one length bin
  expect_gt(ncol(out[["HH"]][["N"]]), 0)

  ## rownames should match haul ids
  expect_equal(rownames(out[["HH"]][["N"]]), as.character(out[["HH"]][["haul.id"]]))

  ## cm.breaks attribute should be present
  expect_true(!is.null(attr(out, "cm.breaks")))
  expect_true(is.numeric(attr(out, "cm.breaks")))
})


test_that("add_total_numbers_by_haul adds HaulN and N when N is absent", {

  x <- dab
  x[["HH"]][["N"]] <- NULL

  out <- add_total_numbers_by_haul(x)

  expect_equal(class(out), class(dab))
  expect_true("N" %in% names(out[["HH"]]))
  expect_true("HaulN" %in% names(out[["HH"]]))

  expect_true(is.matrix(out[["HH"]][["N"]]))
  expect_equal(length(out[["HH"]][["HaulN"]]), nrow(out[["HH"]]))

  ## HaulN should equal the row sums of N
  expect_equal(
    unname(out[["HH"]][["HaulN"]]),
    unname(rowSums(out[["HH"]][["N"]], na.rm = TRUE))
  )
})


test_that("add_total_numbers_by_haul uses existing N correctly", {

  x <- add_numbers_at_length(dab)
  N_before <- x[["HH"]][["N"]]

  out <- add_total_numbers_by_haul(x)

  expect_true("HaulN" %in% names(out[["HH"]]))

  ## existing N should remain unchanged
  expect_equal(out[["HH"]][["N"]], N_before)

  ## HaulN should equal the row sums of N
  expect_equal(
    unname(out[["HH"]][["HaulN"]]),
    unname(rowSums(N_before, na.rm = TRUE))
  )
})


test_that("add_numbers_at_length adds N matrix to HH", {

  out <- add_numbers_at_length(dab)

  expect_true("N" %in% names(out[["HH"]]))
  expect_true(is.matrix(out[["HH"]][["N"]]))
  expect_equal(nrow(out[["HH"]][["N"]]), nrow(out[["HH"]]))
})


test_that("add_total_numbers_by_haul adds HaulN consistent with N", {

  out <- add_total_numbers_by_haul(dab)

  expect_true("N" %in% names(out[["HH"]]))
  expect_true("HaulN" %in% names(out[["HH"]]))
  expect_equal(
    unname(out[["HH"]][["HaulN"]]),
    unname(rowSums(out[["HH"]][["N"]], na.rm = TRUE))
    )
})



test_that("add_total_numbers_by_haul with length_cuts creates expected bins", {

  cuts <- c(0, 20, 40, 60, 100)

  out <- add_total_numbers_by_haul(dab, length_cuts = cuts)

  expect_true("HaulN" %in% names(out[["HH"]]))
  expect_true(is.matrix(out[["HH"]][["HaulN"]]))

  ## number of output bins should match cuts - 1
  expect_equal(ncol(out[["HH"]][["HaulN"]]), length(cuts) - 1)
})


test_that("add_total_numbers_by_haul with length_cuts preserves numbers at length", {

  out_full <- add_numbers_at_length(dab)
  out_cut  <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, 40, 60, 100))

  ## aggregating length classes should not change the total per haul
  expect_equal(
    rowSums(out_cut[["HH"]][["N"]], na.rm = TRUE),
    rowSums(out_full[["HH"]][["N"]], na.rm = TRUE)
  )
})
