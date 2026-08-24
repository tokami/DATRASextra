## require(DATRASextra); require(testthat)

.lab <- function(cols) {
  grDevices::convertColor(t(grDevices::col2rgb(cols)) / 255,
                          from = "sRGB", to = "Lab")
}

## Smallest pairwise CIE Lab distance in a palette. Pairs below roughly 10 are
## hard to tell apart, which is what the discrete palette must avoid.
.min_lab_dist <- function(cols) {
  if (length(cols) < 2) return(Inf)
  min(stats::dist(.lab(cols)))
}

test_that("discrete palette returns n distinct valid colours", {
  for (n in 1:20) {
    pal <- .colours_datrasextra_discrete(n)
    expect_length(pal, n)
    expect_identical(anyDuplicated(pal), 0L)
    expect_silent(grDevices::col2rgb(pal))
  }
})

test_that("discrete palette separates small numbers of groups", {
  ## The regression this guards against: returning the first n anchors of the
  ## sequential ramp, which put two or three groups on neighbouring colours.
  for (n in 2:6) {
    expect_gt(.min_lab_dist(.colours_datrasextra_discrete(n)), 10)
  }
})

test_that("discrete palette is ordered light to dark", {
  ## Monotone lightness is what makes the palette readable in greyscale and
  ## under any form of colour vision deficiency.
  for (n in 2:12) {
    lightness <- .lab(.colours_datrasextra_discrete(n))[, 1]
    expect_true(all(diff(lightness) < 0))
  }
  expect_identical(.colours_datrasextra_discrete(4, rev = TRUE),
                   rev(.colours_datrasextra_discrete(4)))
})

test_that("single group uses the teal default", {
  expect_identical(.colours_datrasextra_discrete(1L), "#117A8B")
})

test_that("discrete palette rejects invalid n", {
  expect_error(.colours_datrasextra_discrete(0), "positive integer")
  expect_error(.colours_datrasextra_discrete(c(2, 3)), "positive integer")
  expect_error(.colours_datrasextra_discrete(NA), "positive integer")
})

test_that("continuous palette keeps its anchors and ordering", {
  pal <- .colours_datrasextra_continuous(6)
  expect_identical(pal[1], "#F0E2C0")
  expect_identical(pal[6], "#0B3C5D")
  expect_true(all(diff(.lab(.colours_datrasextra_continuous(12))[, 1]) < 0))
  expect_identical(.colours_datrasextra_continuous(5, rev = TRUE),
                   rev(.colours_datrasextra_continuous(5)))
})
