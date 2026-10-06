# Convert a `datras_raw` object to a tibble

Method for
[`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html):
the same table as
[`as_table()`](https://tokami.github.io/DATRASextra/reference/as_table.md),
returned as a tibble, so that `as_tibble(x)` and `x |> as_tibble()` work
in tidyverse workflows. All arguments of
[`as_table()`](https://tokami.github.io/DATRASextra/reference/as_table.md)
are available, including `table` for the length (`HL`) and individual
(`CA`) data.

## Usage

``` r
# S3 method for class 'datras_raw'
as_tibble(
  x,
  ...,
  vars = .default_hh_vars,
  add_vars = NULL,
  remove_vars = NULL,
  type = "long",
  table = c("HH", "HL", "CA"),
  hl_by = c("Valid_Aphia", "LngtCm"),
  zeros = TRUE,
  ca_vars = .default_ca_vars
)
```

## Arguments

- x:

  A `datras_raw` object.

- ...:

  Passed to
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  for the converted table, e.g. `.name_repair`.

- vars:

  Character vector of `HH` variable names to include. Defaults to 15
  common haul-level columns: `Survey`, `Gear`, `Country`, `Ship`,
  `Year`, `Quarter`, `Month`, `Day`, `lon`, `lat`, `timeOfYear`,
  `abstime`, `DayNight`, `TimeShotHour`, `HaulDur`.

- add_vars:

  Character vector of additional `HH` variable names to append to
  `vars`. Applied after `remove_vars`.

- remove_vars:

  Character vector of variable names to drop from `vars`. Applied before
  `add_vars`.

- type:

  Character string specifying the output format: `"long"` (default) or
  `"wide"`. See Details for what each means per `table`.

- table:

  Character string naming the table to export: `"HH"` (default) for one
  row per haul, `"HL"` for numbers at length by haul and species, or
  `"CA"` for one row per individual record.

- hl_by:

  Character vector of `HL` columns that define a row for `table = "HL"`,
  in addition to the haul. Default `c("Valid_Aphia", "LngtCm")`: species
  x length class, summed over sex and catch category. Add `"Sex"` to
  keep sexes apart. Must contain `"Valid_Aphia"`.

- zeros:

  Logical. For `table = "HL"`: if `TRUE` (default), add a row with
  `Count = 0` for every haul in `HH` and species in `HL` without a
  record, so that averages over hauls include the hauls where a species
  was not caught.

- ca_vars:

  Character vector of `CA` columns to include for `table = "CA"`.
  Columns not found are omitted with a warning.

## Value

A tibble. See
[`as_table()`](https://tokami.github.io/DATRASextra/reference/as_table.md)
for the rows and columns of each `table` and `type`.

## Details

The method is registered when the tibble package is installed; tibble is
not required otherwise.

## See also

[`as_table()`](https://tokami.github.io/DATRASextra/reference/as_table.md),
[`as_long_format()`](https://tokami.github.io/DATRASextra/reference/as_long_format.md),
[`as_wide_format()`](https://tokami.github.io/DATRASextra/reference/as_wide_format.md)

## Examples

``` r
if (requireNamespace("tibble", quietly = TRUE)) {
  dab <- add_numbers_at_length(dab)
  dab <- add_total_numbers_by_haul(dab, length_cuts = c(0, 20, Inf))

  tibble::as_tibble(dab)
  tibble::as_tibble(dab, type = "wide", add_vars = "Depth")
  tibble::as_tibble(dab, table = "HL", vars = c("Year", "lon", "lat"))
}
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm
#> # A tibble: 25,596 × 8
#>    haul.id                    Year    lon   lat Valid_Aphia LngtCm Species Count
#>    <fct>                      <fct> <dbl> <dbl>       <dbl>  <dbl> <fct>   <dbl>
#>  1 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     12 Limand…  6.34
#>  2 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     13 Limand…  4.22
#>  3 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     14 Limand…  4.22
#>  4 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     15 Limand…  4.22
#>  5 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     16 Limand…  2.11
#>  6 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     17 Limand…  6.34
#>  7 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     18 Limand… 21.1 
#>  8 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     19 Limand… 21.1 
#>  9 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     20 Limand… 27.5 
#> 10 NS-IBTS:2020:1:DK:26D4:GO… 2020   7.14  56.6      127139     21 Limand… 21.1 
#> # ℹ 25,586 more rows
```
