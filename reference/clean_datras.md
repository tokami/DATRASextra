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
  impute_missing_depth = TRUE,
  correct_species = TRUE,
  do_fishglob = FALSE
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

  Logical. If `TRUE` (default), missing haul depths are imputed using a
  smooth spatial GAM fitted to observed depths.

- correct_species:

  Logical. If `TRUE` (default), species information is corrected using
  [`correct_species()`](https://tokami.github.io/DATRASextra/reference/correct_species.md).

- do_fishglob:

  Logical. If `TRUE`, apply
  [`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md)
  instead of the standard DATRAS cleaning steps.

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
latitude.

Optional filtering by `aphias`, `years`, `quarters`, and `gears` is
applied after cleaning.

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
