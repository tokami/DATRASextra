# Convert a `datras_raw` object to a long-format table

Create a long-format data frame from a `datras_raw` / `DATRASraw`
object, using `HH` as the main haul-level table and, when needed, adding
variables from `HL` matched by `haul.id`.

## Usage

``` r
as_long_format(
  x,
  vars = c("Survey", "Gear", "Country", "Ship", "Year", "Quarter", "Month", "Day", "lon",
    "lat", "timeOfYear", "abstime", "DayNight", "TimeShotHour", "HaulDur")
)
```

## Arguments

- x:

  A `datras_raw` object.

- vars:

  Character vector of variable names to include in the output. Variables
  found in `HH` are taken directly from `HH`. Variables not found in
  `HH` but present in `HL` are joined by `haul.id`. Defaults to a set of
  common haul-level variables.

## Value

A data frame in long format.

## Details

If species-level variables such as `Species` or `Valid_Aphia` are
requested, the output contains one row per haul-species combination.
Variables that are not found in either `HH` or `HL` are omitted with a
warning.

The function starts from the `HH` table and adds requested variables
from `HL` only when needed. If one or more requested variables come from
`HL`, the output is expanded to one row per unique `haul.id` and
combination of requested `HL` variables.

This is particularly useful for creating haul-species tables, for
example when requesting `Species` or `Valid_Aphia` together with
haul-level covariates such as year, quarter, gear, or position.

Variables requested in `vars` that are not present in either `HH` or
`HL` are ignored and reported with a warning.

## See also

[`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md),
[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Haul-level long table
tab <- as_long_format(x)

## Haul-species table
tab <- as_long_format(x, vars = c("Survey", "Year", "haul.id",
                                  "Species", "Valid_Aphia"))

## Request variables from both HH and HL
tab <- as_long_format(x, vars = c("Survey", "Gear", "Year",
                                  "Species", "Valid_Aphia"))
} # }
```
