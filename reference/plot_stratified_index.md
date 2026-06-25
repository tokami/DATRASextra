# Plot a stratified abundance or biomass index

Plots the output of
[`calc_stratified_index()`](https://tokami.github.io/DATRASextra/reference/calc_stratified_index.md)
as a time-series. When the index contains multiple length groups (from a
matrix `HaulN`), all groups are drawn in the same panel as separate
coloured lines with a legend. An optional `panel_var` can split the plot
into panels (e.g. by survey).

## Usage

``` r
plot_stratified_index(
  x,
  x_var = NULL,
  panel_var = NULL,
  ci = TRUE,
  ci_alpha = 0.2,
  log_scale = FALSE,
  fixed_ylim = TRUE,
  col = NULL,
  lwd = 2,
  pch = 16,
  legend = TRUE,
  legend_pos = "topright",
  layout = TRUE,
  xlim = NULL,
  ylim = NULL,
  main = NULL,
  xlab = NULL,
  ylab = NULL
)
```

## Arguments

- x:

  Data frame returned by
  [`calc_stratified_index()`](https://tokami.github.io/DATRASextra/reference/calc_stratified_index.md).

- x_var:

  Name of the column to use as the x-axis. Defaults to `"Year"` if
  present, otherwise the first non-result column.

- panel_var:

  Optional column name used to split the plot into panels (e.g.
  `"Survey"`). Default `NULL` (single panel).

- ci:

  Logical; draw per-group confidence-interval ribbons. Default `TRUE`.

- ci_alpha:

  Transparency of the CI ribbons (0-1). Default `0.2`.

- log_scale:

  Logical; log-transform the y-axis. Default `FALSE`.

- fixed_ylim:

  Logical; share a common y-axis range across panels. Default `TRUE`.

- col:

  Character vector of colours, one per unique `group` value. Defaults to
  the DATRASextra discrete palette.

- lwd:

  Line width. Default `2`.

- pch:

  Point symbol. Default `16`.

- legend:

  Logical; draw a legend for the group colours. Default `TRUE`;
  suppressed automatically when there is only one group.

- legend_pos:

  Legend position string passed to
  [`graphics::legend()`](https://rdrr.io/r/graphics/legend.html).
  Default `"topright"`.

- layout:

  Logical; when `TRUE` (default) and the plot has multiple panels, the
  function sets `par(mfrow)` automatically and restores it on exit. Set
  to `FALSE` to draw panels sequentially into the caller's current
  layout – useful when combining with other plots via
  `par(mfrow = ...)`.

- xlim, ylim:

  Optional axis limits.

- main:

  Optional plot title.

- xlab, ylab:

  Axis labels. Auto-generated from `cpue_method` if `NULL`.

## Value

Invisibly returns `x`.

## See also

[`calc_stratified_index()`](https://tokami.github.io/DATRASextra/reference/calc_stratified_index.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data(dab)
dab <- add_swept_area(dab)
dab <- add_total_numbers_by_haul(dab, length_cuts = c(15, 25))
res <- calc_stratified_index(dab, by = "Year")
plot_index(res)
} # }
```
