# Add weight-at-length estimates to a `datras_raw` object

Estimate catch weight from length data and add the resulting weight
fields to a `datras_raw` / `DATRASraw` object.

## Usage

``` r
add_weight_at_length(
  x,
  max_length = NULL,
  max_weight = NULL,
  plus_group = FALSE,
  lw_source = c("lookup", "ca"),
  lookup_as_backup = FALSE,
  verbose = TRUE
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

  Logical. If `TRUE` the midlength for the weight calculation of the
  last length bin is not using the upper limit of this length bin, which
  might be `Inf` or arbitrarily high and result in an unrealistically
  high weight for that length bin. Instead the lower limit plus half of
  the size of the second last length bin is used to define the mid
  length of the largest length bin.

- lw_source:

  Character string specifying the source of length-weight parameters.
  One of `"ca"` or `"lookup"`.

- lookup_as_backup:

  Logical. If `TRUE`, lookup parameters of the length-weight
  relationship (a, b) in the species_info table are used. Default:
  `FALSE`.

- verbose:

  Logical. If `TRUE` (default), progress messages are printed.

## Value

A `datras_raw` object with estimated weight information added.

## Details

The function derives weight-at-length either from an lookup
length-weight relationship fitted to the `CA` table or, if
`lw_source = "lookup"`, uses length-weight parameters from the
species_info table.

- If `lw_source = "lookup"`, a linear model of the form \\\log(IndWgt) ~
  \log(LngtCm)\\ is fitted to positive individual weights in the `CA`
  table. Predicted weights are then assigned to length classes defined
  by `attr(x, "cm.breaks")`, multiplied by numbers-at-length, and
  optionally divided by haul duration.

- If `lw_source = "lookup"`, weight is added using length-weight
  parameters from the species_info table.

## See also

[`check_weights()`](https://tokami.github.io/DATRASextra/reference/check_weights.md),
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)

## Examples

``` r
## Add numbers at length
dab <- add_numbers_at_length(dab)

## Add fitted weight-at-length estimates
x <- add_weight_at_length(dab)

## Exclude large values when fitting the length-weight model
x <- add_weight_at_length(dab, max_length = 100, max_weight = 10000)

## Use lookup weight-at-length instead from the species_info table
x <- add_weight_at_length(dab, lw_source = "lookup")
```
