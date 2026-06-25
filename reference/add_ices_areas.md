# Add ICES area information to a `datras_raw` object

Appends ICES area columns to the `HH` table of a `datras_raw` object by
matching `HH$StatRec` (ICES statistical rectangle codes, e.g. `"39F0"`)
against an internal lookup table derived from the official ICES
shapefiles.

The lookup is purely table-based and requires no spatial packages at
runtime.

## Usage

``` r
add_ices_areas(
  x,
  vars = c("Area_Full", "Area_27", "Ecoregion"),
  verbose = TRUE
)
```

## Arguments

- x:

  A `datras_raw` object with a `StatRec` column in `HH`.

- vars:

  Character vector naming which area columns to add. Allowed values are
  any subset of `"Area_Full"`, `"Area_27"`, `"SubArea"`, `"Division"`,
  `"SubDivisio"`, `"Ecoregion"`. Defaults to
  `c("Area_Full", "Area_27", "Ecoregion")`.

- verbose:

  Logical; if `TRUE` (default), prints a message summarising how many
  hauls were matched.

## Value

The input object `x` with the requested columns added (or overwritten)
in `HH`.

## Details

The function matches on the `StatRec` column of `HH`. Hauls whose
`StatRec` code is not found in the lookup table (e.g. for surveys
outside the ICES area) receive `NA` in the added columns.

If a requested column already exists in `HH`, it is overwritten.

## See also

[`add_species_info()`](https://tokami.github.io/DATRASextra/reference/add_species_info.md)

## Examples

``` r
## Add default columns (Area_Full, Area_27, Ecoregion)
dab2 <- add_ices_areas(dab)
#> Matched 2651 of 2651 hauls to ICES areas.
head(dab2$HH[, c("StatRec", "Area_Full", "Area_27", "Ecoregion")])
#>   StatRec Area_Full Area_27         Ecoregion
#> 1    47F3    27.4.a     4.a Greater North Sea
#> 2    48F3    27.4.a     4.a Greater North Sea
#> 3    46F2    27.4.a     4.a Greater North Sea
#> 4    45F2    27.4.a     4.a Greater North Sea
#> 5    45F3    27.4.a     4.a Greater North Sea
#> 6    46F3    27.4.a     4.a Greater North Sea

## Add only Area_27
dab3 <- add_ices_areas(dab, vars = "Area_27")
#> Matched 2651 of 2651 hauls to ICES areas.
```
