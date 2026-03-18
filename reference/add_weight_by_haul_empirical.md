# Add empirical total haul biomass to `HH`

Calculate total biomass by haul from empirical species-specific
length-weight parameters and add it to the `HH` component of a
`datras_raw` / `DATRASraw` object.

## Usage

``` r
add_weight_by_haul_empirical(x, per_minute = TRUE)
```

## Arguments

- x:

  A `datras_raw` object.

- per_minute:

  Logical. If `TRUE` (default), haul biomass is divided by haul duration
  in minutes.

## Value

A `datras_raw` object with an added `HaulWgt` field in `HH`.

## Details

The function uses the Aphia ID in the `HL` table to look up the
empirical length-weight parameters `a` and `b` in `species_info`,
predicts weight for each length class defined by `attr(x, "cm.breaks")`,
and combines these with haul-specific numbers-at-length stored in `HH$N`
to compute total haul biomass.

The function requires that exactly one unique `Valid_Aphia` value is
present in `x[["HL"]]`, and that matching empirical length-weight
parameters are available in the internal `species_info` table.

Weight-at-length is calculated as: \$\$ W = a \times L^b \$\$

Total biomass for each haul is then calculated by multiplying the
haul-level numbers-at-length by the predicted weight-at-length vector
and summing across length classes.

## See also

[`add_weight()`](https://tokami.github.io/DATRASextra/reference/add_weight.md),
[`add_weight_empirical()`](https://tokami.github.io/DATRASextra/reference/add_weight_empirical.md),
[`add_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_weight_by_haul.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_weight_by_haul_empirical(x)
x <- add_weight_by_haul_empirical(x, per_minute = FALSE)
} # }
```
