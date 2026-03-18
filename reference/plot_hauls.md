# Plot the spatial distribution of hauls

Plot the number of hauls by ICES rectangle on a longitude-latitude grid
using the internal `survey_info_full` data set.

## Usage

``` r
plot_hauls(plot_map = TRUE, xlim = NULL, ylim = NULL)
```

## Arguments

- plot_map:

  Logical. If `TRUE` (default), add a coastline map in the background
  when the required map packages are installed.

- xlim:

  Optional numeric vector of length 2 giving the longitude limits of the
  plot.

- ylim:

  Optional numeric vector of length 2 giving the latitude limits of the
  plot.

## Value

Invisibly returns `NULL`.

## Details

The function aggregates haul counts over spatial bins derived from ICES
statistical rectangles and displays them as a heat map. Optionally, a
coastline map is added if the suggested packages `maps` and `mapdata`
are available.

Hauls are aggregated to a regular grid based on ICES rectangle
midpoints. The resulting frequencies are plotted with
[`image()`](https://rdrr.io/r/graphics/image.html) using a heat-map
colour scale.

The map background is only drawn if both the `maps` and `mapdata`
packages are available.

## Examples

``` r
if (FALSE) { # \dontrun{
## Plot all hauls
plot_hauls()

## Plot hauls in a restricted region
plot_hauls(xlim = c(-10, 15), ylim = c(50, 65))
} # }
```
