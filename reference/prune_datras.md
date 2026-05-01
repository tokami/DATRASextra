# Prune a `datras_raw` object to selected columns

Reduce a `datras_raw` / `DATRASraw` object to a smaller set of columns
in the `HH`, `HL`, and `CA` tables.

## Usage

``` r
prune_datras(
  x,
  keep = NULL,
  add = NULL,
  drop = NULL,
  do_fishglob = FALSE,
  warn_missing = TRUE
)
```

## Arguments

- x:

  A `datras_raw` object.

- keep:

  Optional named list of columns to keep. List names should be `HH`,
  `HL`, and/or `CA`. If supplied, these columns replace the default
  columns for the named table(s).

- add:

  Optional named list of columns to add to the default columns. List
  names should be `HH`, `HL`, and/or `CA`.

- drop:

  Optional named list of columns to remove from the selected columns.
  List names should be `HH`, `HL`, and/or `CA`.

- do_fishglob:

  Logical. If `TRUE`, apply
  [`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md)
  instead of the standard DATRAS pruning rules.

- warn_missing:

  Logical. If `TRUE`, warn when requested columns are not present in the
  corresponding table.

## Value

A pruned `datras_raw` object.

## Details

This is mainly intended to reduce memory use when working with large
DATRAS data sets, while still allowing users to modify which columns are
retained.

If `do_fishglob = TRUE`, pruning is delegated to
[`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md).

By default, the function keeps a predefined set of core columns in each
of the `HH`, `HL`, and `CA` tables. These defaults are intended to
retain the most commonly used haul metadata, length-frequency data, and
biological sampling information.

The default columns can be inspected with
[`list_prune_datras_defaults()`](https://tokami.github.io/DATRASextra/reference/list_prune_datras_defaults.md).
The available columns in a specific object can be inspected with
[`list_prune_datras_available()`](https://tokami.github.io/DATRASextra/reference/list_prune_datras_available.md).

Column selection can be modified in three ways:

- `keep` replaces the default columns for the named table(s),

- `add` adds columns to the default or selected columns,

- `drop` removes columns from the default or selected columns.

Columns listed in `keep`, `add`, or `drop` for tables not present in `x`
are ignored. Requested columns that are not present in a table are
ignored, with an optional warning controlled by `warn_missing`.

## See also

[`list_prune_datras_defaults()`](https://tokami.github.io/DATRASextra/reference/list_prune_datras_defaults.md),
[`list_prune_datras_available()`](https://tokami.github.io/DATRASextra/reference/list_prune_datras_available.md),
[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md),
[`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Inspect default columns retained by prune_datras()
list_prune_datras_defaults()

## Inspect available columns in a specific object
list_prune_datras_available(x)

## Reduce a DATRAS object to the default core columns
x_small <- prune_datras(x)

## Keep defaults, but retain additional environmental variables in HH
x_small <- prune_datras(
  x,
  add = list(HH = c("SurTemp", "BotTemp", "SurSal", "BotSal"))
)

## Keep defaults, but remove selected columns
x_small <- prune_datras(
  x,
  drop = list(HH = c("Roundfish", "timeOfYear"),
              HL = "Count")
)

## Fully override the columns retained for HH
x_small <- prune_datras(
  x,
  keep = list(HH = c("Survey", "Year", "haul.id", "lon", "lat", "Depth"))
)
} # }
```
