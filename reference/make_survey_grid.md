# Make a regular prediction grid from coordinate vectors

Creates an equally spaced grid covering the range of the supplied
coordinates. Works with any coordinate system (UTM metres, UTM
kilometres, lon/lat degrees, etc.) — `resolution` and the coordinates
must simply be in the same units. The grid origin is snapped down to the
nearest `resolution` multiple below each coordinate minimum. Optionally
repeats the spatial grid for every element of `time`, adding a `year`
column. Optionally removes grid nodes that are farther than `max_dist`
from any observation (requires the RANN package).

## Usage

``` r
make_survey_grid(x, y, resolution, max_dist = NULL, time = NULL)
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

## Value

A data.frame with columns `X`, `Y`, and (if `time` is supplied) `year`.
