# Add weight estimates to `HL` records following the FishGlob workflow

Calculate weight-at-length using empirical length-weight parameters and
add the resulting weight fields to the `HL` table of a `datras_raw` /
`DATRASraw` object.

## Usage

``` r
add_total_weight_by_haul_fishglob(x)
```

## Arguments

- x:

  A `datras_raw` object containing `HL` and `HH` tables.

## Value

A `datras_raw` object with the `HL` table updated to include the
additional columns:

- `Wgt_indiv`: estimated individual weight in grams,

- `Wgt_total`: estimated total weight for the record in kilograms.

## Details

The function merges the `HL` table with internal species information to
obtain empirical length-weight parameters (`aFG` and `bFG`), computes
individual weight from length, and then calculates total weight for each
length class record.

Weight-at-length is calculated for each `HL` record as: \$\$ Wgt\\indiv
= aFG \times LngtCm^{bFG} \$\$

where `LngtCm` is fish length in centimetres and `aFG` and `bFG` are
empirical species-specific length-weight parameters obtained from the
internal `species_info` data.

Total weight per record is then calculated as: \$\$ Wgt\\total =
Wgt\\indiv \times Count \$\$

Individual weight is first computed in grams and total weight is
returned in kilograms.

Only species belonging to the classes `Teleostei`, `Elasmobranchii`,
`Petromyzonti`, and `Myxini` are retained in the join with
`species_info`.

A warning is issued if species are present in the joined data but have
missing length-weight parameters.

## See also

[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_total_weight_by_haul_fishglob(x)
} # }
```
