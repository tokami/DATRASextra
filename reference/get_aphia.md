# Get WoRMS AphiaIDs from species names

Retrieves WoRMS AphiaIDs for one or more scientific species names. By
default, the function matches names against the internal `species_info`
table. Optionally, it can query the worrms package to look up AphiaIDs
directly from WoRMS.

## Usage

``` r
get_aphia(species, use_worrms = FALSE)
```

## Arguments

- species:

  A character vector of scientific species names.

- use_worrms:

  Logical; if `TRUE`, AphiaIDs are retrieved using
  [`worrms::wm_name2id()`](https://docs.ropensci.org/worrms/reference/wm_name2id.html).
  If `FALSE` (default), names are matched against the internal
  `species_info` table.

## Value

If `use_worrms = FALSE`, an integer vector of WoRMS AphiaIDs with the
same length and order as `x`. Names not found in `species_info` return
`NA`.

If `use_worrms = TRUE`, the value returned by
[`worrms::wm_name2id()`](https://docs.ropensci.org/worrms/reference/wm_name2id.html),
which may differ in structure from the internal lookup result depending
on the queried names and the response from WoRMS.

## Details

Using the internal `species_info` table provides a fast offline lookup,
but only for names included in that table. Using `use_worrms = TRUE`
allows direct lookup from WoRMS, but requires the worrms package to be
installed and may depend on internet access.

## See also

[`worrms::wm_name2id()`](https://docs.ropensci.org/worrms/reference/wm_name2id.html)

## Examples

``` r
get_aphia("Gadus morhua")
#> [1] 126436

get_aphia(c("Gadus morhua", "Melanogrammus aeglefinus"))
#> [1] 126436 126437

if (FALSE) { # \dontrun{
get_aphia("Gadus morhua", use_worrms = TRUE)
} # }
```
