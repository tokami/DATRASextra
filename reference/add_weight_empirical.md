# Add empirical weight-at-length estimates to `HH`

Calculate weight-at-length from empirical species-specific length-weight
parameters and add the resulting weights to the `HH` component of a
`datras_raw` / `DATRASraw` object.

## Usage

``` r
add_weight_empirical(x, per_minute = TRUE)
```

## Arguments

- x:

  A `datras_raw` object.

- per_minute:

  Logical. If `TRUE` (default), estimated weights are divided by haul
  duration in minutes.

## Value

A `datras_raw` object with an added `Wgt` field in `HH`.

## Details

The function uses the Aphia ID in the `HL` table to look up the
empirical length-weight parameters `a` and `b` in `species_info`,
predicts weight for each length class defined by `attr(x, "cm.breaks")`,
and multiplies these by numbers-at-length stored in `HH$N`.

The function requires that exactly one unique `Valid_Aphia` value is
present in `x[["HL"]]`, and that matching empirical length-weight
parameters are available in the internal `species_info` table.

Weight-at-length is calculated as: \$\$ W = a \times L^b \$\$

where `L` is length in centimetres and `W` is weight in grams.

The resulting length-specific weights are multiplied by the
haul-specific numbers-at-length matrix `HH$N`. If `per_minute = TRUE`,
the resulting weights are standardized by haul duration.

## See also

[`add_weight()`](https://tokami.github.io/DATRASextra/reference/add_weight.md),
[`add_weight_by_haul_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul_empirical.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_weight_empirical(x)
x <- add_weight_empirical(x, per_minute = FALSE)
} # }
```
