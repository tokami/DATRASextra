# Format a `datras_raw` object as a table

Convert a `datras_raw` / `DATRASraw` object to a single data frame in
long or wide format: the hauls (`HH`), the numbers at length by species
(`HL`), or the individual biological records (`CA`), each with the
selected haul-level variables attached.

## Usage

``` r
as_table(
  x,
  vars = .default_hh_vars,
  add_vars = NULL,
  remove_vars = NULL,
  type = "long",
  table = c("HH", "HL", "CA"),
  hl_by = c("Valid_Aphia", "LngtCm"),
  zeros = TRUE,
  ca_vars = .default_ca_vars
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
  `"wide"`. See Details for what each means per `table`.

- table:

  Character string naming the table to export: `"HH"` (default) for one
  row per haul, `"HL"` for numbers at length by haul and species, or
  `"CA"` for one row per individual record.

- hl_by:

  Character vector of `HL` columns that define a row for `table = "HL"`,
  in addition to the haul. Default `c("Valid_Aphia", "LngtCm")`: species
  x length class, summed over sex and catch category. Add `"Sex"` to
  keep sexes apart. Must contain `"Valid_Aphia"`.

- zeros:

  Logical. For `table = "HL"`: if `TRUE` (default), add a row with
  `Count = 0` for every haul in `HH` and species in `HL` without a
  record, so that averages over hauls include the hauls where a species
  was not caught.

- ca_vars:

  Character vector of `CA` columns to include for `table = "CA"`.
  Columns not found are omitted with a warning.

## Value

A data frame in the requested format.

## Details

For `table = "HH"` this is a convenience wrapper around
[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md)
and
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md).

`vars`, `add_vars` and `remove_vars` always select `HH` variables; for
`table = "HL"` and `"CA"` they are attached to each row by `haul.id`.
Columns that exist in both tables (e.g. `Survey`, `Year`, `Quarter`) are
taken once, from `HH`.

**`table = "HH"`.** In addition to explicitly requested `vars`, `HaulN`,
`HaulWgt`, and `SweptArea` are always appended when present in `HH`
(e.g. after calling
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

**`table = "HL"`.** `Count` is the raised number per haul computed by
DATRAS when the data are read (`HLNoAtLngt` times the sub-sampling
factor, and for `DataType = "C"` times `HaulDur / 60`), summed within
each `hl_by` group. The numbers are not rounded.
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)
(via
[`DATRAS::addSpectrum()`](https://rdrr.io/pkg/DATRAS/man/DATRAS-internal.html))
rounds each length class to whole fish, so the `HaulN` of
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
can differ slightly from the sum of `Count` over a haul. Records without
a length (`LngtCm` NA, e.g. catch-only records) are kept as rows with
`LngtCm = NA`; their `Count` is NA when no raised number is available,
as the numbers are unknown rather than zero. With `zeros = TRUE` the
zero rows have `NA` in the other `hl_by` columns, and the table has a
row for every haul x species, which can be large for many hauls and
species: select species first, e.g. with `clean_datras(aphias = )`.

- `type = "long"`: one row per haul x `hl_by` group.

- `type = "wide"`: one row per haul x species (x any other `hl_by`
  columns), with one column per length class named `Count_<LngtCm>`
  (e.g. `Count_25.5`) and 0 where no fish of that length was recorded.
  Records without a length go to a column `Count_NA`.

For a single species, the full haul x length grid is also available as
`as_table(x, add_vars = "N")` after
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md),
with the numbers rounded as described above.

**`table = "CA"`.** One row per `CA` record. Records that could not be
matched to a haul (`haul.id` NA, see `strict` in
[`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md))
are kept, with the `HH` variables taken from the record where it has
them and `NA` otherwise, and their number is reported in a message.
`type = "wide"` is not available.

For `table = "HL"` and `"CA"`, matrix columns of `HH` (`N`, or `HaulN`
and `HaulWgt` with `length_cuts`) are omitted with a warning, and
`HaulN`, `HaulWgt` and `SweptArea` are only included when requested in
`vars` or `add_vars`: a haul total repeated on every row is easily
counted twice.

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

## Numbers at length by haul and species, including zero catches
tab_hl <- as_table(dab, table = "HL", vars = c("Survey", "Year", "lon", "lat"))

## One row per haul and species, one column per length class
tab_hl_wide <- as_table(dab, table = "HL", type = "wide")

## Individual records with the haul position
tab_ca <- as_table(dab, table = "CA", vars = c("Year", "lon", "lat"))
```
