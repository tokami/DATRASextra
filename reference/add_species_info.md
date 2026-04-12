# Add species information to CA and HL tables

Adds one or more columns from `species_info` to the `CA` and/or `HL`
elements of a DATRAS-like object by matching `Valid_Aphia` in the table
to `WoRMS_AphiaID` in `species_info`.

The function preserves the original row order of each table and performs
a left join, meaning that rows with no matching species information are
retained and receive `NA` in the added columns.

For this type of lookup, the function uses
[`base::match()`](https://rdrr.io/r/base/match.html), which is typically
faster and simpler than
[`base::merge()`](https://rdrr.io/r/base/merge.html) when only selected
columns need to be appended and the original row order should be kept.

## Usage

``` r
add_species_info(x, vars = NULL, verbose = TRUE)
```

## Arguments

- x:

  A DATRAS-like object containing at least optional `CA` and/or `HL`
  data frames.

- vars:

  Character vector giving the names of columns in `species_info` to add.
  If `NULL`, all columns except `WoRMS_AphiaID` are added.

- verbose:

  Logical; if `TRUE`, progress messages are printed.

## Value

The input object `x`, with the requested columns added to the `CA`
and/or `HL` elements where present.

## Details

The lookup is based on the correspondence between:

- `x[["CA"]][["Valid_Aphia"]]` or `x[["HL"]][["Valid_Aphia"]]`

- `species_info[["WoRMS_AphiaID"]]`

If any requested columns already exist in `CA` or `HL`, they are
overwritten.

## Examples

``` r
## Add all available species information
## x <- add_species_info(x)

## Add only selected columns
## x <- add_species_info(x, vars = c("ScientificName", "FishBase"))
```
