# Design-based stratified mean abundance or biomass index

Computes a design-based stratified mean index from a `datras_raw` object
using pre-computed per-haul totals (`HaulN` or `HaulWgt`) stored in
`HH`. When the value column is a matrix (e.g. numbers split into length
groups by
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)),
a separate index and confidence interval are returned for each column.

## Usage

``` r
calc_stratified_index(
  x,
  value_var = "HaulN",
  strata_var = "StatRec",
  cpue_method = c("per_swept_area", "per_hour", "count"),
  by = "Year",
  stratum_areas = NULL,
  confidence_level = 0.95
)
```

## Arguments

- x:

  A `datras_raw` object whose `HH` table contains `value_var`.

- value_var:

  Name of the `HH` column containing per-haul values. Default `"HaulN"`
  (total numbers per haul, added by
  [`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)).
  Use `"HaulWgt"` for a biomass index. The column may be a numeric
  vector (single group) or a matrix (one column per length group); in
  the latter case one index is computed per column.

- strata_var:

  Character vector naming one or more `HH` columns that define strata.
  Default `"StatRec"` (ICES statistical rectangles).

- cpue_method:

  Standardisation method applied to `value_var`: `"per_swept_area"` (per
  km^2 swept; requires `SweptArea` from
  [`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md)),
  `"per_hour"` (per hour; uses `HaulDur`), or `"count"` (no
  standardisation, raw totals per haul).

- by:

  Character vector of `HH` column names for which separate indices are
  computed (e.g. `"Year"`, `c("Year", "Quarter")`). Use `NULL` for a
  single overall index.

- stratum_areas:

  Optional data frame with columns matching `strata_var` and a numeric
  `Area` column. If `NULL` (default) all strata are weighted equally.

- confidence_level:

  Numeric; coverage probability for the confidence interval. Default
  `0.95`.

## Value

A data frame with one row per `by`-group x length-group combination and
columns: the `by` columns (if any), `group` (column name from the value
matrix, or `value_var` when the column is a vector), `cpue_method`,
`n_hauls`, `n_strata`, `index`, `se`, `cv`, `ci_lower`, `ci_upper`.

## Details

The function assumes
[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md)
has been applied beforehand and that `value_var` is already present in
`HH` (e.g. via
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
or
[`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)).
Hauls where `value_var` is `NA` or non-finite after CPUE standardisation
are excluded.

The stratified index is: \$\$\hat{Y} = \frac{\sum_h A_h
\bar{y}\_h}{\sum_h A_h}\$\$ with design-based variance
\$\$\widehat{\mathrm{Var}}(\hat{Y}) = \frac{\sum_h A_h^2\\ s_h^2 /
n_h}{(\sum_h A_h)^2}\$\$ summed over strata with \\n_h \ge 2\\. Strata
with a single haul contribute to the index but not to the variance; a
warning is issued when this occurs. Confidence intervals use a
t-distribution with degrees of freedom equal to the number of multi-haul
strata minus one.

## See also

[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md),
[`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md),
[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data(dab)
dab <- add_swept_area(dab)
dab <- add_total_numbers_by_haul(dab)
calc_stratified_index(dab, cpue_method = "per_swept_area", by = "Year")

# length-group indices
dab <- add_total_numbers_by_haul(dab, length_cuts = c(15, 25))
calc_stratified_index(dab, cpue_method = "per_swept_area", by = "Year")
} # }
```
