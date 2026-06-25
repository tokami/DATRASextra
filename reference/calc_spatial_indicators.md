# Centre of gravity from survey data

Computes the CPUE-weighted centre of gravity (CoG) from a `datras_raw`
object for each level of the `by` grouping (typically `"Year"`).

## Usage

``` r
calc_spatial_indicators(
  x,
  value_var = "HaulN",
  cpue_method = c("per_swept_area", "per_hour", "count"),
  by = "Year",
  lat_var = "lat",
  lon_var = "lon"
)
```

## Arguments

- x:

  A `datras_raw` object. `HH` must contain `value_var`, `lat_var`, and
  `lon_var`.

- value_var:

  Name of the `HH` column used as CPUE weights. Default `"HaulN"` (added
  by
  [`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)).
  May be a numeric vector or a matrix; in the latter case one set of
  indicators is computed per column.

- cpue_method:

  Standardisation applied to `value_var` before weighting:
  `"per_swept_area"` (per km^2; requires `SweptArea`), `"per_hour"` (per
  hour; uses `HaulDur`), or `"count"` (raw totals). Default
  `"per_swept_area"`.

- by:

  Character vector of `HH` columns used to define groups (e.g. `"Year"`,
  `c("Year","Quarter")`). Default `"Year"`.

- lat_var, lon_var:

  Names of the latitude and longitude columns in `HH`. Defaults `"lat"`
  and `"lon"` (added by
  [`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md)).

## Value

A data frame with one row per `by`-group x length-group and columns: the
`by` columns, `group`, `cpue_method`, `n_hauls`, `cog_lat`, `cog_lon`.

## Details

The centre of gravity is the CPUE-weighted mean position:
\$\$\text{CoG}\_\text{lat} = \frac{\sum_i w_i \phi_i}{\sum_i w_i},\quad
\text{CoG}\_\text{lon} = \frac{\sum_i w_i \lambda_i}{\sum_i w_i}\$\$
where \\w_i\\ is the CPUE at haul \\i\\. Hauls with zero or missing CPUE
contribute to `n_hauls` but not to the weighted sums.

## See also

[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md),
[`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md),
[`calc_stratified_index()`](https://tokami.github.io/DATRASextra/reference/calc_stratified_index.md),
[`plot_spatial_indicators()`](https://tokami.github.io/DATRASextra/reference/plot_spatial_indicators.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data(dab)
dab <- add_swept_area(dab)
dab <- add_total_numbers_by_haul(dab)
calc_spatial_indicators(dab, by = "Year")

## length-group CoG
dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 15, Inf))
calc_spatial_indicators(dab, by = "Year")
} # }
```
