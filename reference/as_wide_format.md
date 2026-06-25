# Convert a `datras_raw` object to a wide-format table

Create a wide-format data frame from the `HH` table of a `datras_raw` /
`DATRASraw` object. Matrix columns (e.g. `HaulN` or `HaulWgt` produced
with `length_cuts`) are expanded to one column per length bin.

## Usage

``` r
as_wide_format(x, vars = .default_hh_vars, add_vars = NULL, remove_vars = NULL)
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

A data frame with one row per haul.

## Details

Only `HH` columns are used. In addition to the explicitly requested
`vars`, `HaulN`, `HaulWgt`, and `SweptArea` are always appended when
present in `HH`. Variables not found in `HH` are omitted with a warning.

If any selected `HH` columns are matrices (produced by passing
`length_cuts` to
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
or
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)),
each matrix is expanded to one column per length bin. Columns are named
`<variable>_<bin>`, e.g. `HaulN_(0-20]` and `HaulN_(20-Inf]`. Unlike
[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md),
matrix columns with different bin structures are permitted.

## See also

[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md),
[`as_table()`](https://tokami.github.io/DATRASextra/reference/as_table.md)

## Examples

``` r
dab <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))

## Default columns plus auto-added HaulN, one column per length group
tab <- as_wide_format(dab)

## Adjust columns
tab <- as_wide_format(dab, add_vars = "Depth", remove_vars = "Ship")
```
