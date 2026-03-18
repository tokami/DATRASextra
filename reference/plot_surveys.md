# Plot survey spatial coverage

Plot the spatial footprint of surveys using the internal
`survey_info_full` data set.

## Usage

``` r
plot_surveys(
  plot_map = TRUE,
  fixed_axes = TRUE,
  overlay = FALSE,
  consider_quarter = FALSE,
  xlim = NULL,
  ylim = NULL
)
```

## Arguments

- plot_map:

  Logical. If `TRUE` (default), add a coastline map in the background
  when the required map packages are installed.

- fixed_axes:

  Logical. If `TRUE` (default), use the same longitude and latitude
  limits for all panels when `overlay = FALSE`. If `FALSE`, each survey
  panel is scaled to its own spatial extent unless overridden by `xlim`
  or `ylim`.

- overlay:

  Logical. If `FALSE` (default), plot each survey separately. If `TRUE`,
  overlay all surveys in a single map and show the number of surveys
  represented in each spatial cell.

- consider_quarter:

  Logical. Only used when `overlay = TRUE`. If `TRUE`, survey-quarter
  combinations are treated as distinct survey units when counting
  overlap across space.

- xlim:

  Optional numeric vector of length 2 giving the longitude limits of the
  plot.

- ylim:

  Optional numeric vector of length 2 giving the latitude limits of the
  plot.

## Value

Invisibly returns `NULL`.

## Details

The function can either show each survey in a separate panel or overlay
all surveys in a single map. In overlay mode, the map shows how many
surveys sampled each spatial cell, optionally distinguishing survey
quarters.

When `overlay = FALSE`, the function draws the ICES rectangles sampled
by each survey as filled polygons, with one panel per survey.

When `overlay = TRUE`, the function aggregates survey occurrence to a
regular longitude-latitude grid derived from ICES rectangle midpoints
and displays the number of overlapping surveys using a heat map.

If `consider_quarter = TRUE`, survey-quarter combinations are counted
separately in overlay mode, so the map reflects overlap among
survey-quarter units rather than surveys alone.

The map background is only drawn if both the `maps` and `mapdata`
packages are available.

## See also

[`plot_hauls()`](https://tokami.github.io/DATRASextra/reference/plot_hauls.md),
[`plot_hauls_by_survey()`](https://tokami.github.io/DATRASextra/reference/plot_hauls_by_survey.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Plot each survey separately
plot_surveys()

## Overlay all surveys in one map
plot_surveys(overlay = TRUE)

## Overlay survey-quarter combinations
plot_surveys(overlay = TRUE, consider_quarter = TRUE)

## Allow each panel to use its own spatial extent
plot_surveys(fixed_axes = FALSE)
} # }
```
