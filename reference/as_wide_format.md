# Convert a `datras_raw` object to a wide-format table

Create a wide-format data frame from a `datras_raw` / `DATRASraw`
object, using `HH` as the main haul-level table and spreading selected
`HL` variables into species-specific columns.

## Usage

``` r
as_wide_format(
  x,
  vars_hh = c("Survey", "Gear", "Country", "Ship", "Year", "Quarter", "Month", "Day",
    "lon", "lat", "timeOfYear", "abstime", "DayNight", "TimeShotHour", "HaulDur"),
  vars_hl = "Count",
  species_var = "Species",
  id_var = "haul.id",
  sep = "__",
  fill = 0,
  sanitize_names = TRUE,
  verbose = TRUE
)
```

## Arguments

- x:

  A `datras_raw` object.

- vars_hh:

  Character vector of haul-level variables to keep from `HH`.

- vars_hl:

  Character vector of variables from `HL` to spread wide across species.
  Defaults to `"Count"`.

- species_var:

  Character scalar giving the `HL` variable that defines the
  species-specific column names. Defaults to `"Species"`. Can also be
  set to `"Valid_Aphia"` or another grouping variable present in `HL`.

- id_var:

  Character scalar giving the haul identifier variable used to match
  `HH` and `HL`. Defaults to `"haul.id"`.

- sep:

  Character scalar used to separate the `HL` variable name from the
  species name in wide column names. Defaults to `"__"`.

- fill:

  Value used to replace missing values in the wide `HL` columns.
  Defaults to `0`.

- sanitize_names:

  Logical. If `TRUE` (default), species names used in wide column names
  are converted to lower case and non-alphanumeric characters are
  replaced with underscores.

- verbose:

  Logical. If `TRUE` (default), warnings are issued for requested
  variables that are not found.

## Value

A data frame in wide format with one row per haul.

## Details

The output contains one row per haul. Requested haul-level variables
from `HH` are kept as ordinary columns, while requested variables from
`HL` are expanded into columns of the form `"<variable><sep><species>"`.

The function starts from the `HH` table and adds requested variables
from `HL` after aggregating them to unique `haul.id` x `species_var`
combinations.

Numeric `HL` variables are summed within haul-species combinations
before reshaping wide. Non-numeric variables are reduced by taking the
first non-missing value.

Variables requested in `vars_hh` or `vars_hl` that are not found in the
relevant table are omitted and reported with a warning.

## See also

[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## One row per haul, species-specific count columns
tab <- as_wide_format(x)

## Add more HL variables
tab <- as_wide_format(
  x,
  vars_hl = c("Count", "CatCatchWgt")
)

## Use Aphia IDs instead of species names in column names
tab <- as_wide_format(
  x,
  vars_hl = c("Count"),
  species_var = "Valid_Aphia"
)
} # }
```
