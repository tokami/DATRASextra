## require(DATRASextra); require(testthat)


## Three rings of points around the origin: a survey area with a hole of about
## 15 units across once max_dist = 1.5 is applied
ring_points <- function() {
  a <- seq(0, 2 * pi, length.out = 80)
  r <- rep(c(9, 10, 11), each = length(a))
  list(x = r * cos(rep(a, 3)), y = r * sin(rep(a, 3)))
}


## make_survey_grid -------------------------------------------------------------

test_that("make_survey_grid without fill_gaps keeps the nearest-neighbour filter", {
  skip_if_not_installed("RANN")

  trawls <- unique(dab[["HH"]][, c("lon", "lat")])
  g <- make_survey_grid(trawls$lon, trawls$lat, 0.1, max_dist = 0.3)

  ## Recorded before fill_gaps was added
  expect_equal(nrow(g), 8326)
  expect_equal(sum(g$X), 22571.8, tolerance = 1e-8)
  expect_equal(sum(g$Y), 471676.5, tolerance = 1e-8)

  obs <- unique(stats::na.omit(cbind(trawls$lon, trawls$lat)))
  d <- RANN::nn2(obs, as.matrix(g[, c("X", "Y")]), k = 1)$nn.dists[, 1]
  expect_true(all(d <= 0.3))
})

test_that("fill_gaps closes holes narrower than about 2 * fill_gaps", {
  skip_if_not_installed("RANN")

  p <- ring_points()
  centre <- function(g) any(abs(g$X) < 0.3 & abs(g$Y) < 0.3)

  g0 <- make_survey_grid(p$x, p$y, 0.5, max_dist = 1.5)
  g_small <- make_survey_grid(p$x, p$y, 0.5, max_dist = 1.5, fill_gaps = 5)
  g_large <- make_survey_grid(p$x, p$y, 0.5, max_dist = 1.5, fill_gaps = 10)

  expect_false(centre(g0))
  expect_false(centre(g_small))
  expect_true(centre(g_large))

  ## Filling only adds nodes, and the outer edge grows by at most one cell
  key <- function(g) paste(g$X, g$Y)
  expect_true(all(key(g0) %in% key(g_large)))
  radius <- function(g) max(sqrt(g$X^2 + g$Y^2))
  expect_lte(radius(g_large), radius(g0) + 0.5)
})

test_that("fill_gaps needs max_dist and keeps the time dimension", {
  skip_if_not_installed("RANN")

  p <- ring_points()
  expect_error(make_survey_grid(p$x, p$y, 0.5, fill_gaps = 5), "max_dist")

  g <- make_survey_grid(p$x, p$y, 0.5, max_dist = 1.5, fill_gaps = 10,
                        time = 2001:2003)
  expect_equal(sort(unique(g$year)), 2001:2003)
  expect_equal(nrow(g), 3 * nrow(make_survey_grid(p$x, p$y, 0.5, max_dist = 1.5,
                                                  fill_gaps = 10)))
})


## add_grid_support -------------------------------------------------------------

test_that("add_grid_support flags support by year and window", {
  skip_if_not_installed("RANN")

  ## Hauls in the west in 2001, in the east in 2003, everywhere in 2005
  west <- expand.grid(x = 0:4, y = 0:4)
  east <- expand.grid(x = 10:14, y = 0:4)
  hx <- c(west$x, east$x, west$x, east$x)
  hy <- c(west$y, east$y, west$y, east$y)
  ht <- rep(c(2001, 2003, 2005, 2005), each = nrow(west))

  grid <- make_survey_grid(hx, hy, 1, max_dist = 1, time = 2001:2005)
  out <- add_grid_support(grid, hx, hy, ht, max_dist = 1, window = 1)

  is_west <- out$X <= 5
  ## 2002: 2001 (west) and 2003 (east) are within one year
  expect_true(all(out$supported[out$year == 2002]))
  ## 2001: only the west is supported
  expect_true(all(out$supported[out$year == 2001 & is_west]))
  expect_false(any(out$supported[out$year == 2001 & !is_west]))

  ## window = 0: 2002 and 2004 have no hauls
  out0 <- add_grid_support(grid, hx, hy, ht, max_dist = 1, window = 0)
  expect_false(any(out0$supported[out0$year %in% c(2002, 2004)]))

  ## coverage over the 5 grid years: west covered in 2001 and 2005
  expect_true(all(out$coverage >= 0 & out$coverage <= 1))
  expect_equal(unique(out$coverage[is_west]), 2 / 5)
  expect_equal(unique(out$coverage[!is_west]), 2 / 5)
  expect_equal(nrow(out), nrow(grid))
})

test_that("add_grid_support without a year column uses all hauls", {
  skip_if_not_installed("RANN")

  p <- ring_points()
  grid <- make_survey_grid(p$x, p$y, 0.5, max_dist = 1.5)
  out <- add_grid_support(grid, p$x, p$y, rep(2001, length(p$x)), max_dist = 1.5)
  expect_true(all(out$supported))
  expect_true(all(out$coverage == 1))
})

test_that("add_grid_support checks its inputs", {
  expect_error(add_grid_support(data.frame(a = 1), 1, 1, 1, max_dist = 1), "X and Y")
  expect_error(add_grid_support(data.frame(X = 1, Y = 1), 1:2, 1, 1, max_dist = 1),
               "same length")
})


## add_bathymetry ---------------------------------------------------------------

test_that("add_bathymetry adds positive depth, NA on land and outside", {
  skip_if_not_installed("marmap")

  ## Depth increases eastwards; land west of lon 0.2
  xyz <- expand.grid(lon = seq(0, 2, by = 0.5), lat = seq(50, 52, by = 0.5))
  xyz$z <- -100 * xyz$lon + 20
  bathy <- marmap::as.bathy(xyz)

  d <- data.frame(lon = c(0, 1, 2, 5, NA), lat = c(50, 51, 52, 51, 51))
  out <- add_bathymetry(d, bathy = bathy, depth_range = c(50, 150))

  expect_equal(out$Depth, c(NA, 80, 180, NA, NA))
  expect_equal(out$depth_ok, c(FALSE, TRUE, FALSE, FALSE, FALSE))

  ## datras_raw: added to HH under another name
  x <- dab
  hh <- x[["HH"]]
  hh$lon <- 1
  hh$lat <- 51
  x[["HH"]] <- hh
  y <- add_bathymetry(x, bathy = bathy, col = "DepthNOAA")
  expect_true(all(y[["HH"]]$DepthNOAA == 80))
  expect_equal(y[["HH"]]$Depth, x[["HH"]]$Depth)

  expect_error(add_bathymetry(d, bathy = bathy, depth_range = 1), "length 2")
})


## suggest_length_cuts ----------------------------------------------------------

test_that("suggest_length_cuts splits the catch into about equal groups", {
  x <- suppressWarnings(add_numbers_at_length(dab))
  cuts <- suggest_length_cuts(x, 3)

  expect_equal(cuts[1], 0)
  expect_equal(cuts[length(cuts)], Inf)
  expect_length(cuts, 4)
  expect_equal(sum(attr(cuts, "shares")), 1)
  expect_true(all(abs(attr(cuts, "shares") - 1 / 3) < 0.15))
  expect_equal(attr(cuts, "labels")[3], paste0(cuts[3], "+ cm"))

  ## The shares are those of add_total_numbers_by_haul()
  y <- add_total_numbers_by_haul(x, length_cuts = cuts)
  tot <- colSums(y[["HH"]]$HaulN)
  expect_equal(unname(tot / sum(tot)), attr(cuts, "shares"))
})

test_that("suggest_length_cuts warns when fewer groups are possible", {
  x <- suppressWarnings(add_numbers_at_length(dab))
  expect_warning(cuts <- suggest_length_cuts(x, 200), "distinct length groups")
  expect_lt(length(cuts) - 1, 200)
  expect_false(any(attr(cuts, "shares") == 0))

  expect_error(suggest_length_cuts(dab, 3), "add_numbers_at_length")
  expect_error(suggest_length_cuts(x, 1), "at least 2")
})


## add_xy -----------------------------------------------------------------------

test_that("add_xy projects and back-transforms coordinates", {
  skip_if_not_installed("sf")

  x <- add_xy(dab)
  hh <- x[["HH"]]
  expect_true(all(c("X", "Y") %in% names(hh)))
  ## EPSG:3035 in km for the North Sea
  expect_true(all(hh$X > 3000 & hh$X < 5000, na.rm = TRUE))

  back <- add_xy(data.frame(X = hh$X, Y = hh$Y), inverse = TRUE)
  expect_equal(back$lon, hh$lon, tolerance = 1e-8)
  expect_equal(back$lat, hh$lat, tolerance = 1e-8)

  ## Metres, and missing positions
  d <- data.frame(lon = c(hh$lon[1], NA), lat = c(hh$lat[1], 56))
  m <- add_xy(d, units = "m")
  expect_equal(m$X[1], hh$X[1] * 1000, tolerance = 1e-8)
  expect_true(is.na(m$X[2]))

  expect_error(add_xy(data.frame(a = 1)), "lon")
})
