# Check and summarize length distributions in a `datras_raw` object

Create haul-by-length counts from the `HL` table of a `datras_raw` /
`DATRASraw` object and inspect the resulting length distribution.

## Usage

``` r
check_length(
  x,
  cm_breaks = seq(min(x[["HL"]]$LngtCm, na.rm = TRUE), max(x[["HL"]]$LngtCm, na.rm =
    TRUE) + by, by = by),
  by = NULL,
  length_percentile = 99.9999,
  plot = TRUE
)
```

## Arguments

- x:

  A `datras_raw` object.

- cm_breaks:

  Numeric vector of break points for length classes in centimetres. If
  supplied, these are used directly to bin `LngtCm`.

- by:

  Optional bin width in centimetres. If `cm_breaks` is not supplied, the
  bin width is determined from this argument or, if `NULL`, from the
  DATRAS internal function `getAccuracyCM()`.

- length_percentile:

  Numeric percentile used to summarize the upper tail of the observed
  length distribution. Defaults to `99.9999`.

- plot:

  Logical. If `TRUE` (default), plot the length spectrum on raw and log
  count scales.

## Value

A list with three elements:

- `N`: a haul-by-length count matrix,

- `lPars`: a data frame of summary statistics for the length
  distribution,

- `nAbove`: a data frame with the number and percentage of observations
  above selected upper-length thresholds.

## Details

The function bins fish lengths into user-defined or automatically
derived length classes, constructs a haul-by-length count matrix,
computes summary statistics of the overall length distribution, and
optionally plots the observed spectrum on both raw and log scales.

Lengths are grouped into classes using
[`cut()`](https://rdrr.io/r/base/cut.html) and counts are aggregated by
haul and length class.

In addition to the haul-by-length matrix, the function calculates
summary statistics for the pooled length distribution, including:

- observed minimum length,

- weighted mean length,

- median length,

- observed maximum length,

- empirical maximum length from `species_info`, if available,

- a user-defined upper percentile of the length distribution.

The function also reports the number and percentage of observations
above the empirical maximum length and above the selected percentile
threshold.

If multiple species are present in the `HL` table, the combined spectrum
across all species is used and a warning is issued.

## See also

[`check_weight()`](https://tokami.github.io/DATRASextra/reference/check_weight.md)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- check_length(x)

## Use custom length bins
res <- check_length(x, cm_breaks = seq(0, 100, by = 1))

## Use an automatically generated spectrum with 0.5 cm bins
res <- check_length(x, by = 0.5)
} # }
```
