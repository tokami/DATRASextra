# Add swept-area estimates following the FishGlob workflow

Compute haul-level swept-area estimates for a `datras_raw` / `DATRASraw`
object using the FishGlob methodology.

## Usage

``` r
add_swept_area_fishglob(x)
```

## Arguments

- x:

  A `datras_raw` object containing haul-level data in `HH`.

## Value

A `datras_raw` object with two additional columns in `HH`:

- `SweptArea`: swept area in \\km^2\\,

- `DoorsArea`: door-swept area in \\km^2\\.

## Details

The function adds haul-level swept area (`SweptArea`) and door-swept
area (`DoorsArea`) to the `HH` table. Missing `WingSpread`,
`DoorSpread`, and `Distance` values are reconstructed using
survey-specific prediction models and hierarchical fallback rules.

The implementation follows the methodology used in the FishGlob
workflow. Missing `WingSpread` and `DoorSpread` values are predicted
from internally stored survey-specific models. When observed values are
missing or judged implausible, the function applies survey-specific
corrections and fallback prediction rules.

Missing towing distance is reconstructed from `GroundSpeed` and
`HaulDur`. Missing `GroundSpeed` values are imputed hierarchically using
averages at the following levels:

- survey-year-ship,

- survey-year-country,

- survey-country,

- global mean.

Swept area is then computed as: \$\$ SweptArea = Distance \times
WingSpread \times 10^{-6} \$\$

Door-swept area is computed analogously as: \$\$ DoorsArea = Distance
\times DoorSpread \times 10^{-6} \$\$

Both quantities are returned in \\km^2\\, assuming `Distance`,
`WingSpread`, and `DoorSpread` are recorded in metres.

Some survey- and gear-specific filtering and manual corrections are
applied to match the FishGlob workflow.

The original spread-estimation logic was developed by Aurore Maureaud
and P. Daniël van Denderen and is available from the FishGlob code
repository.

## References

FishGlob workflow code:
<https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R>

## See also

[`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md),
[`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x <- add_swept_area_fishglob(x)
} # }
```
