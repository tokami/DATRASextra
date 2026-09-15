# Write a manifest for an archive of DATRAS exchange files

Scan a directory of zipped DATRAS exchange files, compute a checksum for
each, read the ICES calculation date from each, and write the result to
`DATRAS_manifest.csv` in the root of the archive.

## Usage

``` r
write_manifest(
  path,
  recursive = TRUE,
  file = "DATRAS_manifest.csv",
  verbose = TRUE
)
```

## Arguments

- path:

  Character string giving the root directory of the archive.

- recursive:

  Logical. If `TRUE` (default), search subdirectories. A standard
  archive written by
  [`download_datras()`](https://tokami.github.io/DATRASextra/reference/download_datras.md)
  stores files in survey-specific subdirectories.

- file:

  Character string giving the name of the manifest file, relative to
  `path`. Defaults to `"DATRAS_manifest.csv"`.

- verbose:

  Logical. If `TRUE` (default), show a progress bar.

## Value

The manifest, invisibly, as a data frame with one row per survey, year
and quarter.

## Details

The manifest makes a local snapshot verifiable: two users can confirm
that they hold identical data without anyone hosting anything, and a
later comparison shows which survey-year files ICES has revised since
the archive was created.

The checksum is computed over the *contents* of the exchange file inside
the zip archive, not over the zip archive itself. Zip archives embed the
modification time of the file they contain, so re-writing identical data
produces a different zip archive but the same payload checksum. The
checksum of the zip archive is recorded as well, as a check on file
transfer.

SHA-256 is used where available and MD5 otherwise; the algorithm used is
recorded in the `algo` column so that manifests remain self-describing.

Scanning is not free, since each file must be decompressed and read.
Expect on the order of a minute for a complete DATRAS archive of around
650 files.

## See also

[`read_manifest()`](https://tokami.github.io/DATRASextra/reference/read_manifest.md),
[`verify_extraction()`](https://tokami.github.io/DATRASextra/reference/verify_extraction.md),
[`extraction()`](https://tokami.github.io/DATRASextra/reference/extraction.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Create a manifest for an existing archive
write_manifest("data/datras")
} # }
```
