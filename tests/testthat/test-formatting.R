
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


## as_tibble -------------------------------------------------------------------

testthat::test_that("as_tibble returns the as_table output as a tibble", {
  testthat::skip_if_not_installed("tibble")

  out <- tibble::as_tibble(dab_cut)
  testthat::expect_s3_class(out, "tbl_df")
  testthat::expect_equal(as.data.frame(out), as_table(dab_cut))
})

testthat::test_that("as_tibble passes the as_table arguments on", {
  testthat::skip_if_not_installed("tibble")

  out <- tibble::as_tibble(dab_cut, type = "wide", add_vars = "Depth",
                           remove_vars = "Ship")
  ref <- as_table(dab_cut, type = "wide", add_vars = "Depth",
                  remove_vars = "Ship")
  testthat::expect_equal(as.data.frame(out), ref)
  testthat::expect_true(any(grepl("^HaulN_", names(out))))
  testthat::expect_false("Ship" %in% names(out))
})

testthat::test_that("as_tibble passes other arguments to tibble", {
  testthat::skip_if_not_installed("tibble")

  out <- tibble::as_tibble(dab, vars = c("Survey", "Year"),
                           .name_repair = toupper)
  testthat::expect_equal(names(out), c("HAUL.ID", "SURVEY", "YEAR"))
})


## as_table(table = "HL") ------------------------------------------------------

testthat::test_that("HL table keeps the raised numbers of every haul", {
  out <- as_table(mini, table = "HL", vars = "Year")
  raw <- tapply(mini[["HL"]]$Count, as.character(mini[["HL"]]$haul.id), sum, na.rm = TRUE)
  tab <- tapply(out$Count, as.character(out$haul.id), sum, na.rm = TRUE)
  testthat::expect_equal(as.numeric(tab[names(raw)]), as.numeric(raw))
})

testthat::test_that("HL table agrees with HaulN once rounded as DATRAS does", {
  x <- suppressWarnings(add_total_numbers_by_haul(add_numbers_at_length(dab)))
  out <- as_table(dab, table = "HL", vars = "Year", zeros = FALSE)
  out$bin <- cut(out$LngtCm, attr(x, "cm.breaks"), right = FALSE)
  b <- stats::aggregate(Count ~ haul.id + bin, data = out, FUN = sum)
  s <- tapply(round(b$Count), as.character(b$haul.id), sum)
  s <- s[as.character(x[["HH"]]$haul.id)]
  s[is.na(s)] <- 0
  testthat::expect_equal(as.numeric(s), as.numeric(x[["HH"]]$HaulN))
})

testthat::test_that("zeros = TRUE gives every haul x species", {
  out <- as_table(mini, table = "HL", vars = "Year")
  n_sp <- length(unique(mini[["HL"]]$Valid_Aphia))
  pairs <- unique(paste(out$haul.id, out$Valid_Aphia))
  testthat::expect_equal(length(pairs), nrow(mini[["HH"]]) * n_sp)

  ## The added rows are zeros with no length and a species name
  no <- as_table(mini, table = "HL", vars = "Year", zeros = FALSE)
  added <- nrow(out) - nrow(no)
  testthat::expect_gt(added, 0)
  testthat::expect_equal(sum(out$Count == 0 & is.na(out$LngtCm), na.rm = TRUE),
                         added + sum(no$Count == 0 & is.na(no$LngtCm), na.rm = TRUE))
  testthat::expect_false(anyNA(out$Species))
  testthat::expect_equal(sum(out$Count, na.rm = TRUE), sum(no$Count, na.rm = TRUE))
})

testthat::test_that("records without a length keep NA counts, not zero", {
  na_rows <- is.na(mini[["HL"]]$LngtCm) & is.na(mini[["HL"]]$Count)
  testthat::skip_if(!any(na_rows), "mini has no records without length")
  out <- as_table(mini, table = "HL", vars = "Year", zeros = FALSE)
  testthat::expect_true(any(is.na(out$LngtCm) & is.na(out$Count)))
})

testthat::test_that("hl_by can keep sexes apart without changing totals", {
  a <- as_table(mini, table = "HL", vars = "Year")
  b <- as_table(mini, table = "HL", vars = "Year",
                hl_by = c("Valid_Aphia", "Sex", "LngtCm"))
  testthat::expect_true("Sex" %in% names(b))
  testthat::expect_gte(nrow(b), nrow(a))
  testthat::expect_equal(sum(b$Count, na.rm = TRUE), sum(a$Count, na.rm = TRUE))
})

testthat::test_that("HL rows follow the haul order of HH", {
  out <- as_table(dab, table = "HL", vars = "Year")
  pos <- match(as.character(out$haul.id), as.character(dab[["HH"]]$haul.id))
  testthat::expect_false(is.unsorted(pos))
})

testthat::test_that("wide HL table has one row per haul x species and the same totals", {
  long <- as_table(mini, table = "HL", vars = "Year")
  wide <- as_table(mini, table = "HL", vars = "Year", type = "wide")
  cnt <- grep("^Count_", names(wide), value = TRUE)

  testthat::expect_equal(nrow(wide), length(unique(paste(long$haul.id, long$Valid_Aphia))))
  testthat::expect_equal(sum(wide[cnt], na.rm = TRUE), sum(long$Count, na.rm = TRUE))
  testthat::expect_false("LngtCm" %in% names(wide))

  ## A haul x species without records is a row of zeros
  zero <- long$Count == 0 & is.na(long$LngtCm)
  k <- paste(long$haul.id, long$Valid_Aphia)[which(zero)[1]]
  r <- wide[paste(wide$haul.id, wide$Valid_Aphia) == k, cnt]
  testthat::expect_true(all(r == 0))
})

testthat::test_that("HL table errors and warnings", {
  x <- dab
  x[["HL"]] <- NULL
  testthat::expect_error(as_table(x, table = "HL"), "no HL table")
  testthat::expect_error(as_table(dab, table = "HL", hl_by = "LngtCm"), "Valid_Aphia")
  testthat::expect_error(as_table(dab, table = "HL", type = "wide", hl_by = "Valid_Aphia"),
                         "LngtCm")

  ## Matrix columns of HH are not attached; haul totals are not auto-added
  testthat::expect_warning(out <- as_table(dab_cut, table = "HL", add_vars = "HaulN"),
                           "Matrix columns")
  testthat::expect_false("HaulN" %in% names(out))
  out <- as_table(dab_tot, table = "HL")
  testthat::expect_false("HaulN" %in% names(out))
})


## as_table(table = "CA") ------------------------------------------------------

testthat::test_that("CA table has one row per record with HH variables", {
  out <- as_table(dab, table = "CA", vars = c("Year", "lon", "lat"))
  testthat::expect_equal(nrow(out), nrow(dab[["CA"]]))
  testthat::expect_true(all(c("haul.id", "Year", "lon", "lat", "Age", "IndWgt") %in% names(out)))
  testthat::expect_equal(sum(names(out) == "Year"), 1)
  i <- match(as.character(out$haul.id), as.character(dab[["HH"]]$haul.id))
  testthat::expect_equal(out$lon, dab[["HH"]]$lon[i])
})

testthat::test_that("unmatched CA records are kept and reported", {
  x <- dab
  ca <- x[["CA"]]
  ca$haul.id[1:3] <- NA
  x[["CA"]] <- ca

  testthat::expect_message(out <- as_table(x, table = "CA", vars = c("Year", "lon")),
                           "3 CA record")
  testthat::expect_equal(nrow(out), nrow(ca))
  testthat::expect_true(all(is.na(out$lon[1:3])))
  testthat::expect_equal(as.character(out$Year[1:3]), as.character(ca$Year[1:3]))
})

testthat::test_that("CA table errors and warnings", {
  testthat::expect_error(as_table(dab, table = "CA", type = "wide"), "not available")
  testthat::expect_warning(as_table(dab, table = "CA", ca_vars = c("Age", "foo")), "foo")
  x <- dab
  x[["CA"]] <- NULL
  testthat::expect_error(as_table(x, table = "CA"), "no CA table")
})

testthat::test_that("as_tibble passes table on", {
  testthat::skip_if_not_installed("tibble")
  out <- tibble::as_tibble(dab, table = "HL", vars = "Year")
  testthat::expect_s3_class(out, "tbl_df")
  testthat::expect_equal(as.data.frame(out), as_table(dab, table = "HL", vars = "Year"))
})
