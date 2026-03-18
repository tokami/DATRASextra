# Add total numbers by haul to a DATRAS object

Calculates total numbers for each haul by summing numbers-at-length
across all length classes, and stores the result in the `HH` table as
`HaulN`.

## Usage

``` r
add_total_numbers_by_haul(
  x,
  cm_breaks = NULL,
  by = get_accuracy_cm(x),
  length_cuts = NULL
)
```

## Arguments

- x:

  A `DATRASraw` object.

- cm_breaks:

  Numeric vector of break points defining the length classes in cm. If
  `NULL`, break points are created automatically from the observed range
  of `HL$LngtCm` using `by`. Only used if numbers-at-length must first
  be added.

- by:

  Numeric scalar giving the width of the default length classes in cm.
  Only used when `cm_breaks = NULL` and numbers-at-length must first be
  added.

- length_cuts:

  Optional numeric vector of break points for aggregating the original
  length classes into coarser bins after numbers-at-length have been
  calculated. Must be strictly increasing.

## Value

A `DATRASraw` object with total numbers by haul added to the `HH`
component as column `HaulN`.

## Details

If numbers-at-length are not already present in the object, they are
first created with
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md).

Optionally, the resulting length classes can be aggregated into coarser
bins via `length_cuts`.

This function sums the matrix `x[["HH"]][["N"]]` over length classes and
writes the result to `x[["HH"]][["HaulN"]]`. If `length_cuts` is
provided, these original classes are summed into the requested bins
instead of a single vector.

If `N` is not yet available, the function calls
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)
first.

## See also

[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)

## Examples

``` r
## Add total numbers by haul
x <- add_total_numbers_by_haul(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm

## Aggregate into broader bins
x <- add_total_numbers_by_haul(dab, length_cuts = c(0, 10, 20, 30, Inf))
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
```
