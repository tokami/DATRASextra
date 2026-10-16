## require(DATRASextra); require(testthat)


## get_statrec -----------------------------------------------------------------

test_that("get_statrec follows the ICES definition", {

  ## examples of the ICES page: 54 N 3 E is 37F3, 58 12'N 10 33'E is in 45G0
  expect_equal(get_statrec(3.2, 54.1), "37F3")
  expect_equal(get_statrec(10 + 33 / 60, 58 + 12 / 60), "45G0")

  ## columns: A0-A3 from 44 W, B0 at 40 W, E9/F0 at 0, no I, M8 the last
  lon <- c(-44, -40.5, -40, -10.5, -0.5, 0, 29.5, 30, 68.5)
  expect_equal(get_statrec(lon, rep(36, length(lon))),
               c("01A0", "01A3", "01B0", "01D9", "01E9", "01F0", "01H9",
                 "01J0", "01M8"))

  ## rows: 01 from 36 N, 99 up to 85 30'N; boundaries belong north and east
  expect_equal(get_statrec(c(0, 0, 0), c(36, 57.5, 85.49)),
               c("01F0", "44F0", "99F0"))

  ## outside the rectangles and missing positions
  expect_equal(get_statrec(c(-44.1, 69, 0, 0, NA, 0), c(50, 50, 35.9, 85.5, 50, NA)),
               rep(NA_character_, 6))
  expect_error(get_statrec(1:2, 1), "same length")
})


test_that("get_statrec and get_statrec_coords are inverse", {

  codes <- unlist(lapply(sprintf("%02d", 1:99), paste0,
                         c(paste0("A", 0:3),
                           paste0(rep(c("B", "C", "D", "E", "F", "G", "H", "J",
                                        "K", "L"), each = 10), 0:9),
                           paste0("M", 0:8))))
  expect_length(codes, 99 * 113)

  mid <- get_statrec_coords(codes)
  expect_false(anyNA(mid))
  expect_equal(get_statrec(mid$lon, mid$lat), codes)

  corner <- get_statrec_coords(codes, where = "corner")
  expect_equal(corner$lon, mid$lon - 0.5)
  expect_equal(corner$lat, mid$lat - 0.25)
  expect_equal(get_statrec(corner$lon, corner$lat), codes)
})


test_that("get_statrec_coords returns NA for invalid codes", {

  bad <- c("47A4", "01I0", "00F0", "99M9", "-9", "", "37F", NA)
  expect_true(all(is.na(get_statrec_coords(bad)$lon)))
  expect_true(all(is.na(get_statrec_coords(bad)$lat)))
  expect_equal(get_statrec_coords(" 37F3 "), data.frame(lon = 3.5, lat = 54.25))
})


test_that("get_statrec_coords agrees with DATRAS::icesSquare2coord", {
  skip_if_not_installed("DATRAS")

  codes <- unique(dab$HH$StatRec)
  ours <- get_statrec_coords(codes, where = "corner")
  theirs <- DATRAS::icesSquare2coord(codes, "corner")
  expect_equal(ours$lon, unname(theirs$lon))
  expect_equal(ours$lat, unname(theirs$lat))
})


test_that("get_statrec matches the reported rectangles of the hauls", {

  rect <- get_statrec(dab$HH$lon, dab$HH$lat)
  expect_gt(mean(rect == dab$HH$StatRec, na.rm = TRUE), 0.99)
})


## add_ices_areas ----------------------------------------------------------------

test_that("add_ices_areas assigns positions in split rectangles", {

  ## 44G0: Skagerrak and Kattegat; 44F7: northern North Sea and Skagerrak;
  ## 40G2 on land (Copenhagen): nearest area; 33H0: no sea; -50: outside
  pos <- data.frame(lon = c(10.2, 10.8, 7.2, 7.8, 12.6, 2, 20, -50),
                    lat = c(57.8, 57.6, 57.7, 57.9, 55.7, 56, 52, 60))
  out <- add_ices_areas(pos, vars = c("StatRec", "Area_27", "Area_Full"),
                        verbose = FALSE)

  expect_s3_class(out, "data.frame")
  expect_equal(out$StatRec, c("44G0", "44G0", "44F7", "44F7", "40G2", "41F2",
                              "33H0", NA))
  expect_equal(out$Area_27, c("3.a.20", "3.a.21", "4.a", "3.a.20", "3.b.23",
                              "4.b", NA, NA))
  expect_equal(out$Area_Full, ifelse(is.na(out$Area_27), NA,
                                     paste0("27.", out$Area_27)))

  ## by rectangle: the area with most of the sea of the rectangle
  rect <- add_ices_areas(pos, vars = "Area_27", by = "statrec", verbose = FALSE)
  expect_equal(rect$Area_27[1:4], rep("3.a.20", 4))
})


test_that("add_ices_areas derives the area attributes from Area_Full", {

  ## Gulf of Riga (with a unit) and central North Sea (no subdivision)
  pos <- data.frame(lon = c(23.5, 2), lat = c(57.7, 56))
  out <- add_ices_areas(pos, vars = c("SubArea", "Division", "SubDivisio",
                                      "Area_Full"), verbose = FALSE)
  expect_equal(out$Area_Full, c("27.3.d.28.1", "27.4.b"))
  expect_equal(out$SubArea, c("3", "4"))
  expect_equal(out$Division, c("d", "b"))
  expect_equal(out$SubDivisio, c("28", NA))
})


test_that("the lookup takes the area with most of the sea of a rectangle", {

  lk <- DATRASextra:::ices_area_lookup
  get_area <- function(r) lk$Area_27[match(r, lk$StatRec)]
  ## centre on land (45F7 Skagerrak, 41G0 Kattegat side), mostly 3.a.21 (41G2),
  ## and a rectangle missing from the ICES rectangle shapefile (Limfjord)
  expect_equal(get_area(c("45F7", "41G2", "42F9", "37F3")),
               c("3.a.20", "3.a.21", "4.b", "4.b"))
  expect_false(anyNA(get_area(unique(dab$HH$StatRec))))
})


test_that("add_ices_areas works on datras_raw objects", {

  d1 <- add_ices_areas(dab, verbose = FALSE)
  expect_s3_class(d1, "datras_raw")
  expect_true(all(c("Area_Full", "Area_27", "Ecoregion") %in% names(d1$HH)))
  expect_false(anyNA(d1$HH$Area_27))
  expect_equal(nrow(d1$HH), nrow(dab$HH))

  ## by rectangle differs only near area boundaries
  d2 <- add_ices_areas(dab, by = "statrec", verbose = FALSE)
  expect_gt(mean(d1$HH$Area_27 == d2$HH$Area_27), 0.95)

  expect_message(add_ices_areas(dab, vars = "Area_27"), "Matched")
})


test_that("add_ices_areas works without StatRec or without positions", {

  ## without StatRec (e.g. surveys from other sources)
  x <- dab
  x$HH$StatRec <- NULL
  x <- add_ices_areas(x, vars = c("StatRec", "Area_27"), verbose = FALSE)
  ref <- add_ices_areas(dab, vars = "Area_27", verbose = FALSE)
  expect_equal(x$HH$StatRec, get_statrec(dab$HH$lon, dab$HH$lat))
  expect_equal(x$HH$Area_27, ref$HH$Area_27)

  ## without positions: by rectangle only
  hh <- data.frame(StatRec = c("37F3", "44G0", "XX"))
  expect_error(add_ices_areas(hh), "by = \"statrec\"")
  out <- add_ices_areas(hh, vars = "Area_27", by = "statrec", verbose = FALSE)
  expect_equal(out$Area_27, c("4.b", "3.a.20", NA))

  ## missing positions fall back to the reported rectangle
  hh <- data.frame(lon = c(NA, 2), lat = c(NA, 56), StatRec = c("37F3", "41F2"))
  out <- add_ices_areas(hh, vars = "Area_27", verbose = FALSE)
  expect_equal(out$Area_27, c("4.b", "4.b"))

  expect_error(add_ices_areas(data.frame(a = 1)), "needs the columns")
  expect_error(add_ices_areas(dab, vars = "Unit"), "Unknown variable")
  expect_error(add_ices_areas(1:3), "data frame")
})


test_that("the spatial basis 'statrec' uses rectangle midpoints", {

  hh <- data.frame(StatRec = c("37F3", "45E9", "-9", "47A4"), Year = 1:4)
  expect_warning(DATRASextra:::.prepare_spatial_basis(hh, "statrec"),
                 "Dropped 1 invalid")
  out <- suppressWarnings(DATRASextra:::.prepare_spatial_basis(hh, "statrec"))
  expect_equal(out$lon[order(out$StatRec)], c(3.5, -0.5))
  expect_equal(out$lat[order(out$StatRec)], c(54.25, 58.25))
})
