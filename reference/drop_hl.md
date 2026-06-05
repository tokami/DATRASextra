# Remove the HL table from a `datras_raw` object

Set the `HL` (length-frequency) table of a `datras_raw` object to
`NULL`.

## Usage

``` r
drop_hl(x)
```

## Arguments

- x:

  A `datras_raw` object.

## Value

The input object with `HL` set to `NULL`.

## See also

[`drop_ca()`](https://tokami.github.io/DATRASextra/reference/drop_ca.md),
[`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x_no_hl <- drop_hl(x)
} # }
```
