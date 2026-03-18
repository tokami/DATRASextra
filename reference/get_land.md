# Load dissolved Natural Earth land polygon

If download_map = FALSE, loads a dissolved land polygon shipped with the
package (Natural Earth 1:50m), used for offline plotting.

## Usage

``` r
get_land(download_map = FALSE, scale = 50)
```

## Source

Natural Earth via rnaturalearth.

## Arguments

- download_map:

  Logical. If `FALSE` the download map included in DATRASextra is used
  for plotting (with 1:50m scale). If `TRUE`, a map is downloaded with
  [`rnaturalearth::ne_download()`](https://docs.ropensci.org/rnaturalearth/reference/ne_download.html)
  and the specified scale.

- scale:

  Scale of the map to be downloaded by
  [`rnaturalearth::ne_download()`](https://docs.ropensci.org/rnaturalearth/reference/ne_download.html).
  (Only used if download_map = TRUE).

## Value

An sf object (single MULTIPOLYGON) in EPSG:4326.
