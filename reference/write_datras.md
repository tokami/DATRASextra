# Write a `datras_raw` object to a DATRAS exchange zip file

Write the contents of a `datras_raw` / `DATRASraw` object to a temporary
CSV file in DATRAS exchange format and compress it into a zip archive.

## Usage

``` r
write_datras(x, zip_file = "DATRAS.zip")
```

## Arguments

- x:

  A `datras_raw` object to be written.

- zip_file:

  Character string giving the path and name of the output zip file.
  Defaults to `"DATRAS.zip"`.

## Value

Invisibly returns the path to the created zip file, carrying the
attributes `payload_hash`, `zip_hash` and `algo`. The payload hash is
taken over the exchange file inside the archive and is therefore
identical whenever the data are identical; the archive hash is not,
because [`utils::zip()`](https://rdrr.io/r/utils/zip.html) stores the
modification time of the file it compresses. This is why
[`write_manifest()`](https://tokami.github.io/DATRASextra/reference/write_manifest.md)
records the payload hash.

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
write_datras(x, "NS-IBTS_2020.zip")
} # }
```
