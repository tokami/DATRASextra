# Read the manifest of a DATRAS archive

Read the manifest of a DATRAS archive

## Usage

``` r
read_manifest(path, file = "DATRAS_manifest.csv")
```

## Arguments

- path:

  Character string giving the root directory of the archive.

- file:

  Character string giving the name of the manifest file, relative to
  `path`. Defaults to `"DATRAS_manifest.csv"`.

## Value

A data frame with one row per survey, year and quarter. A zero-row data
frame with the same columns is returned when no manifest is present.

## See also

[`write_manifest()`](https://tokami.github.io/DATRASextra/reference/write_manifest.md),
[`verify_extraction()`](https://tokami.github.io/DATRASextra/reference/verify_extraction.md)

## Examples

``` r
if (FALSE) { # \dontrun{
read_manifest("data/datras")
} # }
```
