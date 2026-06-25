# Add weight-at-length estimates to a `datras_raw` object

Estimate catch weight from length data and add the resulting weight
fields to a `datras_raw` / `DATRASraw` object.

## Usage

``` r
add_weight_at_length(
  x,
  max_length = NULL,
  max_weight = NULL,
  plus_group = FALSE,
  lw_source = c("lookup", "ca"),
  lw_pars = NULL,
  lookup_as_backup = FALSE,
  verbose = TRUE
)
```

## Arguments

- x:

  A `datras_raw` object.

- max_length:

  Optional numeric value giving the maximum length in centimetres to
  retain when fitting the length-weight relationship. Observations above
  this value are excluded.

- max_weight:

  Optional numeric value giving the maximum individual weight in grams
  to retain when fitting the length-weight relationship. Observations
  above this value are excluded.

- plus_group:

  Logical. If `TRUE` the midlength for the weight calculation of the
  last length bin is not using the upper limit of this length bin, which
  might be `Inf` or arbitrarily high and result in an unrealistically
  high weight for that length bin. Instead the lower limit plus half of
  the size of the second last length bin is used to define the mid
  length of the largest length bin.

- lw_source:

  Character string specifying the fallback source of length-weight
  parameters when `lw_pars` is `NULL` or does not cover a species. One
  of `"lookup"` (default, uses `species_info`) or `"ca"` (fits a log-log
  model to `CA`).

- lw_pars:

  Optional custom length-weight parameters. Overrides `lw_source` for
  the covered species. Accepted forms:

  - A named numeric vector: `c(a = 0.01, b = 3.0)`.

  - A named list: `list(a = 0.01, b = 3.0)`.

  - A data frame with columns `a` and `b` (one row per species when
    multiple species are present), and optionally a column `Valid_Aphia`
    (or `aphia`) to identify which species each row applies to.

  When no species identifier column is present, the data must contain
  exactly one species; an error is raised otherwise. When a
  `Valid_Aphia` column is present, parameters are matched by species,
  and `lw_source` is used as a fallback for any species not covered.

- lookup_as_backup:

  Logical. If `TRUE` and `lw_source = "ca"`, the `species_info` lookup
  table is used when `CA` data are insufficient. Default: `FALSE`.

- verbose:

  Logical. If `TRUE` (default), progress messages are printed.

## Value

A `datras_raw` object with estimated weight information added.

## Details

The function derives weight-at-length from custom parameters supplied
via `lw_pars`, from a log-log model fitted to the `CA` table
(`lw_source = "ca"`), or from the built-in `species_info` lookup table
(`lw_source = "lookup"`). Custom parameters in `lw_pars` take precedence
over `lw_source` for the covered species.

Weight at length is calculated as \\W = a \times L^b\\, where \\L\\ is
the mid-length of each length bin defined by `attr(x, "cm.breaks")`.

When `lw_source = "ca"`, a linear model \\\log(W) = \alpha + b \log(L)\\
is fitted to positive individual weights in `CA`, and the resulting
parameters are used.

When `lw_source = "lookup"`, parameters `a` and `b` are taken from the
built-in `species_info` table, matched by `Valid_Aphia`.

## See also

[`check_weights()`](https://tokami.github.io/DATRASextra/reference/check_weights.md),
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)

## Examples

``` r

## Add numbers at length
dab <- add_numbers_at_length(dab)
#> Warning: Mixed accuracies found in var[[3]]$LngtCode - worst chosen: 1 cm
#> Warning: NAs found in var[[3]]$LngtCode - assumed to be 1 cm

## Fitted weight-at-length from CA data
x <- add_weight_at_length(dab, lw_source = "ca")

## Lookup weight-at-length from species_info
x <- add_weight_at_length(dab, lw_source = "lookup")

## Custom parameters (single species) - named vector
x <- add_weight_at_length(dab, lw_pars = c(a = 0.00832, b = 3.09))

## Custom parameters (single species) - data frame
x <- add_weight_at_length(dab, lw_pars = data.frame(a = 0.00832, b = 3.09))

if (FALSE) { # \dontrun{
## Custom parameters for multiple species
pars <- data.frame(
  Valid_Aphia = c(127139L, 126436L),
  a = c(0.00832, 0.0045),
  b = c(3.09, 3.12)
)
x <- add_weight_at_length(x_multi, lw_pars = pars)
} # }
```
