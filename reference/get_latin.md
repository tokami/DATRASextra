# Get scientific names from WoRMS AphiaIDs

Retrieves scientific names for one or more WoRMS AphiaIDs. By default,
the function matches AphiaIDs against the internal `species_info` table.
Optionally, it can query WoRMS directly via the worrms package.

## Usage

``` r
get_latin(aphia, use_worrms = FALSE)
```

## Arguments

- aphia:

  A vector of WoRMS AphiaIDs.

- use_worrms:

  Logical; if `TRUE`, scientific names are retrieved using
  [`worrms::wm_id2name()`](https://docs.ropensci.org/worrms/reference/wm_id2name.html).
  If `FALSE` (default), AphiaIDs are matched against the internal
  `species_info` table.

## Value

If `use_worrms = FALSE`, a character vector of scientific names with the
same length and order as `x`. AphiaIDs not found in `species_info`
return `NA`, unless `x` has length 0, in which case an error is thrown.

If `use_worrms = TRUE`, the value returned by
[`worrms::wm_id2name()`](https://docs.ropensci.org/worrms/reference/wm_id2name.html),
which may differ in structure depending on the queried AphiaIDs and the
response from WoRMS.

## Details

Using the internal `species_info` table provides a fast offline lookup,
but only for AphiaIDs included in that table. Using `use_worrms = TRUE`
allows direct lookup from WoRMS, but requires the worrms package to be
installed and may depend on internet access.

## See also

[`worrms::wm_id2name()`](https://docs.ropensci.org/worrms/reference/wm_id2name.html)

## Examples

``` r
get_latin(126436)
#> [1] "Gadus morhua"

get_latin(c(126436, 126437))
#> [1] "Gadus morhua"             "Melanogrammus aeglefinus"

if (FALSE) { # \dontrun{
get_latin(126436, use_worrms = TRUE)
} # }
```
