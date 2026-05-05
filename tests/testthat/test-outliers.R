
## require(DATRASextra); require(testthat)

expected_cols <- c("table", "var", "row", "haul.id", "value",
                   "reason", "method", "severity",
                   "p_lo", "p_hi", "thr_lo", "thr_hi", "group")

## DATRASraw objects use [[ not $; this helper modifies HH in a copy
.corrupt_hh <- function(x, field, value) {
  x[["HH"]][[field]][1] <- value
  x
}

## minimal synthetic DATRASraw for rules that dab cannot exercise easily
.make_synthetic <- function(hh = NULL, hl = NULL, ca = NULL) {
  base_hh <- data.frame(
    haul.id    = "1",
    Survey     = "NS-IBTS",
    Quarter    = 1L,
    Year       = 2010L,
    HaulDur    = 30,
    ShootLat   = 55.0,
    ShootLong  = 5.0,
    Depth      = 80,
    DoorSpread = 80.0,
    WingSpread = 50.0,
    GroundSpeed = 3.0,
    stringsAsFactors = FALSE
  )
  base_hl <- data.frame(haul.id = character(0), stringsAsFactors = FALSE)
  base_ca <- data.frame(haul.id = character(0), stringsAsFactors = FALSE)

  res <- list(
    CA = if (is.null(ca)) base_ca else ca,
    HH = if (is.null(hh)) base_hh else hh,
    HL = if (is.null(hl)) base_hl else hl
  )
  class(res) <- c("datras_raw", "DATRASraw")
  res
}

## ── structure checks ──────────────────────────────────────────────────────────

test_that("check_outliers returns the right structure on clean data", {
  out <- check_outliers(dab, verbose = FALSE)

  expect_true(is.list(out))
  expect_true(all(c("HH", "HL", "CA") %in% names(out)))

  rpt <- attr(out, "outlier_report")
  expect_true(is.data.frame(rpt))
  expect_true(all(expected_cols %in% names(rpt)))

  expect_true(is.character(attr(out, "outlier_hauls")))
  expect_true(is.character(attr(out, "outlier_hauls_invalid")))
  expect_true(is.character(attr(out, "outlier_hauls_extreme")))
})

test_that("check_outliers works on mini dataset", {
  out <- check_outliers(mini, verbose = FALSE)
  expect_true(is.list(out))
  expect_true(is.data.frame(attr(out, "outlier_report")))
})

## ── rule-based checks on dab (numeric HH columns) ────────────────────────────

test_that("rule-based checks flag known-bad values in dab", {

  bad <- .corrupt_hh(dab, "ShootLat", 999)
  out <- check_outliers(bad, verbose = FALSE)
  rpt <- attr(out, "outlier_report")
  expect_true(nrow(rpt) > 0)
  expect_true(any(rpt$var == "ShootLat"))
  expect_true(all(rpt$method[rpt$var == "ShootLat"] == "rule"))
  expect_true(all(rpt$severity[rpt$var == "ShootLat"] == "invalid"))

  bad <- .corrupt_hh(dab, "ShootLong", -999)
  rpt <- attr(check_outliers(bad, verbose = FALSE), "outlier_report")
  expect_true(any(rpt$var == "ShootLong"))

  bad <- .corrupt_hh(dab, "HaulDur", 9999)
  rpt <- attr(check_outliers(bad, verbose = FALSE), "outlier_report")
  expect_true(any(rpt$var == "HaulDur"))
})

## ── rules that need synthetic (numeric) Quarter / Year / GroundSpeed ─────────

test_that("Quarter rule flags values outside 1-4", {
  syn <- .make_synthetic()
  syn[["HH"]]$Quarter <- 9L
  rpt <- attr(check_outliers(syn, verbose = FALSE), "outlier_report")
  expect_true(any(rpt$var == "Quarter"))

  syn2 <- .make_synthetic()
  rpt2 <- attr(check_outliers(syn2, verbose = FALSE), "outlier_report")
  expect_false(any(rpt2$var == "Quarter"))
})

test_that("Year rule flags values before 1965", {
  syn <- .make_synthetic()
  syn[["HH"]]$Year <- 1900L
  rpt <- attr(check_outliers(syn, verbose = FALSE), "outlier_report")
  expect_true(any(rpt$var == "Year"))

  syn2 <- .make_synthetic()
  rpt2 <- attr(check_outliers(syn2, verbose = FALSE), "outlier_report")
  expect_false(any(rpt2$var == "Year"))
})

test_that("GroundSpeed rule flags implausible speeds", {
  syn <- .make_synthetic()
  syn[["HH"]]$GroundSpeed <- 50
  rpt <- attr(check_outliers(syn, verbose = FALSE), "outlier_report")
  expect_true(any(rpt$var == "GroundSpeed"))
})

## ── WingSpread > DoorSpread (strict >): equal values are NOT flagged ──────────

test_that("WingSpread > DoorSpread is flagged; equal values are not", {
  syn <- .make_synthetic()
  syn[["HH"]]$WingSpread <- syn[["HH"]]$DoorSpread + 1   # strictly greater: flag
  rpt <- attr(check_outliers(syn, verbose = FALSE), "outlier_report")
  expect_true(any(grepl("WingSpread", rpt$var)))

  syn2 <- .make_synthetic()
  syn2[["HH"]]$WingSpread <- syn2[["HH"]]$DoorSpread     # equal: do NOT flag
  rpt2 <- attr(check_outliers(syn2, verbose = FALSE), "outlier_report")
  ws_ds_flags <- rpt2[grepl("WingSpread,DoorSpread", rpt2$var), ]
  expect_equal(nrow(ws_ds_flags), 0L)
})

## ── action = "remove" ────────────────────────────────────────────────────────

test_that("action = 'remove' reduces haul count", {
  bad <- .corrupt_hh(dab, "ShootLat", 999)
  n_before <- nrow(dab[["HH"]])

  out <- check_outliers(bad, action = "remove", verbose = FALSE)
  expect_true(nrow(out[["HH"]]) < n_before)

  bad_ids <- attr(out, "outlier_hauls_invalid")
  expect_false(any(out[["HH"]]$haul.id %in% bad_ids))
})

test_that("action = 'report' does not modify the data", {
  bad <- .corrupt_hh(dab, "ShootLat", 999)
  out <- check_outliers(bad, action = "report", verbose = FALSE)
  expect_equal(nrow(out[["HH"]]), nrow(bad[["HH"]]))
})

## ── percentile checks ─────────────────────────────────────────────────────────

test_that("pct = TRUE adds percentile rows to the report", {
  out_no_pct   <- check_outliers(dab, pct = FALSE, verbose = FALSE)
  out_with_pct <- check_outliers(dab, pct = TRUE,  verbose = FALSE)

  rpt_pct <- attr(out_with_pct, "outlier_report")
  expect_true(nrow(rpt_pct) >= nrow(attr(out_no_pct, "outlier_report")))

  pct_rows <- rpt_pct[rpt_pct$method == "percentile", ]
  if (nrow(pct_rows) > 0) {
    expect_true(all(pct_rows$severity == "extreme"))
    expect_true(all(!is.na(pct_rows$p_lo)))
    expect_true(all(!is.na(pct_rows$p_hi)))
  }
})

## ── warnings for no-op argument combinations ─────────────────────────────────

test_that("remove_extremes = TRUE with action = 'report' warns", {
  ## use pct = TRUE so the pct-warning does not also fire
  expect_warning(
    check_outliers(dab, action = "report", pct = TRUE, remove_extremes = TRUE, verbose = FALSE),
    "no effect when action"
  )
})

test_that("remove_extremes = TRUE with pct = FALSE warns", {
  ## use action = "remove" so the action-warning does not also fire
  expect_warning(
    check_outliers(dab, pct = FALSE, action = "remove", remove_extremes = TRUE, verbose = FALSE),
    "no effect when pct = FALSE"
  )
})

## ── vars subsetting ───────────────────────────────────────────────────────────

test_that("vars subsetting limits which rules are applied", {
  out <- check_outliers(
    .corrupt_hh(dab, "ShootLat", 999),
    vars = "HaulDur",
    verbose = FALSE
  )
  rpt <- attr(out, "outlier_report")
  expect_false(any(rpt$var == "ShootLat"))
})

## ── robustness ───────────────────────────────────────────────────────────────

test_that("pct_by with a missing column uses the available columns, not all-group", {
  x <- dab
  x[["HL"]]$Valid_Aphia <- NULL   # remove if present
  expect_no_error(
    check_outliers(x, pct = TRUE, pct_min_n = 10, verbose = FALSE)
  )
})

test_that("empty CA/HL tables do not cause errors", {
  x <- dab
  x[["CA"]] <- x[["CA"]][integer(0), ]
  x[["HL"]] <- x[["HL"]][integer(0), ]
  expect_no_error(check_outliers(x, verbose = FALSE))
})
