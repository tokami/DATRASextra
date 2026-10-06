# Flag grid nodes covered by the hauls of each year

Adds two columns to a prediction grid from
[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md)
that show where the survey actually sampled: `supported`, whether the
hauls of a year (and its neighbouring years) cover a node, and
`coverage`, the share of years in which a node is covered. Predictions
in nodes without support are extrapolations.

## Usage

``` r
add_grid_support(
  grid,
  x,
  y,
  time,
  max_dist,
  fill_gaps = NULL,
  window = 1,
  resolution = NULL
)
```

## Arguments

- grid:

  A data frame with columns `X` and `Y` on a regular grid, and
  optionally `year`, e.g. from
  [`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md).

- x, y:

  Numeric vectors of haul coordinates, in the units of the grid.

- time:

  Vector of haul years, the same length as `x`.

- max_dist, fill_gaps:

  Distances as in
  [`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md).

- window:

  Non-negative number. A node is `supported` in a year when hauls from
  years at most `window` away cover it. Default 1: the year itself and
  the years before and after.

- resolution:

  Grid spacing. If `NULL` (default), taken from the spacing of `grid`.

## Value

`grid` with the columns `supported` (logical; only when `grid` has a
`year` column, otherwise coverage by all hauls) and `coverage` (numeric
between 0 and 1) added.

## Details

A node is covered by a set of hauls when it lies within `max_dist` of
one of them, after filling gaps with `fill_gaps`, exactly as in
[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md).

`coverage` is computed per node from the hauls of each year alone,
without `window`. The years counted are those in `grid$year` when the
grid has a `year` column, so that years without hauls count as not
covered, and those in `time` otherwise. A threshold such as
`coverage >= 0.25` keeps the nodes the survey covers regularly.

Surveys sampled in several quarters usually cover different areas in
each. Run the function per quarter, with the hauls of that quarter (see
the examples).

## See also

[`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md)

## Examples

``` r
if (requireNamespace("RANN", quietly = TRUE)) {
  hh <- dab[["HH"]]
  hh <- hh[!is.na(hh$lon) & !is.na(hh$lat), ]
  years <- as.numeric(as.character(hh$Year))
  grid <- make_survey_grid(hh$lon, hh$lat, resolution = 0.2,
                           max_dist = 0.3, time = sort(unique(years)))

  ## One quarter
  q1 <- hh$Quarter == "1"
  g1 <- add_grid_support(grid, hh$lon[q1], hh$lat[q1], years[q1],
                         max_dist = 0.3)
  table(g1$supported, g1$year)

  ## Nodes covered in at least a quarter of the years
  core <- g1[g1$coverage >= 0.25, ]
}
```
