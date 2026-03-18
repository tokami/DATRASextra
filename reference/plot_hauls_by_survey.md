# Plot the spatial distribution of hauls for each survey

Plot haul density by location separately for each survey using the
internal `survey_info_full` data set.

## Usage

``` r
plot_hauls_by_survey(
  plot_map = TRUE,
  fixed_scale = TRUE,
  col = hcl.colors(12, "YlOrRd", rev = TRUE),
  xlim = NULL,
  ylim = NULL
)
```

## Arguments

- plot_map:

  Logical. If `TRUE` (default), add a coastline map in the background
  when the required map packages are installed.

- fixed_scale:

  Logical. If `TRUE` (default), use a common colour scale across surveys
  to make panels directly comparable. If `FALSE`, each survey gets its
  own scale based on its maximum haul density.

- col:

  A vector of colours used for the heat maps. Defaults to
  `hcl.colors(12, "YlOrRd", rev = TRUE)`.

- xlim:

  Optional numeric vector of length 2 giving the longitude limits of the
  plots.

- ylim:

  Optional numeric vector of length 2 giving the latitude limits of the
  plots.

## Value

Invisibly returns `NULL`.

## Details

The function aggregates haul counts over spatial bins derived from ICES
statistical rectangles and displays them as heat maps in a multi-panel
layout, with one panel per survey. Optionally, a coastline map is added
if the suggested packages `maps` and `mapdata` are available.

Hauls are aggregated to a regular grid based on ICES rectangle
midpoints. For each survey, the resulting frequencies are plotted with
[`image()`](https://rdrr.io/r/graphics/image.html) using a heat-map
colour scale.

If `fixed_scale = TRUE`, all panels use the same class breaks, allowing
direct comparison of haul intensity among surveys. If `FALSE`, class
breaks are determined separately for each survey.

The map background is only drawn if both the `maps` and `mapdata`
packages are available.

## See also

[`plot_hauls()`](https://tokami.github.io/DATRASextra/reference/plot_hauls.md),
[`plot_surveys()`](https://tokami.github.io/DATRASextra/reference/plot_surveys.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Plot haul density for all surveys
plot_hauls_by_survey()

## Use survey-specific colour scales
plot_hauls_by_survey(fixed_scale = FALSE)

## Restrict the plotted region
plot_hauls_by_survey(xlim = c(-10, 15), ylim = c(50, 65))
} # }
```
