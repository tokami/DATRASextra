# Convert a `datras_raw` object to a long-format table

Create a long-format data frame from the `HH` table of a `datras_raw` /
`DATRASraw` object. Matrix columns (e.g. `HaulN` or `HaulWgt` produced
with `length_cuts`) are expanded to one row per haul x length group.

## Usage

``` r
as_long_format(x, vars = .default_hh_vars, add_vars = NULL, remove_vars = NULL)
```

## Arguments

- x:

  A `datras_raw` object.

- vars:

  Character vector of `HH` variable names to include. Defaults to 15
  common haul-level columns: `Survey`, `Gear`, `Country`, `Ship`,
  `Year`, `Quarter`, `Month`, `Day`, `lon`, `lat`, `timeOfYear`,
  `abstime`, `DayNight`, `TimeShotHour`, `HaulDur`.

- add_vars:

  Character vector of additional `HH` variable names to append to
  `vars`. Applied after `remove_vars`.

- remove_vars:

  Character vector of variable names to drop from `vars`. Applied before
  `add_vars`.

## Value

A data frame with one row per haul, or one row per haul x length group
when matrix columns are present.

## Details

Only `HH` columns are used. In addition to the explicitly requested
`vars`, `HaulN`, `HaulWgt`, and `SweptArea` are always appended when
present in `HH`. Variables not found in `HH` are omitted with a warning.

If any selected `HH` columns are matrices (produced by passing
`length_cuts` to
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
or
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)),
the output is expanded to one row per haul x length group. A
`LengthGroup` column is added identifying the bin, and the matrix
columns become scalar columns. All matrix columns must share the same
bin structure; an error is raised if they differ.

## See also

[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md),
[`as_table()`](https://tokami.github.io/DATRASextra/reference/as_table.md)

## Examples

``` r
dab <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))

## Default columns plus auto-added HaulN, expanded to long
tab <- as_long_format(dab)

## Adjust columns
tab <- as_long_format(dab, add_vars = "Depth", remove_vars = "Ship")

## Scalar HaulN only (no length_cuts)
dab2 <- add_total_numbers_by_haul(dab)
tab <- as_long_format(dab2)
```
