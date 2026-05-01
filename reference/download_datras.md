# Download ICES DATRAS survey data

Download ICES DATRAS survey data for one or more surveys and years, and
save each survey-year combination as a zipped exchange file in a
survey-specific subdirectory.

## Usage

``` r
download_datras(
  surveys = NULL,
  years = NULL,
  download_missing_only = TRUE,
  download_hl = TRUE,
  download_ca = TRUE,
  use_php = FALSE,
  dir = NULL,
  force = FALSE,
  return_data = TRUE,
  verbose = TRUE,
  ...
)
```

## Arguments

- surveys:

  A character vector of DATRAS survey names to download, for example
  `"NS-IBTS"` or `"BITS"`. If `NULL`, all available surveys are used.

- years:

  An integer vector of years to download. If `NULL`, all available years
  for each selected survey are used.

- download_missing_only:

  Logical. If `TRUE` (default), only survey-year files that do not
  already exist in `dir` are downloaded.

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

- dir:

  Character string giving the directory where downloaded files should be
  stored. Survey-specific subdirectories are created within this
  directory. If `NULL`, the current working directory is used.

- force:

  Logical. If `FALSE` (default), surveys known to be test surveys or
  surveys with incomplete data may be skipped. If `TRUE`, they are also
  downloaded.

- return_data:

  Logical. If `TRUE` (default), the function returns the downloaded data
  by running
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
  on the specified path.

- verbose:

  Logical. If `TRUE` (default), progress messages are printed.

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
[`write_exchange()`](https://tokami.github.io/DATRASextra/reference/write_exchange.md).
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
  dir = "data/datras"
)

## Re-download existing files
dat <- download_datras(
  surveys = "NS-IBTS",
  years = 2020,
  download_missing_only = FALSE
)
} # }
```
