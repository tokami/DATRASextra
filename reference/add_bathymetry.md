# Add depth from NOAA bathymetry

Adds the sea depth at each position of a data frame, for example the
nodes of a prediction grid from
[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md),
taken from the ETOPO bathymetry of NOAA via the marmap package.
Optionally flags the positions whose depth lies within a given range,
such as the depths at which the survey fishes.

## Usage

``` r
add_bathymetry(
  d,
  lon = "lon",
  lat = "lat",
  bathy = NULL,
  resolution = 1,
  path = NULL,
  depth_range = NULL,
  col = "Depth"
)
```

## Arguments

- d:

  A data frame with longitude and latitude columns (decimal degrees), or
  a `datras_raw` object, in which case depth is added to `HH`.

- lon, lat:

  Names of the longitude and latitude columns.

- bathy:

  Optional bathymetry of class `bathy` (from
  [`marmap::getNOAA.bathy()`](https://rdrr.io/pkg/marmap/man/getNOAA.bathy.html)
  or
  [`marmap::as.bathy()`](https://rdrr.io/pkg/marmap/man/as.bathy.html)).
  If `NULL` (default), it is downloaded for the range of the positions
  plus one degree.

- resolution:

  Resolution of the downloaded bathymetry in arc minutes, passed to
  [`marmap::getNOAA.bathy()`](https://rdrr.io/pkg/marmap/man/getNOAA.bathy.html).
  Default 1.

- path:

  Optional directory in which the downloaded bathymetry is kept and
  looked up again on later calls, so that it is downloaded only once.

- depth_range:

  Optional numeric vector of length 2. When given, a logical column
  `depth_ok` is added that is `TRUE` where the depth lies within the
  range.

- col:

  Name of the depth column to add. Default `"Depth"`, as in `HH`.

## Value

`d` with the depth column, and `depth_ok` when `depth_range` is given,
added.

## Details

Depths are positive below sea level, in metres. Positions on land and
positions outside the bathymetry get `NA`. The depth is that of the
bathymetry cell nearest to each position.

For a grid in projected coordinates, add longitude and latitude first
with `add_xy(grid, inverse = TRUE)`.

A typical `depth_range` is the range of depths the survey fishes, e.g.
`quantile(x[["HH"]]$Depth, c(0.01, 0.99), na.rm = TRUE)`; predictions
outside it extrapolate in depth.

When `d` is a `datras_raw` object and `col = "Depth"`, the haul depths
reported by the survey are replaced. Use another `col` to compare them.

## See also

[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md),
[`add_grid_support()`](https://tokami.github.io/DATRASextra/reference/add_grid_support.md),
[`add_xy()`](https://tokami.github.io/DATRASextra/reference/add_xy.md)

## Examples

``` r
if (FALSE) { # \dontrun{
grid <- make_survey_grid(dab[["HH"]]$lon, dab[["HH"]]$lat,
                         resolution = 0.1, max_dist = 0.3)
names(grid) <- c("lon", "lat")
grid <- add_bathymetry(grid, path = tempdir(),
                       depth_range = quantile(dab[["HH"]]$Depth,
                                              c(0.01, 0.99), na.rm = TRUE))

## Compare the reported haul depths with the bathymetry
x <- add_bathymetry(dab, col = "DepthNOAA", path = tempdir())
} # }
```
