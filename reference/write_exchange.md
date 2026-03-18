# Write a `datras_raw` object to a DATRAS exchange zip file

Write the contents of a `datras_raw` / `DATRASraw` object to a temporary
CSV file in DATRAS exchange format and compress it into a zip archive.

## Usage

``` r
write_exchange(x, zip_file = "DATRAS.zip")
```

## Arguments

- x:

  A `datras_raw` object to be written.

- zip_file:

  Character string giving the path and name of the output zip file.
  Defaults to `"DATRAS.zip"`.

## Value

Invisibly returns the path to the created zip file.

## Details

The function writes the available DATRAS components in the order `HH`,
`HL`, and `CA`. For each component, the column names are written as a
header line, followed by the corresponding data rows.

The exchange file is first written to a temporary CSV file and then
zipped using [`utils::zip()`](https://rdrr.io/r/utils/zip.html). If
`zip_file` already exists, it is overwritten.

Empty or missing components among `HH`, `HL`, and `CA` are skipped.

## Examples

``` r
if (FALSE) { # \dontrun{
## Write a DATRAS object to a zip archive
write_exchange(x, "NS-IBTS_2020.zip")
} # }
```
