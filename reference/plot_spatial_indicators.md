# Plot spatial indicators

Plots the output of
[`calc_spatial_indicators()`](https://tokami.github.io/DATRASextra/reference/calc_spatial_indicators.md)
as time-series panels, one panel per indicator variable. When the input
contains multiple length groups, all groups are overlaid as coloured
lines within each panel.

## Usage

``` r
plot_spatial_indicators(
  x,
  vars = NULL,
  x_var = NULL,
  col = NULL,
  lwd = 2,
  pch = NULL,
  legend = TRUE,
  legend_pos = "topright",
  layout = TRUE,
  xlim = NULL,
  main = NULL
)
```

## Arguments

- x:

  Data frame returned by
  [`calc_spatial_indicators()`](https://tokami.github.io/DATRASextra/reference/calc_spatial_indicators.md).

- vars:

  Character vector of column names to plot. Defaults to all indicator
  columns detected in `x` (`cog_lat` and `cog_lon`).

- x_var:

  Name of the x-axis column. Defaults to `"Year"` if present, otherwise
  the first non-result column.

- col:

  Character vector of colours, one per unique `group`. Defaults to the
  DATRASextra discrete palette.

- lwd:

  Line width. Default `2`.

- pch:

  Integer vector of point symbols, one per unique `group`. If `NULL`
  (default), a built-in sequence of distinct symbols is used.

- legend:

  Logical; draw a legend for group colours. Default `TRUE`; suppressed
  automatically when there is only one group.

- legend_pos:

  Legend position string passed to
  [`graphics::legend()`](https://rdrr.io/r/graphics/legend.html).
  Default `"topright"`.

- layout:

  Logical; when `TRUE` (default) and there are multiple indicator
  panels, the function sets `par(mfrow)` automatically and restores it
  on exit. Set to `FALSE` to draw panels sequentially into the caller's
  current layout – useful when combining with other plots via
  `par(mfrow = ...)`.

- xlim:

  Optional x-axis limits.

- main:

  Optional overall title prefix. If multiple panels are drawn, the
  indicator name is appended.

## Value

Invisibly returns `x`.

## See also

[`calc_spatial_indicators()`](https://tokami.github.io/DATRASextra/reference/calc_spatial_indicators.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data(dab)
dab <- add_swept_area(dab)
dab <- add_total_numbers_by_haul(dab)
res <- calc_spatial_indicators(dab, by = "Year")
plot_spatial_indicators(res)
plot_spatial_indicators(res, vars = "cog_lat")
} # }
```
