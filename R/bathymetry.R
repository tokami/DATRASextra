## Main functions ----------------------------------------------------------------


##' Add depth from NOAA bathymetry
##'
##' Adds the sea depth at each position of a data frame, for example the
##' nodes of a prediction grid from [make_survey_grid()], taken from the ETOPO
##' bathymetry of NOAA via the \pkg{marmap} package.  Optionally flags the
##' positions whose depth lies within a given range, such as the depths at
##' which the survey fishes.
##'
##' @param d A data frame with longitude and latitude columns (decimal
##'   degrees), or a `datras_raw` object, in which case depth is added to
##'   `HH`.
##' @param lon,lat Names of the longitude and latitude columns.
##' @param bathy Optional bathymetry of class `bathy` (from
##'   `marmap::getNOAA.bathy()` or `marmap::as.bathy()`). If `NULL` (default),
##'   it is downloaded for the range of the positions plus one degree.
##' @param resolution Resolution of the downloaded bathymetry in arc minutes,
##'   passed to `marmap::getNOAA.bathy()`. Default 1.
##' @param path Optional directory in which the downloaded bathymetry is kept
##'   and looked up again on later calls, so that it is downloaded only once.
##' @param depth_range Optional numeric vector of length 2. When given, a
##'   logical column `depth_ok` is added that is `TRUE` where the depth lies
##'   within the range.
##' @param col Name of the depth column to add. Default `"Depth"`, as in `HH`.
##'
##' @details
##' Depths are positive below sea level, in metres.  Positions on land and
##' positions outside the bathymetry get `NA`.  The depth is that of the
##' bathymetry cell nearest to each position.
##'
##' For a grid in projected coordinates, add longitude and latitude first with
##' `add_xy(grid, inverse = TRUE)`.
##'
##' A typical `depth_range` is the range of depths the survey fishes, e.g.
##' `quantile(x[["HH"]]$Depth, c(0.01, 0.99), na.rm = TRUE)`; predictions
##' outside it extrapolate in depth.
##'
##' When `d` is a `datras_raw` object and `col = "Depth"`, the haul depths
##' reported by the survey are replaced. Use another `col` to compare them.
##'
##' @return `d` with the depth column, and `depth_ok` when `depth_range` is
##'   given, added.
##'
##' @seealso [make_survey_grid()], [add_grid_support()], [add_xy()]
##'
##' @examples
##' \dontrun{
##' grid <- make_survey_grid(dab[["HH"]]$lon, dab[["HH"]]$lat,
##'                          resolution = 0.1, max_dist = 0.3)
##' names(grid) <- c("lon", "lat")
##' grid <- add_bathymetry(grid, path = tempdir(),
##'                        depth_range = quantile(dab[["HH"]]$Depth,
##'                                               c(0.01, 0.99), na.rm = TRUE))
##'
##' ## Compare the reported haul depths with the bathymetry
##' x <- add_bathymetry(dab, col = "DepthNOAA", path = tempdir())
##' }
##'
##' @export
add_bathymetry <- function(d,
                           lon = "lon",
                           lat = "lat",
                           bathy = NULL,
                           resolution = 1,
                           path = NULL,
                           depth_range = NULL,
                           col = "Depth") {

  if (!requireNamespace("marmap", quietly = TRUE)) {
    stop("Package 'marmap' is required for add_bathymetry(). ",
         "Install with install.packages('marmap').")
  }
  if (!is.null(depth_range) && (!is.numeric(depth_range) || length(depth_range) != 2)) {
    stop("depth_range must be a numeric vector of length 2.")
  }

  if (inherits(d, "datras_raw") || inherits(d, "DATRASraw")) {
    d[["HH"]] <- add_bathymetry(d[["HH"]], lon = lon, lat = lat, bathy = bathy,
                                resolution = resolution, path = path,
                                depth_range = depth_range, col = col)
    return(d)
  }

  if (!all(c(lon, lat) %in% names(d))) {
    stop("d must have the columns '", lon, "' and '", lat, "'.")
  }
  px <- as.numeric(d[[lon]])
  py <- as.numeric(d[[lat]])
  ok <- is.finite(px) & is.finite(py)
  if (!any(ok)) stop("No finite positions in d.")

  if (is.null(bathy)) {
    bathy <- marmap::getNOAA.bathy(
      lon1 = max(-180, min(px[ok]) - 1), lon2 = min(180, max(px[ok]) + 1),
      lat1 = max(-90, min(py[ok]) - 1), lat2 = min(90, max(py[ok]) + 1),
      resolution = resolution, keep = !is.null(path), path = path)
  }
  if (!inherits(bathy, "bathy")) stop("bathy must be an object of class 'bathy'.")

  ## get.depth() fails for positions outside the bathymetry, so only the
  ## positions inside are looked up
  bx <- range(as.numeric(rownames(bathy)))
  by <- range(as.numeric(colnames(bathy)))
  inside <- ok & px >= bx[1] & px <= bx[2] & py >= by[1] & py <= by[2]

  depth <- rep(NA_real_, nrow(d))
  if (any(inside)) {
    z <- marmap::get.depth(bathy, x = data.frame(lon = px[inside], lat = py[inside]),
                           locator = FALSE)$depth
    depth[inside] <- -z
  }
  depth[!is.na(depth) & depth <= 0] <- NA_real_

  d[[col]] <- depth
  if (!is.null(depth_range)) {
    r <- sort(depth_range)
    d$depth_ok <- !is.na(depth) & depth >= r[1] & depth <= r[2]
  }
  d
}
