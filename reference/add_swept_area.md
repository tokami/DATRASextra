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
  impute_missing = FALSE
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

  Logical. Passed to
  [`add_swept_area_simple()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_simple.md).
  Only used when `method = "simple"`. Defaults to `FALSE`.

## Value

A `datras_raw` object with swept-area estimates added.

## Details

This function is a wrapper around
[`add_swept_area_simple()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_simple.md)
and
[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md).
It allows users to choose between a simple rule-based approach and the
FishGlob workflow.

If `method = "simple"`, swept area is calculated using
[`add_swept_area_simple()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_simple.md),
which applies basic plausibility filters, gear-specific median
imputations, and a direct distance-times-width calculation.

If `method = "fishglob"`, swept area is calculated using
[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md),
which follows the FishGlob workflow based on survey-specific spread
models and hierarchical fallback rules.

## See also

[`add_swept_area_simple()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_simple.md),
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
