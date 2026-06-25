# Add swept-area estimates to a `datras_raw` object

Compute haul-level swept-area estimates for a `datras_raw` / `DATRASraw`
object using one of the supported methods.

## Usage

``` r
add_swept_area(
  x,
  method = "simple",
  min_speed = 1,
  min_dist = 0,
  max_dist_dev = 0.2,
  impute_missing = FALSE,
  width = "WingSpread",
  verbose = TRUE,
  full_report = FALSE
)
```

## Arguments

- x:

  A `datras_raw` object.

- method:

  Character string specifying the method used to calculate swept area.
  Must be either `"simple"` (default) or `"fishglob"`.

- min_speed:

  Minimum plausible ground speed. Values below this threshold are
  treated as missing. Only used when `method = "simple"`. Defaults to
  `1`.

- min_dist:

  Minimum plausible towing distance. Values below this threshold are
  treated as missing. Only used when `method = "simple"`. Defaults to
  `0`.

- max_dist_dev:

  Maximum relative deviation allowed between recorded distance and
  distance reconstructed from `HaulDur` and `GroundSpeed`. Distances
  with larger deviations are treated as missing. Only used when
  `method = "simple"`. Defaults to `0.2`.

- impute_missing:

  Logical. Only used when `method = "simple"`. Defaults to `FALSE`.

- width:

  Character string specifying which spread column to use as trawl width.
  Must be either `"WingSpread"` (default) or `"DoorSpread"`. Only used
  when `method = "simple"`; ignored for `method = "fishglob"`.

- verbose:

  Logical. If `TRUE` (default) and `method = "simple"`, print a summary
  of swept-area missingness and imputation by survey and gear.

- full_report:

  Logical. If `TRUE`, the printed and attached summary also includes
  per-column missingness counts (`na_DoorSpread`, `na_WingSpread`,
  `na_Distance`, `na_HaulDur`, `na_GroundSpeed`) for the original input
  columns. Only used when `method = "simple"`. Defaults to `FALSE`.

## Value

A `datras_raw` object with swept-area estimates added.

## Details

This function is a wrapper around an internal simple swept-area function
and
[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md).
It allows users to choose between a simple rule-based approach and the
FishGlob workflow.

If `method = "simple"`, swept area is calculated using a simple
rule-based approach that applies basic plausibility filters,
gear-specific median imputations, and a direct distance-times-width
calculation. A per-haul logical column `SweptArea_imputed` is added to
`HH`, and a survey-by-gear summary of missingness and imputation is
attached as `attr(x, "swept_area_summary")` (and printed when
`verbose = TRUE`).

If `method = "fishglob"`, swept area is calculated using
[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md),
which follows the FishGlob workflow based on survey-specific spread
models and hierarchical fallback rules.

## See also

[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Simple swept-area estimation
x <- add_swept_area(x)

## FishGlob workflow
x <- add_swept_area(x, method = "fishglob")

## Simple method with stricter filters
x <- add_swept_area(x, method = "simple", min_speed = 2,
                    max_dist_dev = 0.1)
} # }
```
