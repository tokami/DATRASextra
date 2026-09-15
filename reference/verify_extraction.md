# Verify a DATRAS archive against its manifest

Recompute the checksum of every exchange file in an archive and compare
it with the manifest, reporting files that have changed, are missing, or
are not listed.

## Usage

``` r
verify_extraction(path, manifest = NULL, recursive = TRUE, verbose = TRUE)
```

## Arguments

- path:

  Character string giving the root directory of the archive.

- manifest:

  Optional manifest to compare against, as returned by
  [`read_manifest()`](https://tokami.github.io/DATRASextra/reference/read_manifest.md).
  If `NULL` (default), the manifest stored in `path` is used.

- recursive:

  Logical. If `TRUE` (default), search subdirectories.

- verbose:

  Logical. If `TRUE` (default), print a summary and show a progress bar.

## Value

A data frame, invisibly, with one row per file and a `status` column
taking the values `"ok"`, `"changed"`, `"revised"`, `"missing"` or
`"new"`.

## Details

Two kinds of difference are distinguished, because they have different
causes and different remedies:

- a changed `payload_hash` with an unchanged `date_of_calculation`
  indicates a local problem, such as a corrupted or partially
  transferred file,

- a changed `date_of_calculation` indicates that ICES has revised the
  data upstream. This is the case that silently changes results and is
  the reason the manifest is worth keeping.

## See also

[`write_manifest()`](https://tokami.github.io/DATRASextra/reference/write_manifest.md),
[`read_manifest()`](https://tokami.github.io/DATRASextra/reference/read_manifest.md),
[`extraction()`](https://tokami.github.io/DATRASextra/reference/extraction.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Check that an archive still matches its manifest
verify_extraction("data/datras")
} # }
```
