# Remove the CA table from a `datras_raw` object

Set the `CA` (biological sampling) table of a `datras_raw` object to
`NULL`.

## Usage

``` r
drop_ca(x)
```

## Arguments

- x:

  A `datras_raw` object.

## Value

The input object with `CA` set to `NULL`.

## See also

[`drop_hl()`](https://tokami.github.io/DATRASextra/reference/drop_hl.md),
[`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x_no_ca <- drop_ca(x)
} # }
```
