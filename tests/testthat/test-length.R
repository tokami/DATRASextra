
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


## get_haul_catch and summarise_catch --------------------------------------------

## Five hauls in two years, with numbers in two length classes
catch_hauls <- function() {
  hh <- data.frame(Year = c(2001, 2001, 2001, 2002, 2002),
                   Survey = c("A", "A", "B", "A", "B"),
                   SweptArea = c(1, 2, 1, 0, 4))
  hh$HaulN <- matrix(c(0, 2, 0, 1, 0,
                       3, 0, 0, 4, 8), ncol = 2,
                     dimnames = list(NULL, c("(0-20]", "(20-Inf]")))
  hh$Total <- rowSums(hh$HaulN)
  hh
}

test_that("get_haul_catch sums all or selected length classes", {

  hh <- catch_hauls()
  expect_equal(get_haul_catch(hh), c(3, 2, 0, 5, 8))
  expect_equal(get_haul_catch(hh, length_class = "(20-Inf]"), c(3, 0, 0, 4, 8))
  expect_equal(get_haul_catch(hh, length_class = 1), c(0, 2, 0, 1, 0))
  expect_equal(get_haul_catch(hh, length_class = 1:2), get_haul_catch(hh))
  ## a vector column
  expect_equal(get_haul_catch(hh, var = "Total"), c(3, 2, 0, 5, 8))

  x <- suppressWarnings(add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf)))
  expect_equal(get_haul_catch(x), unname(rowSums(x$HH$HaulN)))

  expect_error(get_haul_catch(hh, length_class = "(5-10]"), "not found")
  expect_error(get_haul_catch(hh, length_class = 3), "positions")
  expect_error(get_haul_catch(hh, var = "HaulWgt"), "add_total_weight_by_haul")
  expect_error(get_haul_catch(1:3), "data frame")
})

test_that("summarise_catch counts positive hauls and averages the catch", {

  hh <- catch_hauls()
  s <- summarise_catch(hh, by = "Year")
  expect_equal(names(s), c("Year", "length_class", "hauls", "positive",
                           "pct_positive", "mean"))
  expect_equal(levels(s$length_class), c("(0-20]", "(20-Inf]", "all"))
  expect_equal(s$hauls, c(3, 3, 3, 2, 2, 2))
  expect_equal(s$positive, c(1L, 1L, 2L, 1L, 2L, 2L))
  expect_equal(s$pct_positive, 100 * s$positive / s$hauls)
  expect_equal(s$mean[s$length_class == "all"], c(5 / 3, 6.5))

  ## per unit of effort: the haul with zero effort is left out of the mean
  s2 <- summarise_catch(hh, by = "Year", offset = "SweptArea")
  expect_equal(s2$mean[s2$length_class == "all"], c(mean(c(3, 1, 0)), 2))
  expect_equal(s2$positive, s$positive)

  ## two grouping variables, and none
  s3 <- summarise_catch(hh, by = c("Year", "Survey"))
  expect_equal(nrow(s3), 4 * 3)
  expect_equal(unique(s3[, c("Year", "Survey")]),
               data.frame(Year = c(2001, 2001, 2002, 2002),
                          Survey = c("A", "B", "A", "B")),
               ignore_attr = TRUE)
  s4 <- summarise_catch(hh, by = NULL)
  expect_equal(s4$hauls, rep(5, 3))
  expect_equal(s4$positive, c(2L, 3L, 4L))

  ## a vector column: only "all"
  expect_equal(as.character(summarise_catch(hh, var = "Total")$length_class),
               c("all", "all"))
  expect_error(summarise_catch(hh, by = "Quarter"), "not found")
})
