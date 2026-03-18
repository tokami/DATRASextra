# Prune a `datras_raw` object following the FishGlob workflow

Reduce a `datras_raw` / `DATRASraw` object to the components and columns
needed for the FishGlob workflow.

## Usage

``` r
prune_fishglob(x)
```

## Arguments

- x:

  A `datras_raw` object.

## Value

A pruned `datras_raw` object following the FishGlob workflow.

## Details

This function removes the `CA` table entirely and retains only a
selected subset of columns in the `HH` and `HL` tables. It is mainly
intended to reduce memory use when preparing data in a format consistent
with the FishGlob data workflow.

The FishGlob workflow does not require the full DATRAS object. In
particular, the `CA` table is discarded and only a reduced set of
variables is kept from the `HH` and `HL` tables.

This can substantially reduce memory use when working with large survey
data sets.

## See also

[`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md),
[`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x_small <- prune_fishglob(x)
} # }
```
