# Prune a `datras_raw` object to core columns

Reduce a `datras_raw` / `DATRASraw` object to a smaller set of core
columns in the `HH`, `HL`, and `CA` tables.

## Usage

``` r
prune_datras(x, do_fishglob = FALSE)
```

## Arguments

- x:

  A `datras_raw` object.

- do_fishglob:

  Logical. If `TRUE`, apply
  [`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md)
  instead of the standard DATRAS pruning rules.

## Value

A pruned `datras_raw` object.

## Details

This is mainly intended to reduce memory use when working with large
DATRAS data sets.

If `do_fishglob = TRUE`, pruning is delegated to
[`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md).

For standard DATRAS data (`do_fishglob = FALSE`), the function keeps
only a predefined set of columns in each component:

- `CA`: age and individual-level biological information,

- `HH`: haul- and station-level metadata,

- `HL`: length-structured catch information.

Any columns not included in these predefined sets are removed.

## See also

[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md),
[`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Reduce a DATRAS object to core columns
x_small <- prune_datras(x)
} # }
```
