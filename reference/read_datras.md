# Read ICES DATRAS survey data from zipped exchange files

Read one or more ICES DATRAS exchange files, or all zipped exchange
files in one or more directories, into a single `datras_raw` /
`DATRASraw` object.

## Usage

``` r
read_datras(
  paths,
  years = NULL,
  min_file_size = 10000,
  prune = FALSE,
  verbose = TRUE
)
```

## Arguments

- paths:

  A character vector of file paths or directory paths. Paths can point
  either to individual DATRAS `.zip` exchange files or to directories
  containing such files.

- years:

  Optional integer vector of years to read. When supplied and `paths`
  contains directories, only zip files matching those years are read.

- min_file_size:

  Minimum file size in bytes. Files smaller than this threshold are
  excluded because they are likely incomplete or invalid and may cause
  errors when being read. Defaults to `1e4`.

- prune:

  Logical. If `TRUE`, only core columns are retained using
  [`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md)
  before combining files. This can substantially reduce memory use when
  reading many files.

- verbose:

  Logical. If `TRUE` (default), progress messages are printed.

## Value

A combined DATRAS survey object with classes `datras_raw` and
`DATRASraw`.

## Details

The function can read:

- one or more individual `.zip` files,

- one or more directories containing `.zip` files,

- optionally only files matching selected years.

Small zip files can be excluded using `min_file_size`, as unusually
small files are often incomplete or corrupted and may fail in the
underlying DATRAS reader functions.

DATRAS zip archives are typically much larger than a few kilobytes, so
very small files are often suspicious and may represent failed downloads
or damaged archives.

Reading a large number of DATRAS files into R can require substantial
memory, especially when combining multiple surveys or many years.
Setting `prune = TRUE` can reduce memory use by removing non-essential
columns before merging files.

If you need a different set of retained columns than provided by
[`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md),
you may wish to apply your own pruning function after reading or adapt
the pruning code.

## See also

[`download_datras()`](https://tokami.github.io/DATRASextra/reference/download_datras.md),
[`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Read all zip files from a survey folder
x <- read_datras("data/NS-IBTS")

## Read selected years from a folder
x <- read_datras("data/NS-IBTS", years = 2018:2020)

## Read multiple zip files directly
files <- c("data/NS-IBTS/NS-IBTS_2020.zip",
           "data/NS-IBTS/NS-IBTS_2021.zip")
x <- read_datras(files)

## Read and prune to reduce memory use
x <- read_datras("data/NS-IBTS", prune = TRUE)
} # }
```
