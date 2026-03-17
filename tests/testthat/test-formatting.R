
## require(DATRASextra); require(testthat)


## as_long_format --------------------------------------------

test_that("as_long_format returns a data frame", {
  out <- as_long_format(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))
  expect_s3_class(out, "data.frame")
})

test_that("as_long_format includes requested columns", {
  out <- as_long_format(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))
  expect_true(all(c("Survey", "Year", "Species", "Aphia_ID") %in% names(out)))
})

test_that("as_long_format keeps haul.id", {
  out <- as_long_format(dab, vars = c("Survey", "Year", "Species"))
  expect_true("haul.id" %in% names(out))
})

test_that("as_long_format warns for missing variables and omits them", {
  expect_warning(
    out <- as_long_format(mini, vars = c("Survey", "Year", "foo", "Species")),
    "not found in HH or HL"
  )
  expect_false("foo" %in% names(out))
})


test_that("as_long_format expands rows when HL variables are requested", {
  out_hh <- as_long_format(mini, vars = c("Survey", "Year"))
  out_hl <- as_long_format(mini, vars = c("Survey", "Year", "Species"))
  expect_gte(nrow(out_hl), nrow(out_hh))
})


test_that("HH values are preserved in long format", {
  out <- as_long_format(dab, vars = c("Survey", "Year"))
  expect_true(all(!is.na(out$Survey)))
  expect_true(all(!is.na(out$Year)))
})


test_that("Species and Aphia_ID come from HL consistently", {
  out <- as_long_format(dab, vars = c("Species", "Aphia_ID"))
  expect_true(all(c("Species", "Aphia_ID") %in% names(out)))
})

test_that("Species matches expected Aphia_ID", {
  out <- as_long_format(dab, vars = c("Species", "Aphia_ID"))
  sel <- !is.na(out$Species)
  expect_true(all(out$Aphia_ID[sel] == 127139))
})




## as_wide_format -------------------------------------------

test_that("as_wide_format returns a data frame", {
  out <- as_wide_format(dab)
  expect_s3_class(out, "data.frame")
})

test_that("as_wide_format has one row per haul", {
  out <- as_wide_format(dab)
  expect_equal(nrow(out), length(unique(dab[["HH"]][["haul.id"]])))
})

test_that("as_wide_format keeps HH variables", {
  out <- as_wide_format(dab, vars_hh = c("Survey", "Year"))
  expect_true(all(c("Survey", "Year") %in% names(out)))
})

test_that("as_wide_format creates species-specific HL columns", {
  out <- as_wide_format(dab, vars_hl = "Count")
  expect_true(any(grepl("^Count__", names(out))))
})

test_that("as_wide_format warns for missing variables", {
  expect_warning(
    out <- as_wide_format(mini, vars_hh = c("Survey", "foo"), vars_hl = c("Count", "bar")),
    "not found"
  )
})




## as_table -------------------------------------------------

test_that("as_table", {

  out1 <- as_table(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))
  out2 <- as_long_format(dab, vars = c("Survey", "Year", "Species", "Aphia_ID"))

  expect_equal(out1, out2)

  out1 <- as_table(dab,
                   type = "wide",
                   vars_hh = c("Survey", "Year"),
                   vars_hl = "Species")
  out2 <- as_wide_format(dab,
                         vars_hh = c("Survey", "Year"),
                         vars_hl = "Species")

  expect_equal(out1, out2)
})
