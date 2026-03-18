# Check and summarize individual weight information in a `datras_raw` object

Inspect the length-weight information stored in the `CA` table of a
`datras_raw` / `DATRASraw` object.

## Usage

``` r
check_weight(x, max_length = NULL, max_weight = NULL, plot = TRUE)
```

## Arguments

- x:

  A `datras_raw` object.

- max_length:

  Optional numeric value giving the maximum length in centimetres to
  retain for the analysis. Observations above this value are excluded.

- max_weight:

  Optional numeric value giving the maximum individual weight in grams
  to retain for the analysis. Observations above this value are
  excluded.

- plot:

  Logical. If `TRUE` (default), produce diagnostic plots of the observed
  length-weight relationship and marginal histograms of length and
  weight.

## Value

A list with four elements:

- `lPars`: a data frame with summary statistics for observed lengths,

- `wPars`: a data frame with summary statistics for observed weights,

- `parEst`: a data frame with estimated length-weight parameters `a` and
  `b`,

- `parEmp`: a data frame with empirical length-weight parameters `a` and
  `b`, if available.

## Details

The function filters to positive individual weights, optionally excludes
very large lengths or weights, summarizes the observed length and weight
distributions, fits a log-log length-weight relationship, and optionally
plots the observed data together with the fitted curve.

The function first calls
[`DATRAS::checkSpectrum()`](https://rdrr.io/pkg/DATRAS/man/DATRAS-internal.html)
and then works on the `CA` table of the input object.

A linear model of the form \$\$ \log(IndWgt) = \alpha + b \log(LngtCm)
\$\$ is fitted to the filtered observations, and the corresponding
length-weight parameters are returned as: \$\$ a = \exp(\alpha) \$\$ and
\$\$ b \$\$

If available, empirical length-weight parameters are also retrieved from
`species_info` for comparison.

## See also

[`check_length()`](https://tokami.github.io/DATRASextra/reference/check_length.md),
[`DATRAS::checkSpectrum()`](https://rdrr.io/pkg/DATRAS/man/DATRAS-internal.html)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- check_weight(x)

## Restrict to plausible values
res <- check_weight(x, max_length = 100, max_weight = 10000)
} # }
```
