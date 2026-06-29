# Read ICES DATRAS survey data from zipped exchange files

Read one or more ICES DATRAS exchange files, or all zipped exchange
files in one or more directories, into a single `datras_raw` /
`DATRASraw` object.

## Usage

``` r
read_datras(
  path,
  surveys = NULL,
  years = NULL,
  recursive = TRUE,
  min_file_size = 10000,
  prune = FALSE,
  drop_hl = FALSE,
  drop_ca = FALSE,
  verbose = TRUE,
  ncores = 1
)
```

## Arguments

- path:

  A character vector of file or directory paths. Each element can point
  either to an individual DATRAS `.zip` exchange file or to a directory
  containing such files.

- surveys:

  Optional character vector of survey acronyms to read (e.g.
  `c("NS-IBTS", "BITS")`). When supplied and `path` contains
  directories, only zip files whose **immediate parent folder name**
  exactly matches one of the specified strings are read. This avoids
  false matches between similarly named folders (e.g. `"NS-IBTS"` will
  not match `"NS-IBTS_old"`). Matching is case-sensitive.

- years:

  Optional integer vector of years to read. When supplied and `path`
  contains directories, only zip files matching those years are read.

- recursive:

  logical. Should the listing recurse into directories? (Default:
  `TRUE`).

- min_file_size:

  Minimum file size in bytes. Files smaller than this threshold are
  excluded because they are likely incomplete or invalid and may cause
  errors when being read. Defaults to `1e4`.

- prune:

  Logical. If `TRUE`, only core columns are retained using
  [`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md)
  before combining files. This can substantially reduce memory use when
  reading many files.

- drop_hl:

  Logical. If `TRUE`, the `HL` (length-frequency) table is set to `NULL`
  after reading each file. Use this when only haul metadata is needed,
  as `HL` is often the largest table. Can be combined with `prune`.

- drop_ca:

  Logical. If `TRUE`, the `CA` (biological sampling) table is set to
  `NULL` after reading each file. Can be combined with `prune` and
  `drop_hl`.

- verbose:

  Logical. If `TRUE` (default), progress messages are printed.

- ncores:

  Integer. Number of parallel workers to use when reading zip files.
  Defaults to `1` (sequential). Values greater than 1 use
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) and
  are only effective on non-Windows systems.

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
memory, especially when combining multiple surveys or many years. The
following options can substantially reduce peak memory use:

- `drop_hl = TRUE` drops the length-frequency table (`HL`) immediately
  after each file is read. `HL` is typically the largest table and can
  be omitted when only haul-level metadata is needed.

- `drop_ca = TRUE` drops the biological sampling table (`CA`) in the
  same way.

- `prune = TRUE` trims all three tables to a compact set of core
  columns. Can be combined with `drop_hl` / `drop_ca`.

When loading a very large database (many surveys, many years) in a
single call still exceeds available memory even after using the options
above, consider loading in parts and combining with
[`c()`](https://rdrr.io/r/base/c.html):

    x1 <- read_datras("~/data/DATRAS", surveys = c("NS-IBTS", "BITS"),
                      drop_ca = TRUE)
    x2 <- read_datras("~/data/DATRAS", surveys = c("EVHOE", "IBTS-MED"),
                      drop_ca = TRUE)
    x_all <- c(x1, x2)
    rm(x1, x2)

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

## Read selected surveys from a folder containing the whole database
x <- read_datras("data/DATRAS", surveys = c("NS-IBTS", "BITS"))

## Combine survey and year filtering
x <- read_datras("data/DATRAS", surveys = "NS-IBTS", years = 2018:2020)

## Read multiple zip files directly
files <- c("data/NS-IBTS/NS-IBTS_2020.zip",
           "data/NS-IBTS/NS-IBTS_2021.zip")
x <- read_datras(path = files)

## Read and prune to reduce memory use
x <- read_datras("data/NS-IBTS", prune = TRUE)

## Load only haul metadata (HH) -- drop HL and CA to minimise memory use
x <- read_datras("data/DATRAS", drop_hl = TRUE, drop_ca = TRUE)

## Prune columns and also drop the CA table
x <- read_datras("data/NS-IBTS", prune = TRUE, drop_ca = TRUE)
} # }
```
