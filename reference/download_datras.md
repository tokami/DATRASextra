# Download ICES DATRAS survey data

Download ICES DATRAS survey data for one or more surveys and years, and
save each survey-year combination as a zipped exchange file in a
survey-specific subdirectory.

## Usage

``` r
download_datras(
  path = NULL,
  surveys = NULL,
  years = NULL,
  overwrite = FALSE,
  download_hl = TRUE,
  download_ca = TRUE,
  use_php = FALSE,
  include_flagged = FALSE,
  return_data = TRUE,
  strict = TRUE,
  verbose = TRUE,
  timeout = 10,
  ...
)
```

## Arguments

- path:

  Character string giving the directory where downloaded files should be
  stored. Survey-specific subdirectories are created within this
  directory. If `NULL`, the current working directory is used.

- surveys:

  A character vector of DATRAS survey names to download, for example
  `"NS-IBTS"` or `"BITS"`. If `NULL`, all available surveys are used.

- years:

  An integer vector of years to download. If `NULL`, all available years
  for each selected survey are used.

- overwrite:

  Logical. If `FALSE` (default), survey-year files that already exist in
  `path` are skipped. Set to `TRUE` to re-download and overwrite
  existing files.

- download_hl:

  Logical. If `TRUE` (default), length-frequency data are also
  downloaded where available. This option is only used when
  `use_php = FALSE`.

- download_ca:

  Logical. If `TRUE` (default), age-length keys and age data are also
  downloaded where available. This option is only used when
  `use_php = FALSE`.

- use_php:

  Logical. If `FALSE` (default), data are downloaded via
  [`DATRAS::getDatrasExchange()`](https://rdrr.io/pkg/DATRAS/man/getDatrasExchange.html).
  If `TRUE`, the legacy
  [`DATRAS::downloadExchange()`](https://rdrr.io/pkg/DATRAS/man/downloadExchange.html)
  method is used.

- include_flagged:

  Logical. If `FALSE` (default), known test surveys are skipped when the
  survey list is taken from the server. Set to `TRUE` to download them
  anyway.

- return_data:

  Logical. If `TRUE` (default), the function returns the downloaded data
  by running
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
  on the specified path.

- strict:

  Logical. Passed to
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
  when `return_data = TRUE`, and ignored otherwise. Controls how records
  in `CA` without a haul identifier are matched back to a haul: if
  `TRUE` (default), a record matching several candidate hauls is left as
  `NA`; if `FALSE`, it is assigned one of them at random. It does not
  affect the files written to disk, which always hold the exchange data
  as delivered by ICES.

- verbose:

  Logical. If `TRUE` (default), progress messages are printed.

- timeout:

  Numeric. Maximum number of seconds to wait for the ICES DATRAS server
  to respond when retrieving the list of available surveys or years. If
  the server does not respond within this time (e.g. because a firewall
  blocks the connection), the function falls back to locally cached
  information. Default is 10 seconds.

- ...:

  Additional arguments for the function
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md),
  used when `return_data = TRUE`. The most useful ones control how much
  is held in memory: `prune = TRUE` drops non-essential columns,
  `drop_hl = TRUE` and `drop_ca = TRUE` omit the length-frequency and
  biological tables from the returned object, and `ncores` sets the
  number of workers used to read the files. None of them affect what is
  written to disk. See
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
  for the full list.

## Value

Invisibly returns `NULL`.

## Details

If `surveys` is `NULL`, all available surveys returned by
[`icesDatras::getSurveyList()`](https://rdrr.io/pkg/icesDatras/man/getSurveyList.html)
are used. If `years` is `NULL`, all available years for each selected
survey are downloaded.

By default, data are downloaded using
[`DATRAS::getDatrasExchange()`](https://rdrr.io/pkg/DATRAS/man/getDatrasExchange.html),
cleaned to remove extra variables, and written to disk with
[`write_datras()`](https://tokami.github.io/DATRASextra/reference/write_datras.md).
Alternatively, the legacy PHP-based download route from
[`DATRAS::downloadExchange()`](https://rdrr.io/pkg/DATRAS/man/downloadExchange.html)
can be used by setting `use_php = TRUE`.

Files are saved as zipped exchange files named `"<survey>_<year>.zip"`
inside survey-specific subfolders.

The following surveys are treated as test surveys and are skipped unless
`include_flagged = TRUE`: `"Test-DATRAS"` and `"NS-IBTS_UNIFtest"`. The
filter applies only when `surveys` is `NULL`, i.e. when the survey list
is taken from the DATRAS server; a survey named explicitly is always
downloaded.

Each downloaded survey-year is recorded in an archive manifest,
`DATRAS_manifest.csv`, written in the root of `path`. The manifest holds
the extraction date, the checksum of each exchange file, the ICES
calculation date of the records it contains, and the package versions
used, so that a snapshot can later be verified with
[`verify_extraction()`](https://tokami.github.io/DATRASextra/reference/verify_extraction.md)
and so that data read from the archive can report where they came from.
Existing manifest entries for the same survey, year and quarter are
replaced.

Downloading a large part of the database and returning it in one call
can exhaust memory, because every survey-year is read back into a single
object. Either set `return_data = FALSE` and read the archive in pieces
afterwards, or pass the memory-reducing arguments of
[`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
through `...`, for example `prune = TRUE` and `drop_ca = TRUE`.

No manifest entries are written when `use_php = TRUE`, because
[`DATRAS::downloadExchange()`](https://rdrr.io/pkg/DATRAS/man/downloadExchange.html)
writes the files through an external script and reports nothing about
what it retrieved. Run
[`write_manifest()`](https://tokami.github.io/DATRASextra/reference/write_manifest.md)
on the directory afterwards to describe such an archive.

## See also

[`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md),
[`write_manifest()`](https://tokami.github.io/DATRASextra/reference/write_manifest.md),
[`verify_extraction()`](https://tokami.github.io/DATRASextra/reference/verify_extraction.md),
[`extraction()`](https://tokami.github.io/DATRASextra/reference/extraction.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Download all available years for one survey into the current directory
dat <- download_datras(surveys = "NS-IBTS")

## Download selected years for multiple surveys
dat <- download_datras(
  surveys = c("NS-IBTS", "BITS"),
  years = 2010:2012,
  path = "data/datras"
)

## Re-download existing files
dat <- download_datras(
  surveys = "NS-IBTS",
  years = 2020,
  overwrite = TRUE
)
} # }
```
