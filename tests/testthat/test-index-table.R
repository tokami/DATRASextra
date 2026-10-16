## require(DATRASextra); require(testthat)


test_that("as_surveyindex sets Nage, ctime and the factors", {

  x <- suppressWarnings(add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf)))
  x <- subset(x, Year %in% c("2021", "2022"))

  xs <- as_surveyindex(x, length_class = "(20-Inf]", scale = 2)
  expect_s3_class(xs, "datras_raw")
  expect_equal(xs$HH$Nage,
               matrix(2 * x$HH$HaulN[, 2], ncol = 1, dimnames = list(NULL, "1")),
               ignore_attr = "dimnames")
  expect_equal(colnames(xs$HH$Nage), "1")
  expect_equal(xs$HH$ctime, as.numeric(as.character(x$HH$Year)))
  expect_equal(levels(xs$HH$Year), c("2021", "2022"))
  expect_true(is.factor(xs$HH$Gear) && is.factor(xs$HH$Ship))

  ## one column per length class
  xb <- as_surveyindex(x, by_length_class = TRUE)
  expect_equal(colnames(xb$HH$Nage), c("1", "2"))
  expect_equal(unname(attr(xb$HH$Nage, "length_classes")), c("(0-20]", "(20-Inf]"))
  expect_equal(unname(xb$HH$Nage[, 2]), unname(x$HH$HaulN[, 2]))
})


## A minimal surveyIdx object: two age groups, three years, 95 % intervals
fake_si <- function() {
  idx <- matrix(c(10, 20, 30, 1, 2, 4), ncol = 2,
                dimnames = list(c("2001", "2002", "2003"), c("1", "2")))
  structure(list(idx = idx, lo = idx / 2, up = idx * 2, CIlevel = 0.95),
            class = "surveyIdx")
}

test_that("as_index_table turns a surveyIdx object into a table", {

  tab <- as_index_table(fake_si(), quarter = 3)
  expect_equal(names(tab), c("year", "group", "index", "lo", "up", "sd_log", "time"))
  expect_equal(tab$year, rep(2001:2003, 2))
  expect_equal(tab$group, rep(c("1", "2"), each = 3))
  expect_equal(tab$index, c(10, 20, 30, 1, 2, 4))
  ## interval index / 2 to index * 2: sd_log = log(4) / (2 * 1.96)
  expect_equal(tab$sd_log, rep(log(4) / (2 * stats::qnorm(0.975)), 6))
  expect_equal(tab$time, tab$year + 0.625)

  expect_equal(as_index_table(fake_si(), time_of_year = 0.2)$time, tab$year + 0.2)
  expect_false("time" %in% names(as_index_table(fake_si())))
})

test_that("as_index_table turns a stratified index into a table", {

  si <- data.frame(Year = c(2001, 2002), group = "HaulN", index = c(5, 6),
                   se = c(1, 1.2), cv = c(0.2, 0.2), ci_lower = c(3, 4),
                   ci_upper = c(7, 8))
  tab <- as_index_table(si, quarter = 1)
  expect_equal(tab$year, 2001:2002)
  expect_equal(tab$lo, c(3, 4))
  expect_equal(tab$sd_log, rep(sqrt(log(1.04)), 2))
  expect_equal(tab$time, c(2001.125, 2002.125))

  expect_error(as_index_table(data.frame(a = 1)), "surveyIdx")
  expect_error(as_index_table(si, quarter = 5), "1 to 4")
  expect_error(as_index_table(si, time_of_year = 1), "\\[0, 1\\)")
})
