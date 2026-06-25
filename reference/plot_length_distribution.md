# Plot catch distribution by length class

Aggregates numbers-at-length (`N`) and/or weight-at-length (`Wgt`)
across hauls and plots the resulting length distribution as a bar chart.
The function is intended to help identify meaningful length groups.
Optional cut points can be overlaid as dashed vertical lines, and bars
are coloured according to the resulting length intervals.

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
  legend = TRUE,
  legend_ncol = 1
)
```

## Arguments

- x:

  A `datras_raw` object with `N` and/or `Wgt` matrices in `HH`.

- what:

  Character; which quantity to plot. One of `"N"`, `"Wgt"`, `"both"`, or
  `"legend"`. The latter draws only the length-group legend.

- agg:

  Character; how to aggregate across hauls. Either `"sum"` or `"mean"`.

- log_scale:

  Logical; if `TRUE`, plot log-transformed aggregated values. Zero
  values are shown as missing.

- length_cuts:

  Optional numeric vector of break points in cm. If supplied, dashed
  vertical lines are drawn at these cut points and bars are coloured by
  length interval.

- col:

  Optional colour vector. If `length_cuts` is supplied, colours are
  recycled to match the number of resulting intervals, i.e.
  `length(length_cuts) + 1`. If `length_cuts` is not supplied, the first
  colour is used for all bars.

- main:

  Optional plot title.

- legend:

  Logical; if `TRUE`, draw a legend for the length intervals when
  `length_cuts` is supplied.

- legend_ncol:

  Integer; number of columns to use in the legend.

## Value

Invisibly returns a `data.frame` with column `midL` and one or both of
`N` and `Wgt`, depending on `what`. If `what = "legend"`, nothing useful
is returned.

## Details

The `N` and/or `Wgt` matrices must be present in `x[["HH"]]`, depending
on the selected value of `what`. Use
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)
and/or
[`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)
to add these matrices before plotting.

If `what = "both"` but only one of `N` or `Wgt` is available, the
function falls back to plotting the available quantity and issues a
message.

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

## Plot without legend
plot_length_distribution(x, length_cuts = c(15, 25), legend = FALSE)

## Draw only the length-group legend
plot_length_distribution(x, what = "legend",
                         length_cuts = c(15, 25),
                         legend_ncol = 3)
} # }
```
