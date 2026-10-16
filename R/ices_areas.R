## Main functions ----------------------------------------------------------------


##' Add ICES areas to hauls or grid cells
##'
##' @description
##' Adds ICES area columns (e.g. `Area_27` such as `"4.a"` or `"3.a.20"`) to
##' the `HH` table of a `datras_raw` object or to a data frame such as a
##' prediction grid. Areas are assigned from the position (`lon`, `lat`) or
##' from the ICES statistical rectangle (`StatRec`), using internal tables
##' derived from the ICES area and rectangle shapefiles, so no spatial
##' packages are needed.
##'
##' @param x A `datras_raw` object or a data frame with the columns named by
##'   `lon` and `lat`, or a `StatRec` column.
##' @param vars Character vector naming the columns to add. Any of
##'   `"Area_Full"`, `"Area_27"`, `"SubArea"`, `"Division"`, `"SubDivisio"`,
##'   `"Ecoregion"` and `"StatRec"`. Defaults to
##'   `c("Area_Full", "Area_27", "Ecoregion")`.
##' @param by `"position"` (default) assigns the area of the position, and
##'   `"statrec"` the area that covers most of the sea surface of the
##'   rectangle. See Details.
##' @param lon,lat Names of the longitude and latitude columns (decimal
##'   degrees). Default `"lon"` and `"lat"`.
##' @param verbose Logical; if `TRUE` (default), prints a message summarising
##'   how many rows were matched.
##'
##' @details
##' Most ICES statistical rectangles lie in one area. With `by = "position"`,
##' positions in the rectangles that cross an area boundary (e.g. between the
##' Skagerrak, the Kattegat and the North Sea) are assigned by point in
##' polygon, using the area boundaries within these rectangles simplified to
##' 100 m. A position on land in such a rectangle gets the nearest area. A
##' position exactly on an area boundary that is also a rectangle boundary
##' (e.g. 57 30'N between 4.a and 4.b) gets the area of the rectangle to its
##' north or east. Rows without a position fall back to the `StatRec` column,
##' if there is one.
##'
##' With `by = "statrec"`, every row gets the area that covers most of the sea
##' surface of its rectangle, taken from the `StatRec` column or, if there is
##' none, from the position (see [get_statrec()]). This matches the areas
##' used for data reported by rectangle, but assigns the hauls near an area
##' boundary to the area of the rectangle.
##'
##' `Ecoregion` is always assigned by rectangle, as in the ICES rectangle
##' shapefile. `"StatRec"` in `vars` adds the rectangle of the position, for
##' example for data without rectangles; an existing `StatRec` column is then
##' overwritten. Rectangles without sea surface and positions outside the
##' rectangles get `NA`.
##'
##' The tables were derived from `ICES_Areas_20160601_cut_dense_3857` and
##' `ICES_Statistical_Rectangles_Eco` (<https://gis.ices.dk>); see
##' [reference_tables()].
##'
##' If a requested column already exists, it is overwritten.
##'
##' @return `x` with the requested columns added (or overwritten), in `HH` for
##'   a `datras_raw` object.
##'
##' @examples
##' ## Add default columns (Area_Full, Area_27, Ecoregion)
##' dab2 <- add_ices_areas(dab)
##' head(dab2$HH[, c("StatRec", "Area_Full", "Area_27", "Ecoregion")])
##'
##' ## Add only Area_27, from the reported rectangles
##' dab3 <- add_ices_areas(dab, vars = "Area_27", by = "statrec")
##'
##' ## A data frame of positions (e.g. a prediction grid): Skagerrak, Kattegat
##' ## and northern North Sea in the same rectangle (44G0, 44F7)
##' pos <- data.frame(lon = c(10.2, 10.8, 7.2, 7.8), lat = c(57.8, 57.6, 57.7, 57.9))
##' add_ices_areas(pos, vars = c("StatRec", "Area_27"))
##'
##' @seealso [get_statrec()], [add_species_info()]
##' @export
add_ices_areas <- function(x,
                           vars = c("Area_Full", "Area_27", "Ecoregion"),
                           by = c("position", "statrec"),
                           lon = "lon",
                           lat = "lat",
                           verbose = TRUE) {

  by <- match.arg(by)
  is_datras <- inherits(x, c("datras_raw", "DATRASraw"))
  if (is_datras) {
    .check_class_datras(x)
    d <- x[["HH"]]
  } else if (is.data.frame(x)) {
    d <- x
  } else {
    stop("'x' must be a 'datras_raw' object or a data frame.")
  }

  allowed <- c("Area_Full", "Area_27", "SubArea", "Division",
               "SubDivisio", "Ecoregion", "StatRec")
  bad <- setdiff(vars, allowed)
  if (length(bad) > 0) {
    stop(
      "Unknown variable(s): ", paste(bad, collapse = ", "),
      ". Must be one of: ", paste(allowed, collapse = ", ")
    )
  }

  has_pos <- all(c(lon, lat) %in% names(d))
  has_rect <- "StatRec" %in% names(d)
  if (!has_pos && !has_rect) {
    stop("'", if (is_datras) "HH" else "x", "' needs the columns '", lon,
         "' and '", lat, "' or a 'StatRec' column.")
  }
  if (by == "position" && !has_pos) {
    stop("by = \"position\" needs the columns '", lon, "' and '", lat,
         "'; use by = \"statrec\".")
  }
  if ("StatRec" %in% vars && !has_pos) {
    stop("vars = \"StatRec\" needs the columns '", lon, "' and '", lat, "'.")
  }

  ## rectangle of each row: by position, else as reported
  rect_pos <- if (has_pos) get_statrec(d[[lon]], d[[lat]]) else NULL
  rect_rep <- if (has_rect) as.character(d[["StatRec"]]) else NULL
  rect <- if (by == "statrec" && has_rect) rect_rep else rect_pos
  ## rows without a position or rectangle: the other one
  if (has_pos && has_rect) {
    rect <- ifelse(is.na(rect), if (by == "statrec") rect_pos else rect_rep, rect)
  }

  lookup <- get("ices_area_lookup", envir = asNamespace("DATRASextra"))
  idx <- match(rect, lookup[["StatRec"]])
  area <- lookup[["Area_Full"]][idx]

  n_split <- 0L
  if (by == "position") {
    in_split <- !is.na(idx) & lookup[["Split"]][idx] &
      !is.na(rect_pos) & rect == rect_pos
    if (any(in_split)) {
      a <- .area_in_split_rect(d[[lon]][in_split], d[[lat]][in_split],
                               rect[in_split])
      area[in_split] <- ifelse(is.na(a), area[in_split], a)
      n_split <- sum(in_split)
    }
  }

  out <- .ices_area_attrs(area)
  out$Ecoregion <- lookup[["Ecoregion"]][idx]
  out$StatRec <- rect_pos
  d[vars] <- out[vars]
  rownames(d) <- NULL

  if (verbose) {
    n_matched <- sum(!is.na(area))
    n_total <- nrow(d)
    message(
      "Matched ", n_matched, " of ", n_total,
      if (is_datras) " hauls" else " rows", " to ICES areas",
      if (n_split > 0)
        paste0(" (", n_split, " in rectangles split between areas)")
      else "",
      if (n_matched < n_total)
        paste0("; ", n_total - n_matched, " unmatched -> NA.")
      else
        "."
    )
  }

  if (is_datras) {
    x[["HH"]] <- d
    return(x)
  }
  d
}


##' ICES statistical rectangles
##'
##' @description
##' `get_statrec()` returns the ICES statistical rectangle (e.g. `"37F3"`) of
##' positions, and `get_statrec_coords()` the coordinates of rectangles.
##'
##' @param lon,lat Numeric vectors of longitude and latitude in decimal
##'   degrees, of the same length.
##' @param statrec Character vector of rectangle codes.
##' @param where `"midpoint"` (default) or `"corner"` (south-west corner).
##'
##' @details
##' Rectangles are 30' of latitude by 1 degree of longitude. Rows are numbered
##' `01` to `99` from 36 degrees N to 85 degrees 30' N. Columns are a letter
##' for each 10 degrees of longitude and a digit for each degree, from `A0`
##' at 44 degrees W to `M8` at 68 degrees E. `A` only has `A0` to `A3`
##' (44 to 40 degrees W), and the letter `I` is not used. A position on the
##' boundary between rectangles belongs to the rectangle to its north and
##' east. See
##' <https://www.ices.dk/data/maps/Pages/ICES-statistical-rectangles.aspx>.
##'
##' @return `get_statrec()`: a character vector of rectangle codes, `NA` for
##'   missing positions and positions outside the rectangles.
##'   `get_statrec_coords()`: a data frame with the columns `lon` and `lat`,
##'   `NA` for invalid codes.
##'
##' @examples
##' get_statrec(lon = c(3.2, -0.5, 10.55), lat = c(54.1, 58.2, 58.2))
##' get_statrec_coords(c("37F3", "45E9"))
##'
##' @seealso [add_ices_areas()]
##' @export
get_statrec <- function(lon, lat) {

  if (length(lon) != length(lat)) {
    stop("'lon' and 'lat' must have the same length.")
  }
  lon <- suppressWarnings(as.numeric(lon))
  lat <- suppressWarnings(as.numeric(lat))

  row <- floor((lat - 36) * 2) + 1
  ## columns from 44 W: A0-A3, then 10 per letter from 40 W (B0) to 68 E (M8)
  col <- floor(lon) + 44
  ok <- !is.na(row) & !is.na(col) & row >= 1 & row <= 99 & col >= 0 & col <= 112

  out <- rep(NA_character_, length(lon))
  row <- row[ok]
  col <- col[ok]
  letter <- ifelse(col < 4, 1, (col - 4) %/% 10 + 2)
  digit <- ifelse(col < 4, col, (col - 4) %% 10)
  out[ok] <- paste0(sprintf("%02d", row), .statrec_letters[letter], digit)
  out
}


##' @rdname get_statrec
##' @export
get_statrec_coords <- function(statrec, where = c("midpoint", "corner")) {

  where <- match.arg(where)
  statrec <- trimws(as.character(statrec))
  ok <- !is.na(statrec) & grepl("^[0-9]{2}[A-HJ-M][0-9]$", statrec)

  row <- as.integer(substr(statrec, 1, 2))
  letter <- match(substr(statrec, 3, 3), .statrec_letters)
  digit <- as.integer(substr(statrec, 4, 4))
  ok <- ok & row >= 1 & row <= 99 &
    !(letter == 1 & digit > 3) & !(letter == 12 & digit > 8)

  lon <- ifelse(letter == 1, -44 + digit, -40 + (letter - 2) * 10 + digit)
  lat <- 36 + (row - 1) / 2
  lon[!ok] <- NA_real_
  lat[!ok] <- NA_real_
  if (where == "midpoint") {
    lon <- lon + 0.5
    lat <- lat + 0.25
  }
  data.frame(lon = lon, lat = lat)
}


## Internal helpers --------------------------------------------------------------


## Column letters of the rectangles: A (44-40 W, only A0-A3), then one letter
## per 10 degrees from 40 W; the letter I is not used
.statrec_letters <- c("A", LETTERS[2:8], LETTERS[10:13])


## Area attributes from Area_Full, e.g. 27.3.d.28.1: Major_FA 27, SubArea 3,
## Division d, SubDivisio 28 (the unit, 1, is only part of Area_Full)
.ices_area_attrs <- function(area_full) {
  area_full <- as.character(area_full)
  parts <- strsplit(area_full, ".", fixed = TRUE)
  part <- function(i) {
    vapply(parts, function(p) if (length(p) >= i) p[i] else NA_character_,
           character(1))
  }
  data.frame(Major_FA = part(1), SubArea = part(2), Division = part(3),
             SubDivisio = part(4), Area_Full = area_full,
             Area_27 = sub("^27\\.", "", area_full),
             stringsAsFactors = FALSE)
}


## Area of positions in rectangles that cross an area boundary: point in
## polygon with the pieces in ices_area_split, or the nearest piece for
## positions outside all pieces (on land, or in a gap of the simplification)
.area_in_split_rect <- function(lon, lat, rect) {

  split <- get("ices_area_split", envir = asNamespace("DATRASextra"))
  area <- rep(NA_character_, length(lon))

  for (r in unique(rect)) {
    i <- which(rect == r)
    v <- split[split$StatRec == r, ]
    pieces <- unique(v$Area_Full)
    if (length(pieces) == 0) next
    hit <- vapply(pieces, function(a) {
      s <- v$Area_Full == a
      .in_rings(lon[i], lat[i], v$lon[s], v$lat[s], v$ring[s])
    }, logical(length(i)))
    hit <- matrix(hit, nrow = length(i))
    first <- max.col(hit, ties.method = "first")
    inside <- rowSums(hit) > 0
    area[i[inside]] <- pieces[first[inside]]

    for (j in i[!inside]) {
      dist <- vapply(pieces, function(a) {
        s <- v$Area_Full == a
        .dist_to_rings(lon[j], lat[j], v$lon[s], v$lat[s], v$ring[s])
      }, numeric(1))
      area[j] <- pieces[which.min(dist)]
    }
  }
  area
}


## Points in polygon by the even-odd rule over all rings, so that holes
## (islands) are outside; loops over the edges, vectorised over the points
.in_rings <- function(px, py, vx, vy, ring) {
  inside <- logical(length(px))
  for (r in unique(ring)) {
    s <- ring == r
    x <- vx[s]
    y <- vy[s]
    n <- length(x)
    prev <- c(n, seq_len(n - 1))
    for (k in seq_len(n)) {
      x1 <- x[prev[k]]
      y1 <- y[prev[k]]
      if (y[k] == y1) next
      cross <- (y[k] > py) != (y1 > py) &
        px < (x1 - x[k]) * (py - y[k]) / (y1 - y[k]) + x[k]
      inside <- xor(inside, cross)
    }
  }
  inside
}


## Distance of one point to the edges of rings (degrees of latitude, with
## longitude scaled by the cosine of the latitude)
.dist_to_rings <- function(px, py, vx, vy, ring) {
  sc <- cos(py * pi / 180)
  d <- Inf
  for (r in unique(ring)) {
    s <- ring == r
    x <- vx[s] * sc
    y <- vy[s]
    n <- length(x)
    prev <- c(n, seq_len(n - 1))
    dx <- x - x[prev]
    dy <- y - y[prev]
    len2 <- dx^2 + dy^2
    t <- ifelse(len2 > 0,
                ((px * sc - x[prev]) * dx + (py - y[prev]) * dy) / len2, 0)
    t <- pmin(pmax(t, 0), 1)
    d <- min(d, sqrt((x[prev] + t * dx - px * sc)^2 + (y[prev] + t * dy - py)^2))
  }
  d
}
