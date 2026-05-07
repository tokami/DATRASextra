# Plot species composition by length group

Shows the contribution of each species in `x[["HL"]]` to the total
numbers (`HaulN`) and/or total weight (`HaulWgt`) already computed in
`x[["HH"]]`. Length groups are taken directly from the column names of
`HaulN`/`HaulWgt`; if those matrices have only one column (or are plain
vectors), a single stacked bar is drawn.

Numbers are aggregated from `HL$Count`. Weights are estimated from `HL`
using length-weight parameters from the internal `species_info` table;
species without parameters contribute 0 g with a warning.

## Usage

``` r
plot_species_composition(
  x,
  what = c("N", "Wgt", "both", "legend"),
  beside = TRUE,
  col = NULL,
  main = NULL,
  max_species = 8L,
  do_legend = TRUE,
  legend_ncol = 1L
)
```

## Arguments

- x:

  A `datras_raw` object. `HH` must contain `HaulN` and/or `HaulWgt`
  (produced by
  [`add_total_numbers_by_haul`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
  and
  [`add_total_weight_by_haul`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)).

- what:

  Character; which quantity to plot: `"N"`, `"Wgt"`, or `"both"`.

- beside:

  Logical. If `TRUE` (default), species bars are stacked within each
  length group. If `TRUE`, bars are placed side by side.

- col:

  Optional colour vector — one colour per species (after collapsing to
  `max_species`). The palette cycles if too short.

- main:

  Optional plot title.

- max_species:

  Maximum number of species to show individually. Species beyond this
  ranked by total count are collapsed into an `"Other"` category.

- legend_ncol:

  Number of columns in the species legend.

## Value

Invisibly returns a named list with elements `N` and/or `Wgt`: matrices
of aggregated values with rows = species and columns = length groups.

## Examples

``` r
if (FALSE) { # \dontrun{
dat <- add_numbers_at_length(mini)
dat <- add_weight_at_length(dat)
dat <- add_total_numbers_by_haul(dat, length_cuts = c(0, 20, 35, Inf))
dat <- add_total_weight_by_haul(dat, length_cuts = c(0, 20, 35, Inf))

plot_species_composition(dat)
plot_species_composition(dat, what = "both")
plot_species_composition(dat, beside = FALSE)
} # }
```
