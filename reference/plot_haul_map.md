# Plot haul maps through space and time

Visualise the spatial footprint of survey hauls by year using faceted
maps. Point sizes can optionally be scaled by a haul-level variable or
by a haul-level variable standardised by effort.

## Usage

``` r
plot_haul_map(
  x,
  value_var = "HaulN",
  effort_var = "SweptArea",
  years = NULL,
  plot_map = TRUE,
  fixed_axes = TRUE,
  xlim = NULL,
  ylim = NULL,
  size_var = NULL,
  cex = 0.8,
  cex_range = c(0.5, 2.5),
  col_points = NULL,
  pch = 16,
  transform = c("sqrt", "log1p", "identity"),
  show_size_legend = TRUE,
  legend_n = 4,
  legend_pos = "bottomright",
  legend_title = NULL,
  verbose = TRUE
)
```

## Arguments

- x:

  A DATRAS-like object containing an `HH` data frame.

- value_var:

  Optional character string naming a haul-level variable in `x[["HH"]]`
  used to scale point sizes. If `NULL`, point sizes are constant unless
  `size_var` is provided.

- effort_var:

  Optional character string naming a haul-level effort variable in
  `x[["HH"]]`. If both `value_var` and `effort_var` are available, point
  sizes are scaled by `value_var / effort_var`.

- years:

  Optional numeric or character vector specifying which years to plot.
  Defaults to all available years.

- plot_map:

  Logical; if `TRUE`, add land polygons in the background.

- fixed_axes:

  Logical; if `TRUE`, all panels use the same `xlim` and `ylim`. If
  `FALSE`, each panel is scaled to the data shown in that year.

- xlim:

  Optional numeric vector of length 2 giving x-axis limits.

- ylim:

  Optional numeric vector of length 2 giving y-axis limits.

- size_var:

  Deprecated alias for `value_var`. If supplied, it overrides
  `value_var`.

- cex:

  Base point size used when no scaling variable is available.

- cex_range:

  Numeric vector of length 2 giving the minimum and maximum point size
  when scaling is applied.

- col_points:

  Colour used for haul locations.

- pch:

  Plotting symbol used for haul locations.

- transform:

  Character string specifying the transformation applied before scaling
  point sizes. One of `"sqrt"`, `"log1p"`, or `"identity"`.

- verbose:

  Logical; if `TRUE`, print which variable was used for point-size
  scaling.

## Value

Invisibly returns a list with the plotted years, axis limits, panel
layout, and the variable used for scaling.

## Details

The function expects a DATRAS-like object containing a haul table
`x[["HH"]]` with at least the columns `Year`, `lon`, and `lat`.

If both `value_var` and `effort_var` are available, point sizes are
based on `value_var / effort_var`, which can be useful for visualising a
haul-level quantity standardised by effort. However, in standard DATRAS
haul tables, `HaulN` is typically a haul identifier rather than a catch
variable and is therefore generally not meaningful for this purpose.

## Examples

``` r
if (FALSE) { # \dontrun{
## Plot yearly haul maps
plot_haul_map(dat)

## Restrict to selected years
plot_haul_map(dat, years = 2010:2015)

## Scale point size by a haul-level variable
plot_haul_map(dat, value_var = "HaulDur")

## Scale point size by a haul-level quantity standardised by effort
plot_haul_map(dat, value_var = "TotalNo", effort_var = "SweptArea")
} # }
```
