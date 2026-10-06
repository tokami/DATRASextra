# Clean a `datras_raw` object

Apply standard cleaning steps to a `datras_raw` / `DATRASraw` object.

## Usage

``` r
clean_datras(
  x,
  aphias = NULL,
  years = NULL,
  quarters = NULL,
  gears = NULL,
  impute_missing_depth = FALSE,
  correct_species = TRUE,
  do_fishglob = FALSE,
  verbose = TRUE,
  explain_codes = FALSE,
  drop_without_hl = FALSE
)
```

## Arguments

- x:

  A `datras_raw` object.

- aphias:

  Optional numeric or character vector of Aphia IDs (`Valid_Aphia`) to
  retain.

- years:

  Optional integer vector of years to retain.

- quarters:

  Optional integer vector of quarters to retain.

- gears:

  Optional character vector of gear codes to retain.

- impute_missing_depth:

  Logical. If `TRUE`, missing haul depths are imputed using a smooth
  spatial GAM fitted to observed depths. Default: `FALSE`.

- correct_species:

  Logical. If `TRUE` (default), species information is corrected using
  [`correct_species()`](https://tokami.github.io/DATRASextra/reference/correct_species.md).

- do_fishglob:

  Logical. If `TRUE`, apply
  [`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md)
  instead of the standard DATRAS cleaning steps.

- verbose:

  Logical. If `TRUE` (default), print a summary of `HaulVal` and
  `StdSpecRecCode` category counts and the number of hauls with missing
  `Depth` before cleaning. Ignored when `do_fishglob = TRUE`.

- explain_codes:

  Logical. If `TRUE`, include a description of each `HaulVal`,
  `StdSpecRecCode`, and `BySpecRecCode` code in the printed summary.
  Default: `FALSE`. Only used when `verbose = TRUE`.

- drop_without_hl:

  Logical. If `TRUE`, remove survey-year-quarters that have hauls but no
  length data (`HL`) at all. Default: `FALSE`, which only reports them
  when `verbose = TRUE`. See Details.

## Value

A cleaned `datras_raw` object.

## Details

For standard DATRAS data, the function removes invalid hauls, keeps only
records with complete standard-species recording, optionally imputes
missing haul depths, optionally corrects species information, and can
subset the data by species, year, quarter, or gear.

If `do_fishglob = TRUE`, cleaning is delegated to
[`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md).

For standard DATRAS data (`do_fishglob = FALSE`), the following filters
are applied before any optional subsetting:

- only hauls with `HaulVal %in% c("V", "N")` are retained,

- only records with `StdSpecRecCode == 1` are retained.

If `impute_missing_depth = TRUE`, missing `Depth` values are predicted
from a GAM of `log(Depth)` on a two-dimensional smooth of longitude and
latitude. Note that this requires the R package mgcv to be installed.

Optional filtering by `aphias`, `years`, `quarters`, and `gears` is
applied after cleaning.

A haul without records in `HL` is treated as an empty haul (zero catch)
by later steps such as
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md).
That is correct for a single haul, but when a whole survey-year-quarter
has hauls and no `HL` records, its length data are missing rather than
zero. DATRAS holds a few such cases, for example test entries (see
<https://github.com/ices-tools-prod/icesDatras/issues/59>), and they
would enter an analysis as hauls without any catch. `clean_datras()`
checks for them before any other step and lists them;
`drop_without_hl = TRUE` removes them together with their `CA` records.
The check needs the complete `HL` table: it is skipped when there is no
`HL` table, either because it was dropped (e.g.
`read_datras(drop_hl = TRUE)`) or because none of the data read has
length records. When `HL` has already been subset to some species, a
survey-year-quarter where none of them was caught looks the same as one
without length data. Use the `aphias` argument, which is applied after
the check, to select species instead.

## See also

[`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md),
[`correct_species()`](https://tokami.github.io/DATRASextra/reference/correct_species.md),
[`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Basic cleaning
x_clean <- clean_datras(x)

## Restrict to selected years and quarters
x_clean <- clean_datras(x, years = 2018:2020, quarters = c(1, 3))

## Keep only selected species
x_clean <- clean_datras(x, aphias = c(126417, 126436))
} # }
```
