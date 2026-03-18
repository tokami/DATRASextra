# Add weight-at-length estimates to a `datras_raw` object

Estimate catch weight from length data and add the resulting weight
fields to a `datras_raw` / `DATRASraw` object.

## Usage

``` r
add_weight_at_length(
  x,
  per_minute = TRUE,
  max_length = NULL,
  max_weight = NULL,
  empirical = FALSE
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

## Value

A `datras_raw` object with estimated weight information added.

## Details

The function derives weight-at-length either from an empirical
length-weight relationship fitted to the `CA` table or, if
`empirical = TRUE`, uses length-weight parameters from the species_info
table.

- If `empirical = FALSE`, a linear model of the form \\\log(IndWgt) ~
  \log(LngtCm)\\ is fitted to positive individual weights in the `CA`
  table. Predicted weights are then assigned to length classes defined
  by `attr(x, "cm.breaks")`, multiplied by numbers-at-length, and
  optionally divided by haul duration.

- If `empirical = TRUE`, weight is added using length-weight parameters
  from the species_info table.

## See also

[`check_weights()`](https://tokami.github.io/DATRASextra/reference/check_weights.md),
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)

## Examples

``` r
## Add numbers at length
dab <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm

## Add fitted weight-at-length estimates
x <- add_weight_at_length(dab)

## Exclude large values when fitting the length-weight model
x <- add_weight_at_length(dab, max_length = 100, max_weight = 10000)

## Use empirical weight-at-length instead
x <- add_weight_at_length(dab, empirical = TRUE)
```
