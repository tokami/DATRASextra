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

  Logical. If `FALSE` (default), surveys known to be test surveys or
  surveys with incomplete data are skipped. Set to `TRUE` to download
  them anyway.

- return_data:

  Logical. If `TRUE` (default), the function returns the downloaded data
  by running
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
  on the specified path.

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
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md).

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

The following surveys are currently treated as problematic or test
surveys: `"NS-IDPS"`, `"IS-IDPS"`, `"Test-DATRAS"`, and
`"NS-IBTS_UNIFtest"`.

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
