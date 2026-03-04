# Add swept area indices following FishGlob methodology

Computes swept area indices (m²) for haul-level records in a `DATRASraw`
object following the methodology developed for FishGlob.

DoorSpread and WingSpread are re-estimated using survey-specific linear
models (stored internally in the package) when missing. Towing distance
is calculated from recorded distance or reconstructed from ground speed
and haul duration using a hierarchical fallback: Survey-Year-Ship →
Survey-Year-Country → Survey-Country → Global mean.

Swept area is calculated as: \$\$ SweptArea = Distance \times WingSpread
\times 10^{-6} \$\$

Door area is calculated analogously using DoorSpread.

## Usage

``` r
addSweptAreaFishGlob(x)
```

## Arguments

- x:

  A `DATRASraw` object containing haul-level (`HH`) data.

## Value

A `DATRASraw` object with two additional columns in `HH`:

- `SweptArea` — swept area in km^2

- `DoorsArea` — door swept area in km^2

## Details

The original spread estimation logic was developed by Aurore Maureaud
and Daniël van Denderen and is available at:
<https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R>.

This implementation uses pre-fitted survey-specific models stored
internally in the package and applies hierarchical fallback logic when
factor levels are not present in the training data.

Swept area is returned in square km (km^2).
