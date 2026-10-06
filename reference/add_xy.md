# Add projected coordinates

Adds projected coordinates `X` and `Y` to a data frame with longitude
and latitude, or the reverse: longitude and latitude to a data frame
with projected `X` and `Y`, e.g. a prediction grid built in kilometres
with
[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md).
Spatial models and distance-based grid operations need projected
coordinates, in which a distance is the same in all directions.

## Usage

``` r
add_xy(
  d,
  crs = 3035,
  units = c("km", "m"),
  lon = "lon",
  lat = "lat",
  xy = c("X", "Y"),
  inverse = FALSE
)
```

## Arguments

- d:

  A data frame, or a `datras_raw` object, in which case the coordinates
  are added to `HH`.

- crs:

  Coordinate reference system of `X` and `Y`, as accepted by
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html).
  Default 3035, the ETRS89 Lambert azimuthal equal-area projection for
  Europe.

- units:

  Units of `X` and `Y`: `"km"` (default) or `"m"`.

- lon, lat:

  Names of the longitude and latitude columns (decimal degrees, WGS84).

- xy:

  Names of the projected coordinate columns. Default `c("X", "Y")`, as
  in the output of
  [`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md).

- inverse:

  Logical. If `FALSE` (default), `X` and `Y` are computed from longitude
  and latitude. If `TRUE`, longitude and latitude are computed from `X`
  and `Y`.

## Value

`d` with the coordinate columns added.

## Details

Rows with missing coordinates get `NA`. Existing columns of the same
names are overwritten.

## See also

[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md),
[`add_bathymetry()`](https://tokami.github.io/DATRASextra/reference/add_bathymetry.md)

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  x <- add_xy(dab)
  head(x[["HH"]][, c("lon", "lat", "X", "Y")])

  ## A 10 km grid, with longitude and latitude for each node
  grid <- make_survey_grid(x[["HH"]]$X, x[["HH"]]$Y, resolution = 10)
  grid <- add_xy(grid, inverse = TRUE)
  head(grid)
}
#>      X    Y        lon      lat
#> 1 3510 2980 -1.2151146 49.37472
#> 2 3520 2980 -1.0787174 49.38832
#> 3 3530 2980 -0.9422514 49.40175
#> 4 3540 2980 -0.8057172 49.41501
#> 5 3550 2980 -0.6691157 49.42811
#> 6 3560 2980 -0.5324476 49.44104
```
