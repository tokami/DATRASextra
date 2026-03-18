# Format a `datras_raw` object as a table

Convert a `datras_raw` / `DATRASraw` object to either long or wide
tabular format.

## Usage

``` r
as_table(x, type = "long", ...)
```

## Arguments

- x:

  A `datras_raw` object.

- type:

  Character string specifying the output format. Must be either `"long"`
  (default) or `"wide"`.

- ...:

  Additional arguments passed to
  [`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md)
  or
  [`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md).

## Value

A data frame in the requested format.

## Details

This is a convenience wrapper around
[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md)
and
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md).

If `type = "long"`, the object is converted using
[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md).
If `type = "wide"`, the object is converted using
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md).

## See also

[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md),
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Long-format table
tab_long <- as_table(x, type = "long")

## Wide-format table
tab_wide <- as_table(x, type = "wide")
} # }
```
