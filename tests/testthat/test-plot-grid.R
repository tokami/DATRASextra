## require(DATRASextra); require(testthat)


## A 6 x 4 grid of 10 km cells: area A west of X = 30, B east of it, with a
## missing cell, and values of each type
small_grid <- function() {
  g <- expand.grid(X = seq(5, 55, by = 10), Y = seq(5, 35, by = 10))
  g$Area <- ifelse(g$X < 30, "A", "B")
  g$depth <- g$X + g$Y
  g$flag <- g$Y > 20
  g$status <- factor(ifelse(g$X > 40, "far", "near"), levels = c("near", "far", "none"))
  g[-1, ]
}


test_that("plot_grid draws one panel per column and returns the legends", {

  g <- small_grid()
  hauls <- data.frame(X = c(10, 40), Y = c(10, 30))
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())

  op <- graphics::par("mfrow", "mar", "oma")
  out <- plot_grid(g, c("depth", "flag", "status"), hauls = hauls,
                   areas = "Area", plot_map = FALSE, n_breaks = 4)
  expect_equal(graphics::par("mfrow", "mar", "oma"), op)

  expect_named(out, c("depth", "flag", "status"))
  ## numeric: classes covering the values
  b <- out$depth$breaks
  expect_true(min(b) <= min(g$depth) && max(b) >= max(g$depth))
  expect_length(out$depth$col, length(b) - 1)
  ## logical and factor: categories, all factor levels
  expect_equal(out$flag$labels, c("TRUE", "FALSE"))
  expect_equal(unname(out$flag$col), DATRASextra:::.colours_datrasextra_continuous(6)[c(5, 1)])
  expect_equal(out$status$labels, c("near", "far", "none"))
  expect_null(out$status$breaks)

  ## colours by panel, by name
  out2 <- plot_grid(g, c("depth", "status"), plot_map = FALSE,
                    col = list(status = c(far = "red", near = "blue", none = "grey")))
  expect_equal(out2$status$col, c("blue", "red", "grey"))
  ## no colours for depth: the default palette
  expect_equal(out2$depth, plot_grid(g, "depth", plot_map = FALSE)$depth)

  ## user breaks and transform: labels in the units of the column
  out3 <- plot_grid(g, "depth", plot_map = FALSE, breaks = c(0, 25, 100),
                    transform = "sqrt")
  expect_equal(out3$depth$breaks, c(0, 25, 100))
  expect_equal(out3$depth$labels, c("0 - 25", "25 - 100"))

  ## logical columns: labels, and colours by TRUE/FALSE or by position
  out4 <- plot_grid(g, "flag", plot_map = FALSE, logical_labels = c("yes", "no"))
  expect_equal(out4$flag$labels, c("yes", "no"))
  out5 <- plot_grid(g, "flag", plot_map = FALSE, col = c("FALSE" = "white", "TRUE" = "black"),
                    logical_labels = c("yes", "no"))
  expect_equal(unname(out5$flag$col), c("black", "white"))
  out6 <- plot_grid(g, "flag", plot_map = FALSE, col = c("red", "blue"))
  expect_equal(unname(out6$flag$col), c("red", "blue"))

  ## several rows of panels, and panels into an existing layout
  expect_silent(plot_grid(g, c("depth", "flag", "status", "depth"), nrow = 2,
                          plot_map = FALSE))
  graphics::par(mfrow = c(1, 2))
  expect_silent(plot_grid(g, "depth", plot_map = FALSE, add = TRUE))
  graphics::par(mfrow = c(1, 1))

  ## hauls per panel
  expect_silent(plot_grid(g, c("depth", "flag"), hauls = list(hauls, NULL),
                          plot_map = FALSE))
})


test_that("plot_grid draws land in projected and geographic coordinates", {
  skip_if_not_installed("sf")

  hh <- dab[["HH"]]
  g <- expand.grid(lon = seq(-2, 8, by = 0.5), lat = seq(50, 56, by = 0.5))
  g$v <- g$lat
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())

  expect_silent(plot_grid(g, "v", coords = c("lon", "lat"), crs = 4326,
                          hauls = hh))

  gx <- add_xy(g)
  gx <- gx[, c("X", "Y", "v")]
  gx$X <- round(gx$X / 50) * 50
  gx$Y <- round(gx$Y / 50) * 50
  gx <- gx[!duplicated(gx[, c("X", "Y")]), ]
  expect_silent(plot_grid(gx, "v", resolution = 50))
})


test_that("plot_grid checks its inputs", {

  g <- small_grid()
  expect_error(plot_grid(g, "nope", plot_map = FALSE), "not found in grid")
  expect_error(plot_grid(rbind(g, g), "depth", plot_map = FALSE), "one row per node")
  expect_error(plot_grid(g, "depth", main = c("a", "b"), plot_map = FALSE),
               "one title per column")
  expect_error(plot_grid(g, "depth", hauls = data.frame(lon = 1, lat = 1),
                         plot_map = FALSE), "columns 'X' and 'Y'")
  expect_error(plot_grid(g, c("depth", "flag"), hauls = list(g), plot_map = FALSE),
               "one element per column")
  expect_error(plot_grid(g, "depth", col = list("red", "blue"), plot_map = FALSE),
               "one element per column")
  expect_error(plot_grid(g, "flag", logical_labels = "a", plot_map = FALSE),
               "two different labels")
})


test_that("area boundaries run along the cell edges where the area changes", {

  g <- small_grid()
  xs <- seq(5, 55, by = 10)
  ys <- seq(5, 35, by = 10)
  e <- DATRASextra:::.grid_area_edges(g$Area, round((g$X - 5) / 10) + 1,
                                      round((g$Y - 5) / 10) + 1, xs, ys, 10)
  ## one vertical edge at X = 30 per row of cells, none horizontal
  expect_equal(nrow(e), 4)
  expect_true(all(e$x0 == 30 & e$x1 == 30))
  expect_equal(sort(e$y0), c(0, 10, 20, 30))
  expect_equal(e$y1 - e$y0, rep(10, 4))

  ## a missing neighbour is not a boundary
  g2 <- g[!(g$X == 35 & g$Y == 15), ]
  e2 <- DATRASextra:::.grid_area_edges(g2$Area, round((g2$X - 5) / 10) + 1,
                                       round((g2$Y - 5) / 10) + 1, xs, ys, 10)
  expect_equal(nrow(e2), 3)
})
