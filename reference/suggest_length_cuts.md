# Suggest length groups with equal numbers of fish

Derives cut points that split the catch into `n_groups` length groups
holding about equal numbers of fish, for use as `length_cuts` in
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
and
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md).

## Usage

``` r
suggest_length_cuts(x, n_groups)
```

## Arguments

- x:

  A `datras_raw` object with numbers-at-length, from
  [`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md).

- n_groups:

  Number of length groups, at least 2.

## Value

A numeric vector of cut points from 0 to `Inf`, with the attributes
`shares`, the share of fish in each group (binned as in
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)),
and `labels`, e.g. `"0-20 cm"` and `"20+ cm"`.

## Details

The interior cut points lie on the length-class boundaries of
`attr(x, "cm.breaks")`, at the boundary where the cumulative share of
fish over all hauls is closest to `1 / n_groups`, `2 / n_groups`, and so
on. The groups are therefore only as equal as the length classes allow.
When the length distribution is too concentrated to give `n_groups`
distinct groups, fewer are returned with a warning.

The numbers-at-length matrix sums all species in `x`, so `x` should hold
one species, e.g. after `clean_datras(aphias = )`.

## See also

[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md),
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)

## Examples

``` r
x <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
cuts <- suggest_length_cuts(x, 3)
cuts
#> [1]   0  16  18 Inf
#> attr(,"shares")
#> [1] 0.3002824 0.3079447 0.3917729
#> attr(,"labels")
#> [1] "0-16 cm"  "16-18 cm" "18+ cm"  
attr(cuts, "shares")
#> [1] 0.3002824 0.3079447 0.3917729
x <- add_total_numbers_by_haul(x, length_cuts = cuts)
```
