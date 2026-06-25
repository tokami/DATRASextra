# Add numbers-at-length to a DATRAS object

Calculates numbers-at-length for each haul and stores the result in the
`HH` table of a `DATRASraw` object as matrix `N`, with one row per haul
and one column per length class.

## Usage

``` r
add_numbers_at_length(x, cm_breaks = NULL, by = get_accuracy_cm(x))
```

## Arguments

- x:

  A `DATRASraw` object.

- cm_breaks:

  Numeric vector of break points defining the length classes in cm. If
  `NULL`, break points are created automatically from the observed range
  of `HL$LngtCm` using `by`.

- by:

  Numeric scalar giving the width of the default length classes in cm.
  Defaults to the survey's native recording resolution via
  [`get_accuracy_cm()`](https://tokami.github.io/DATRASextra/reference/get_accuracy_cm.md).
  Only used when `cm_breaks = NULL`.

## Value

A `DATRASraw` object with numbers-at-length added to the `HH` component
as matrix `N`.

## Details

By default, numbers-at-length are calculated using the available
haul-level length data in `HL` and the default length recording
resolution of the data.

The function first adds numbers-at-length at the finest available length
resolution and stores the result as `x[["HH"]][["N"]]`.

The applied break points are stored as attribute `cm.breaks` on the
returned object.

## See also

[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)

## Examples

``` r
## Add numbers-at-length using the default length resolution
x <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
```
