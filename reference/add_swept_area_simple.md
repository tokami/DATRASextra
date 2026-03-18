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
  impute_missing = FALSE
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

## Value

A `datras_raw` object with two additional swept-area fields:

- `SweptArea`: swept area based on haul-specific `WingSpread`,

- `SweptArea.median`: swept area based on gear-specific median wing
  spread.

## Details

The function uses recorded `WingSpread` where available, applies a
series of basic plausibility filters and gear-specific corrections,
imputes missing values from gear-level medians, reconstructs towing
distance when needed from `HaulDur` and `GroundSpeed`, and returns two
swept-area estimates.

Swept area is calculated in \\m^2\\ as: \$\$ SweptArea = WingSpread
\times Distance \$\$

A second estimate, `SweptArea.median`, is also returned. This uses a
gear-specific median wing spread rather than the haul-specific recorded
or imputed wing spread: \$\$ SweptArea.median = WingSpread.median \times
Distance \$\$

The function applies the following steps:

- removes implausible values of `GroundSpeed`, `Distance`, and
  `WingSpread`,

- removes distance values that differ too much from reconstructed
  distance based on speed and haul duration,

- imputes missing wing spread using gear-specific medians,

- applies fixed widths for selected beam trawl gear codes,

- accounts for double-beam trawls via `GearEx == "DB"`,

- imputes missing ground speed using gear-specific medians,

- reconstructs missing towing distance from haul duration and ground
  speed.

## See also

[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_swept_area_simple(x)

## Use stricter plausibility filtering
x <- add_swept_area_simple(x, min_speed = 2, max_dist_dev = 0.1)
} # }
```
