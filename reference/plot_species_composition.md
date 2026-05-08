# Plot species composition by length group

Shows the contribution of each species in `x[["HL"]]` to total numbers
and/or total weight by length group. Length groups are taken from the
column names of `x[["HH"]][["HaulN"]]` or `x[["HH"]][["HaulWgt"]]`. If
these objects have only one column, or are plain vectors, a single
length group representing all lengths is used.

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

  A `datras_raw` object. `HH` must contain `HaulN` and/or `HaulWgt`, as
  produced by
  [`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
  and/or
  [`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md).

- what:

  Character; which quantity to plot. One of `"N"`, `"Wgt"`, `"both"`, or
  `"legend"`. The latter draws only the species legend.

- beside:

  Logical; passed to
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html). If
  `FALSE`, species are stacked within each length group. If `TRUE`,
  species are shown side by side within each length group.

- col:

  Optional colour vector, recycled to the number of displayed species
  after collapsing rare species to `"Other"`.

- main:

  Optional plot title.

- max_species:

  Integer; maximum number of species to show individually. Additional
  species, ranked by total count, are collapsed into `"Other"`.

- do_legend:

  Logical; if `TRUE`, draw the species legend.

- legend_ncol:

  Integer; number of columns to use in the legend.

## Value

Invisibly returns a named list with elements `N` and `Wgt`. Each element
is a matrix of aggregated values with rows representing species and
columns representing length groups. `Wgt` is `NULL` unless
`what = "Wgt"` or `what = "both"`.

## Details

Numbers are aggregated from `HL$Count`. Weights are estimated from `HL`
using length-weight parameters from the internal `species_info` table.
Species without available length-weight parameters contribute zero
weight and trigger a warning.

If `what = "both"` but only one of `HaulN` or `HaulWgt` is available,
the function falls back to plotting the available quantity and issues a
message.

## Examples

``` r
if (FALSE) { # \dontrun{
dat <- add_numbers_at_length(mini)
dat <- add_weight_at_length(dat)
dat <- add_total_numbers_by_haul(dat, length_cuts = c(0, 20, 35, Inf))
dat <- add_total_weight_by_haul(dat, length_cuts = c(0, 20, 35, Inf))

## Numbers only
plot_species_composition(dat)

## Numbers and weight panels
plot_species_composition(dat, what = "both")

## Stacked bars instead of side-by-side bars
plot_species_composition(dat, beside = FALSE)

## Suppress legend
plot_species_composition(dat, do_legend = FALSE)

## Draw legend only
plot_species_composition(dat, what = "legend", legend_ncol = 2)
} # }
```
