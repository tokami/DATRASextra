# Unified DATRAS overview plotting

Plots spatial overviews from DATRAS haul data using gridded image maps
or point maps, with optional grouping and faceting.

## Usage

``` r
plot_datras_overview(
  x = NULL,
  mode = c("points", "grid"),
  metric = c("presence", "sum", "mean", "count_hauls", "count_surveys"),
  spatial_basis = c("raw", "statrec"),
  by_survey = FALSE,
  by_gear = FALSE,
  by_quarter = FALSE,
  by_year = FALSE,
  by_daynight = FALSE,
  multi_panels = FALSE,
  value_var = NULL,
  offset_var = NULL,
  transform = c("none", "log1p", "sqrt", "log10"),
  fixed_scale = TRUE,
  fixed_axes = TRUE,
  plot_map = TRUE,
  xlim = NULL,
  ylim = NULL,
  col = NULL,
  palette_rev = FALSE,
  alpha = 0.8,
  pch = 16,
  cex = 0.8,
  size_range = c(0.7, 2.2),
  legend = TRUE,
  legend_mode = c("auto", "none", "global", "per_panel"),
  legend_outside = FALSE,
  max_legend_items = 30,
  max_grid_legend_levels = 5,
  legend_ncol = 1,
  legend_pos = NULL,
  legend_cex = NULL,
  grid_group_strategy = c("dominant", "mixed", "error"),
  main = NULL
)
```

## Arguments

- x:

  A DATRAS-like object containing `x[['HH']]`, or `NULL` to use
  [`DATRASextra::survey_info_full_raw`](https://tokami.github.io/DATRASextra/reference/survey_info_full_raw.md)
  (fallback `survey_info_full`).

- mode:

  Plot mode: `"grid"` or `"points"`. Default is `"points"`.

- metric:

  Grid metric: `"sum"`, `"mean"`, `"count_hauls"`, `"presence"`, or
  `"count_surveys"`.

- spatial_basis:

  Spatial basis used for coordinates: `"raw"` uses haul coordinates,
  `"statrec"` uses ICES rectangle midpoints from `StatRec`.

- by_survey, by_gear, by_quarter, by_year, by_daynight:

  Logical grouping toggles used to define panel groups.

- multi_panels:

  Logical. If `TRUE`, plot one group per panel.

- value_var:

  Optional haul-level variable to map to values.

- offset_var:

  Optional haul-level denominator variable.

- transform:

  Value transform: `"none"`, `"log1p"`, `"sqrt"`, `"log10"`.

- fixed_scale:

  Logical. Use common color scale across panels in grid mode.

- fixed_axes:

  Logical. Use common map extent across panels.

- plot_map:

  Logical. Add land map layer.

- xlim, ylim:

  Optional map limits.

- col:

  Optional color palette.

- palette_rev:

  Logical. Reverse default palette direction.

- alpha:

  Point alpha in points mode.

- pch:

  Point symbol.

- cex:

  Base point size.

- size_range:

  Point size range when value-based scaling is used.

- legend:

  Logical. Draw legends.

- legend_mode:

  Legend behavior: `"auto"`, `"none"`, `"global"`, or `"per_panel"`.

- legend_outside:

  Logical. If `TRUE`, draw the legend outside the main plotting panel
  area. For multi-panel layouts, a free panel is used when available;
  otherwise a narrow right-side legend panel is created.

- max_legend_items:

  Maximum number of group legend entries.

- max_grid_legend_levels:

  Maximum number of levels shown in grid legends.

- legend_ncol:

  Number of columns in legend

- legend_pos:

  position of legend. Default: NULL.

- legend_cex:

  cex of legend. Default: NULL.

- grid_group_strategy:

  Strategy for grouped single-panel grid maps when multiple groups occur
  in the same cell: `"dominant"`, `"mixed"`, or `"error"`.

- main:

  Optional title for single-panel mode.

## Value

Invisibly returns list with processed data and plotting metadata.
