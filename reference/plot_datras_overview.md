# Unified DATRAS overview plotting

Plots spatial overviews from DATRAS haul data using gridded image maps
or point maps, with optional grouping and faceting.

## Usage

``` r
plot_datras_overview(
  x = NULL,
  mode = c("points", "grid"),
  grid_resolution = c(1, 0.5),
  metric = c("presence", "sum", "mean", "count_hauls", "count_surveys",
    "species_richness"),
  spatial_basis = c("raw", "statrec"),
  by_survey = FALSE,
  by_gear = FALSE,
  by_quarter = FALSE,
  by_year = FALSE,
  by_daynight = FALSE,
  multi_panels = FALSE,
  panel_layout = c("auto", "horizontal", "vertical"),
  value_var = NULL,
  offset_var = NULL,
  positive_only = FALSE,
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
  max_grid_legend_levels = 5,
  legend_ncol = 1,
  legend_pos = NULL,
  legend_cex = NULL,
  grid_group_strategy = c("dominant", "mixed", "error"),
  main = NULL,
  years = NULL,
  asp = "auto",
  add = FALSE
)
```

## Arguments

- x:

  A DATRAS-like object containing `x[['HH']]`, or `NULL` to use
  [`DATRASextra::survey_info_full_raw`](https://tokami.github.io/DATRASextra/reference/survey_info_full_raw.md)
  (fallback `survey_info_full`).

- mode:

  Plot mode: `"grid"` or `"points"`. Default is `"points"`.

- grid_resolution:

  Numeric vector `c(lon_step, lat_step)` in degrees controlling the bin
  width for `mode = "grid"`. Default `c(1, 0.5)` gives the original 1 x
  0.5 degree grid. Finer values such as `c(0.5, 0.25)` add spatial
  detail; coarser values (e.g. `c(2, 1)`) reduce clutter for very dense
  data. Has no effect in `mode = "points"`.

- metric:

  Grid metric: `"sum"`, `"mean"`, `"count_hauls"`, `"presence"`,
  `"count_surveys"`, or `"species_richness"`. The `"species_richness"`
  option counts unique species (via `Valid_Aphia`) per haul in points
  mode and per grid cell (pooled across hauls) in grid mode; it requires
  `x` to contain an `HL` table with `haul.id` and `Valid_Aphia` columns.

- spatial_basis:

  Spatial basis used for coordinates: `"raw"` uses haul coordinates,
  `"statrec"` uses ICES rectangle midpoints from `StatRec`.

- by_survey, by_gear, by_quarter, by_year, by_daynight:

  Logical grouping toggles used to define panel groups.

- multi_panels:

  Logical. If `TRUE`, plot one group per panel.

- panel_layout:

  Arrangement of panels when `multi_panels = TRUE`. `"auto"` (default)
  uses
  [`grDevices::n2mfrow()`](https://rdrr.io/r/grDevices/n2mfrow.html) to
  choose a roughly square layout; `"horizontal"` places all panels in a
  single row; `"vertical"` places them in a single column. For
  matrix-valued `value_var` (length-class panels crossed with groups),
  `"horizontal"` transposes the row/column assignment.

- value_var:

  Optional haul-level variable to map to values.

- offset_var:

  Optional haul-level denominator variable.

- positive_only:

  Logical. If `TRUE`, only hauls with a strictly positive value are
  plotted. When `value_var` is supplied, positivity is determined from
  that variable (after dividing by `offset_var` if supplied). When
  `value_var` is `NULL`, the function falls back to total `HaulN` or
  `HaulWgt` from `HH` (whichever is found first); a warning is issued if
  neither is available. Default `FALSE`.

- transform:

  Value transform: `"none"`, `"log1p"`, `"sqrt"`, `"log10"`.

- fixed_scale:

  Logical. If `TRUE` (default), a common value scale is used across
  groups or panels: in grid mode the colour scale is shared across
  panels; in points mode point sizes are scaled relative to the global
  value range. If `FALSE`, each group (single-panel grouped mode) or
  each panel (multi-panel mode) is scaled independently, so point sizes
  reflect relative abundance within the group or panel rather than in
  absolute terms.

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

- years:

  Optional integer vector of years to include. If `NULL` (default), all
  years in the data are plotted.

- asp:

  Aspect ratio passed to
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html).
  `"auto"` (default) uses the latitude-corrected value
  `1 / cos(mean(ylim) * pi / 180)`, which gives equal physical distances
  per degree of longitude and latitude at the mean latitude. Pass `1`
  for a simpler equal-degrees ratio, or `NULL` to leave the aspect ratio
  determined by the device dimensions (current behaviour of base
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html)). Fixing
  `asp` prevents the map from distorting when figure margins or device
  dimensions change.

- add:

  Logical. If `FALSE` (default), the function configures its own
  graphics device via
  [`graphics::par()`](https://rdrr.io/r/graphics/par.html) (`mfrow`,
  `mar`, `oma`) and restores the previous settings on exit. If `TRUE`,
  no [`par()`](https://rdrr.io/r/graphics/par.html) changes are made:
  the plot is drawn into whatever panel or layout is already active,
  allowing the function to be embedded in figures created with
  `par(mfrow = ...)` or
  [`graphics::layout()`](https://rdrr.io/r/graphics/layout.html). When
  `add = TRUE`, the caller is responsible for setting appropriate
  margins.

## Value

Invisibly returns list with processed data and plotting metadata.
