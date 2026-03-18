# Add total haul biomass to `HH`

Calculate total biomass by haul and add it to the `HH` component of a
`datras_raw` / `DATRASraw` object using the underlying DATRAS method.

## Usage

``` r
add_weight_by_haul(x, per_minute = TRUE)
```

## Arguments

- x:

  A `datras_raw` object.

- per_minute:

  Logical. If `TRUE` (default), biomass is divided by haul duration in
  minutes.

## Value

A `datras_raw` object with haul-level biomass added to `HH`.

## Details

This function is a thin wrapper around
[`DATRAS::addWeightByHaul()`](https://rdrr.io/pkg/DATRAS/man/addWeightByHaul.html),
applied after checking that the input is a valid `datras_raw` object.

## See also

[`add_weight()`](https://tokami.github.io/DATRASextra/reference/add_weight.md),
[`add_weight_by_haul_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul_empirical.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_weight_by_haul(x)
x <- add_weight_by_haul(x, per_minute = FALSE)
} # }
```
