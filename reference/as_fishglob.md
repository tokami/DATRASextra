# Convert a `datras_raw` object to FishGlob format

Convert a `datras_raw` / `DATRASraw` object into a data frame structured
to match the FishGlob data set format.

## Usage

``` r
as_fishglob(x)
```

## Arguments

- x:

  A `datras_raw` object containing `HH` and `HL` tables.

## Value

A data frame in FishGlob-like format, with one row per haul-taxon
combination.

## Details

The function aggregates length-based catch information in `HL` to the
haul-species level, merges the result with haul-level metadata from
`HH`, computes abundance and biomass standardization metrics, and
renames selected fields to match FishGlob naming conventions.

The function first aggregates `HL` records by haul and taxon using:

- total weight (`wgt`), calculated as the sum of `Wgt_total`,

- total number (`num`), calculated as the sum of `Count`.

These aggregated values are merged with the `HH` table and used to
compute:

- `wgt_cpue`: biomass per hour trawled,

- `wgt_cpua`: biomass per swept area,

- `num_cpue`: abundance per hour trawled,

- `num_cpua`: abundance per swept area.

Haul duration is converted from minutes to hours before calculating CPUE
metrics.

The returned data frame follows FishGlob naming conventions where
possible, including fields such as `survey`, `haul_id`, `latitude`,
`longitude`, `accepted_name`, and `aphia_id`.

Some output fields are created as placeholders with missing values when
the corresponding information is not available in the input data.

Country and survey-unit fields are assigned using survey-specific rules
that approximate the FishGlob workflow.

## See also

[`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md),
[`prune_fishglob()`](https://tokami.github.io/DATRASextra/reference/prune_fishglob.md),
[`add_swept_area_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_fishglob.md),
[`add_weight_fishglob()`](https://tokami.github.io/DATRASextra/reference/add_weight_fishglob.md)

## Examples

``` r
if (FALSE) { # \dontrun{
fg <- as_fishglob(x)
} # }
```
