# Add weight-at-length estimates to a `datras_raw` object

Estimate catch weight from length data and add the resulting weight
fields to a `datras_raw` / `DATRASraw` object.

## Usage

``` r
add_weight(
  x,
  per_minute = TRUE,
  max_length = NULL,
  max_weight = NULL,
  empirical = FALSE,
  by_haul = FALSE
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

  Logical. If `TRUE`, use empirical weight-at-length calculations via
  [`add_weight_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_empirical.md)
  instead of fitting a length-weight model to the `CA` table.

- by_haul:

  Logical. If `TRUE`, also add haul-level weight information using
  [`add_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul.md)
  or
  [`add_weight_by_haul_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul_empirical.md),
  depending on the value of `empirical`.

## Value

A `datras_raw` object with estimated weight information added.

## Details

The function derives weight-at-length either from an empirical
length-weight relationship fitted to the `CA` table or, if
`empirical = TRUE`, from the empirical helper functions
[`add_weight_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_empirical.md)
and optionally
[`add_weight_by_haul_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul_empirical.md).

The function first calls
[`DATRAS::checkSpectrum()`](https://rdrr.io/pkg/DATRAS/man/DATRAS-internal.html)
and then proceeds in one of two ways:

- If `empirical = FALSE`, a linear model of the form \\\log(IndWgt) ~
  \log(LngtCm)\\ is fitted to positive individual weights in the `CA`
  table. Predicted weights are then assigned to length classes defined
  by `attr(x, "cm.breaks")`, multiplied by numbers-at-length, and
  optionally divided by haul duration.

- If `empirical = TRUE`, weight is added using
  [`add_weight_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_empirical.md).
  If `by_haul = TRUE`, haul-level weight is also added using
  [`add_weight_by_haul_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul_empirical.md).

When `by_haul = TRUE` and `empirical = FALSE`, haul-level weight is
added using
[`add_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul.md).

## See also

[`check_weight()`](https://tokami.github.io/DATRASextra/reference/check_weight.md),
[`add_weight_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_empirical.md),
[`add_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul.md),
[`add_weight_by_haul_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul_empirical.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Add fitted weight-at-length estimates
x <- add_weight(x)

## Exclude large values when fitting the length-weight model
x <- add_weight(x, max_length = 100, max_weight = 10000)

## Use empirical weight-at-length instead
x <- add_weight(x, empirical = TRUE)

## Also add haul-level weight
x <- add_weight(x, by_haul = TRUE)
} # }
```
