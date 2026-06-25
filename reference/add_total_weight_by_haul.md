# Add total haul biomass to `HH`

Calculate total biomass by haul and add it to the `HH` component of a
`datras_raw` / `DATRASraw` object.

## Usage

``` r
add_total_weight_by_haul(
  x,
  max_length = NULL,
  max_weight = NULL,
  plus_group = FALSE,
  lw_source = c("lookup", "ca"),
  lw_pars = NULL,
  length_cuts = NULL,
  per_minute = FALSE
)
```

## Arguments

- x:

  A `datras_raw` object.

- max_length:

  Optional numeric value giving the maximum length in centimetres to
  retain when fitting the length-weight relationship. Observations above
  this value are excluded.

- max_weight:

  Optional numeric value giving the maximum individual weight in grams
  to retain when fitting the length-weight relationship. Observations
  above this value are excluded.

- plus_group:

  Logical. If `TRUE`, all fish at or above the largest length class are
  accumulated into that class. Passed to
  [`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md).

- lw_source:

  Character string specifying the source of length-weight parameters.
  One of `"ca"` or `"lookup"`.

- lw_pars:

  Optional custom length-weight parameters passed to
  [`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md).
  See that function for the accepted forms.

- length_cuts:

  Optional numeric vector of break points for aggregating the original
  length classes into coarser bins. Must be strictly increasing.

- per_minute:

  Logical. If `TRUE`, add `HaulWgtPerMin`, calculated as `HaulWgt`
  divided by haul duration in minutes. If `FALSE`, only `HaulWgt` is
  added.

## Value

A `datras_raw` object with `HaulWgt` added to `HH`. If
`per_minute = TRUE`, `HaulWgtPerMin` is also added.

## Details

Optionally, total biomass can be standardized by haul duration and
returned as biomass per minute. Length classes can also be aggregated
into coarser bins via `length_cuts`.

If weight-at-length information is not already present, the function
first calls
[`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)
to create `x[["HH"]][["Wgt"]]`.

Weight-at-length is calculated as: \$\$ W = a \times L^b \$\$

Total biomass for each haul is calculated by summing estimated
weight-at-length across length classes and is stored in
`x[["HH"]][["HaulWgt"]]`.

If `length_cuts` is supplied, `HaulWgt` is a matrix with one column per
aggregated length bin. Otherwise, `HaulWgt` is a vector with one value
per haul.

If `per_minute = TRUE`, the function also adds
`x[["HH"]][["HaulWgtPerMin"]]`, calculated by dividing `HaulWgt` by
`HaulDur`. If `HaulWgt` is a matrix, each row is divided by the
corresponding haul duration.

## See also

[`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)

## Examples

``` r
## Add numbers at length
dab <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm

## Add total haul biomass
x <- add_total_weight_by_haul(dab)

## Add total haul biomass and biomass per minute
x <- add_total_weight_by_haul(dab, per_minute = TRUE)

## Use length-weight parameters from the species_info table
x <- add_total_weight_by_haul(dab, lw_source = "lookup")
```
