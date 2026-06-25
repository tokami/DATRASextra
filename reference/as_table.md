# Format a `datras_raw` object as a table

Convert a `datras_raw` / `DATRASraw` object to either long or wide
tabular format using haul-level (`HH`) variables only.

## Usage

``` r
as_table(
  x,
  vars = .default_hh_vars,
  add_vars = NULL,
  remove_vars = NULL,
  type = "long"
)
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

- type:

  Character string specifying the output format: `"long"` (default) or
  `"wide"`.

## Value

A data frame in the requested format.

## Details

This is a convenience wrapper around
[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md)
and
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md).

Both functions only use columns from the `HH` table. In addition to
explicitly requested `vars`, `HaulN`, `HaulWgt`, and `SweptArea` are
always appended when present in `HH` (e.g. after calling
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md),
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md),
or
[`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md)).

Matrix columns such as `HaulN` or `HaulWgt` produced by passing
`length_cuts` to
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
or
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)
are handled differently by each format:

- `type = "long"`: matrix columns are expanded to one row per haul x
  length group. A `LengthGroup` column is added identifying the bin. All
  matrix columns must share the same bin structure.

- `type = "wide"`: matrix columns are expanded to one column per length
  bin, named `<variable>_<bin>` (e.g. `HaulN_(0-20]`).

## See also

[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md),
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md)

## Examples

``` r
dab <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))

## Long format - one row per haul x length group
tab_long <- as_table(dab, type = "long")

## Wide format - one column per length group
tab_wide <- as_table(dab, type = "wide")

## Adjust the default column set
tab <- as_table(dab, add_vars = "Depth", remove_vars = "Ship")
```
