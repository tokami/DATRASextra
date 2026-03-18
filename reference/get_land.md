# Load dissolved Natural Earth land polygon

If download_map = FALSE, loads a dissolved land polygon shipped with the
package (Natural Earth 1:10m), used for offline plotting.

## Usage

``` r
get_land(download_map = FALSE, scale = 50)
```

## Source

Natural Earth via rnaturalearth.

## Value

An sf object (single MULTIPOLYGON) in EPSG:4326.
