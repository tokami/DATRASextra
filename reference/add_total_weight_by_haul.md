# Add total haul biomass to `HH`

Calculate total biomass by haul and add it to the `HH` component of a
`datras_raw` / `DATRASraw` object based on available information in the
`CA` data set. If `CA` data is not available, total haul biomass can be
calculated from empirical species-specific length-weight parameters.

## Usage

``` r
add_total_weight_by_haul(
  x,
  per_minute = TRUE,
  max_length = NULL,
  max_weight = NULL,
  empirical = FALSE,
  length_cuts = NULL
)
```

## Arguments

- x:

  A `datras_raw` object.

- per_minute:

  Logical. If `TRUE` (default), estimated weights are divided by haul
  duration in minutes.

- max_length:

  Optional numeric value giving the maximum length in centimetres to
  retain when fitting the length-weight relationship. Observations above
  this value are excluded.

- max_weight:

  Optional numeric value giving the maximum individual weight in grams
  to retain when fitting the length-weight relationship. Observations
  above this value are excluded.

- empirical:

  Logical. If `TRUE`, use empirical weight-at-length calculations
  instead of fitting a length-weight model to the `CA` table.

- length_cuts:

  Optional numeric vector of break points for aggregating the original
  length classes into coarser bins after numbers-at-length have been
  calculated. Must be strictly increasing.

## Value

A `datras_raw` object with haul-level biomass added to `HH`.

## Details

Optionally, the resulting length classes can be aggregated into coarser
bins via `length_cuts`.

If empirical = TRUE, the function requires that exactly one unique
`Valid_Aphia` value is present in `x[["HL"]]`, and that matching
empirical length-weight parameters are available in the internal
`species_info` table.

Weight-at-length is calculated as: \$\$ W = a \times L^b \$\$

Total biomass for each haul is then calculated by multiplying the
haul-level numbers-at-length by the predicted weight-at-length vector
and summing across length classes.

Provide your own a and b parameters by overwriting the relevant fields
in the species_info table.

## See also

[`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)

## Examples

``` r
## Add numbers at length
dab <- add_numbers_at_length(dab)

x <- add_total_weight_by_haul(dab)
#> Multiple aphia IDs in data set (n = 1). Caclulating weight at length for each and summing them all up.
#> Running aphia: 127139

x <- add_total_weight_by_haul(dab, empirical = TRUE)
#> Multiple aphia IDs in data set (n = 1). Caclulating weight at length for each and summing them all up.
#> Running aphia: 127139
```
