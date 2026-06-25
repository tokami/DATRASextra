# Add simple swept-area estimates to a `datras_raw` object

Compute haul-level swept-area estimates from towing distance and trawl
width using a simple rule-based approach.

## Usage

``` r
add_swept_area_simple(
  x,
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

- min_speed:

  Minimum plausible ground speed. Values below this threshold are
  treated as missing. Defaults to `1`.

- min_dist:

  Minimum plausible towing distance. Values below this threshold are
  treated as missing. Defaults to `0`.

- max_dist_dev:

  Maximum relative deviation allowed between recorded distance and
  distance reconstructed from `HaulDur` and `GroundSpeed`. Distances
  with larger deviations are treated as missing. Defaults to `0.2`.

- impute_missing:

  Logical. Currently included for compatibility, but not used explicitly
  in the present implementation.

- width:

  Character string specifying which spread column to use as trawl width.
  Must be either `"WingSpread"` (default) or `"DoorSpread"`. Use
  `"DoorSpread"` for surveys that record door spread but not wing
  spread. Note that the fixed beam-trawl widths and the gear-specific
  plausibility bounds are only applied when `width = "WingSpread"`.

- verbose:

  Logical. If `TRUE` (default), print a summary of swept-area
  missingness and imputation by survey and gear.

- full_report:

  Logical. If `TRUE`, the summary also includes per-column missingness
  counts (`na_DoorSpread`, `na_WingSpread`, `na_Distance`, `na_HaulDur`,
  `na_GroundSpeed`) for the original input columns. Defaults to `FALSE`.

## Value

A `datras_raw` object with the following fields added to `HH`:

- `SweptArea`: swept area in \\km^2\\ based on haul-specific spread,

- `SweptArea_median`: swept area in \\km^2\\ based on gear-specific
  median spread,

- `SweptArea_imputed`: logical flag, `TRUE` when the spread and/or
  towing distance used for that haul was imputed.

A survey-by-gear summary is attached as `attr(x, "swept_area_summary")`,
with columns `survey`, `gear`, `n_records`, `n_imputed`, `prop_imputed`,
and `n_NA` / `prop_NA` (hauls whose `SweptArea` is still `NA` after
imputation, e.g. gears that cannot be imputed). When
`full_report = TRUE`, per-column missingness counts (`na_DoorSpread`,
`na_WingSpread`, `na_Distance`, `na_HaulDur`, `na_GroundSpeed`) of the
original input columns are appended.

## Details

The function uses recorded `WingSpread` where available, applies a
series of basic plausibility filters and gear-specific corrections,
imputes missing values from gear-level medians, reconstructs towing
distance when needed from `HaulDur` and `GroundSpeed`, and returns two
swept-area estimates.

Swept area is calculated in \\km^2\\ as: \$\$ SweptArea = Spread \times
Distance \times 10^{-6} \$\$ where \\Spread\\ is taken from the column
selected by `width` (in metres) and \\Distance\\ is in metres.

A second estimate, `SweptArea_median`, is also returned. This uses a
gear-specific median spread rather than the haul-specific recorded or
imputed spread: \$\$ SweptArea\\median = Spread\\median \times Distance
\times 10^{-6} \$\$

The function applies the following steps:

- removes implausible values of `GroundSpeed`, `Distance`, and the
  selected spread column,

- removes distance values that differ too much from reconstructed
  distance based on speed and haul duration,

- when `width = "WingSpread"`: applies fixed widths for selected beam
  trawl gear codes and accounts for double-beam trawls via
  `GearEx == "DB"`,

- imputes missing spread values using gear-specific medians,

- imputes missing ground speed using gear-specific medians,

- reconstructs missing towing distance from haul duration and ground
  speed.

## See also

[`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md),
[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md)
