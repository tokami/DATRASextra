# Plot catch distribution by length class

Aggregates numbers-at-length (`N`) and/or weight-at-length (`Wgt`)
across hauls and plots the distribution as a bar chart, to help identify
meaningful length groups. Optional cut points are overlaid as dashed
vertical lines, with bars coloured by the resulting intervals.

Both matrices must be present in `x[["HH"]]` before calling this
function. Use
[`add_numbers_at_length`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)
and/or
[`add_weight_at_length`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)
to add them.

## Usage

``` r
plot_length_distribution(
  x,
  what = c("N", "Wgt", "both", "legend"),
  agg = c("sum", "mean"),
  log_scale = FALSE,
  length_cuts = NULL,
  col = NULL,
  main = NULL,
  do_legend = TRUE,
  legend_ncol = 1L
)
```

## Arguments

- x:

  A `datras_raw` object with `N` and/or `Wgt` matrices in `HH`.

- what:

  Character; which quantity to plot: `"N"`, `"Wgt"`, or `"both"`.

- agg:

  Character; how to aggregate across hauls: `"sum"` (default) or
  `"mean"`.

- log_scale:

  Logical; if `TRUE`, plot on a log scale.

- length_cuts:

  Optional numeric vector of break points in cm to overlay as dashed
  vertical lines. Bars are coloured by which interval each length class
  falls in.

- col:

  Optional colour vector. If `length_cuts` is supplied, one colour per
  interval (length of `length_cuts` + 1). Otherwise a single bar colour.

- main:

  Optional plot title.

## Value

Invisibly returns the aggregated values: a `data.frame` with columns
`midL`, `N` and/or `Wgt` (depending on `what`).

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_numbers_at_length(dab)
x <- add_weight_at_length(x)

## Basic numbers distribution
plot_length_distribution(x)

## Both panels, log scale
plot_length_distribution(x, what = "both", log_scale = TRUE)

## Overlay proposed length groups
plot_length_distribution(x, length_cuts = c(15, 25))
} # }
```
