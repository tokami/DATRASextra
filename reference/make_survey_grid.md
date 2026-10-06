# Make a regular prediction grid from coordinate vectors

Creates an equally spaced grid covering the range of the supplied
coordinates. Works with any coordinate system (UTM metres, UTM
kilometres, lon/lat degrees, etc.) - `resolution` and the coordinates
must simply be in the same units. The grid origin is snapped down to the
nearest `resolution` multiple below each coordinate minimum. Optionally
repeats the spatial grid for every element of `time`, adding a `year`
column. Optionally removes grid nodes that are farther than `max_dist`
from any observation (requires the RANN package), and fills gaps in the
remaining footprint with `fill_gaps`.

## Usage

``` r
make_survey_grid(
  x,
  y,
  resolution,
  max_dist = NULL,
  time = NULL,
  fill_gaps = NULL
)
```

## Arguments

- x:

  Numeric vector of X coordinates (any units).

- y:

  Numeric vector of Y coordinates (same units as `x`).

- resolution:

  Step size between grid nodes, in the same units as `x` and `y`.

- max_dist:

  Optional distance threshold in the same units as `x` and `y`. Grid
  nodes whose nearest observation is farther than `max_dist` are
  dropped. Uses a k-d tree via RANN for efficiency.

- time:

  Optional vector of time values (e.g. `1990:2000`). When supplied the
  spatial grid is crossed with `time` and a `year` column is added.

- fill_gaps:

  Optional distance in the same units as `x` and `y`, used together with
  `max_dist`. Holes and bays in the footprint that are narrower than
  about `2 * fill_gaps` are filled, without extending the outer edge of
  the footprint. See Details.

## Value

A data.frame with columns `X`, `Y`, and (if `time` is supplied) `year`.

## Details

With `max_dist` alone, the grid keeps the nodes within `max_dist` of an
observation. Where hauls are farther than `2 * max_dist` apart, this
leaves holes inside the survey area and notches along its edge, although
the survey covers the area between them. `fill_gaps` closes these: the
footprint is first grown by `max_dist + fill_gaps` around each
observation and then shrunk by `fill_gaps` again (a morphological
closing). Gaps narrower than about `2 * fill_gaps` disappear, while the
outer edge stays at `max_dist` from the outermost observations. Nodes
kept by `max_dist` are always kept.

The closing is computed on the grid nodes, so it is accurate to about
one `resolution`. Distances are measured in the units of the
coordinates; in lon/lat degrees a degree of longitude is shorter than a
degree of latitude, so project the coordinates first (e.g. with
[`add_xy()`](https://tokami.github.io/DATRASextra/reference/add_xy.md))
when distances should be equal in all directions.

## See also

[`add_grid_support()`](https://tokami.github.io/DATRASextra/reference/add_grid_support.md)
to flag the grid nodes covered by the hauls of each year,
[`add_bathymetry()`](https://tokami.github.io/DATRASextra/reference/add_bathymetry.md)
to add depth.

## Examples

``` r
trawls <- unique(dab[["HH"]][, c("lon", "lat")])
if (requireNamespace("RANN", quietly = TRUE)) {
  grid <- make_survey_grid(trawls$lon, trawls$lat, resolution = 0.1,
                           max_dist = 0.2)
  grid_filled <- make_survey_grid(trawls$lon, trawls$lat, resolution = 0.1,
                                  max_dist = 0.2, fill_gaps = 0.3)
  c(nrow(grid), nrow(grid_filled))
}
#> [1] 6856 7970
```
