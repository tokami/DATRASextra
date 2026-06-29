# Changelog

## DATRASextra 0.4.0

This release focuses on API consistency. Several arguments and function
names have been renamed so that naming conventions are uniform across
the package (e.g. `verbose` instead of `warn_missing`, `legend` instead
of `do_legend`, `write_datras` instead of `write_exchange`). Two new
arguments have been added: `plus_group` in
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)
and `lw_pars` in the weight functions for supplying custom length-weight
parameters. The default bin width in
[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)
now matches the survey’s native recording resolution instead of always
using 1 cm. All renaming changes are breaking; see the detailed entries
below.

### Breaking changes (API consistency)

- [`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md):
  arguments `remove_hl` and `remove_ca` renamed to `drop_hl` and
  `drop_ca` to match the verb used by
  [`drop_hl()`](https://tokami.github.io/DATRASextra/reference/drop_hl.md)
  and
  [`drop_ca()`](https://tokami.github.io/DATRASextra/reference/drop_ca.md).
  Argument `warn_missing` renamed to `verbose` for consistency with all
  other functions.

- [`plot_length_distribution()`](https://tokami.github.io/DATRASextra/reference/plot_length_distribution.md)
  and
  [`plot_species_composition()`](https://tokami.github.io/DATRASextra/reference/plot_species_composition.md):
  argument `do_legend` renamed to `legend` for consistency with
  [`plot_datras_overview()`](https://tokami.github.io/DATRASextra/reference/plot_datras_overview.md),
  [`plot_stratified_index()`](https://tokami.github.io/DATRASextra/reference/plot_stratified_index.md),
  and
  [`plot_spatial_indicators()`](https://tokami.github.io/DATRASextra/reference/plot_spatial_indicators.md).
  `legend_ncol` default changed from `1L` to `1`.

- [`get_aphia()`](https://tokami.github.io/DATRASextra/reference/get_aphia.md):
  first argument renamed from `x` to `species`.

- [`get_latin()`](https://tokami.github.io/DATRASextra/reference/get_latin.md):
  first argument renamed from `x` to `aphia`.

- `write_exchange()` renamed to
  [`write_datras()`](https://tokami.github.io/DATRASextra/reference/write_datras.md)
  for consistency with
  [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md).

- [`add_swept_area_simple()`](https://tokami.github.io/DATRASextra/reference/add_swept_area_simple.md)
  is no longer exported. Use
  [`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md)
  (with default `method = "simple"`) instead.

- [`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md)
  output column `SweptArea.median` renamed to `SweptArea_median`, for
  consistency with the underscore naming convention used elsewhere
  (e.g. `SweptArea_imputed`).

### Breaking changes

- [`check_lengths()`](https://tokami.github.io/DATRASextra/reference/check_lengths.md)
  and
  [`check_weights()`](https://tokami.github.io/DATRASextra/reference/check_weights.md)
  now return the input `datras_raw` object invisibly (consistent with
  [`check_outliers()`](https://tokami.github.io/DATRASextra/reference/check_outliers.md)),
  instead of a plain list. Results are attached as attributes:
  `attr(x, "length_check")` and `attr(x, "weight_check")`, respectively.
  Code that assigned the return value to a separate variable
  (e.g. `res <- check_lengths(x)`) and then accessed `res$lPars` should
  be updated to `x <- check_lengths(x)` and
  `attr(x, "length_check")$lPars`.

- The default for `impute_missing_depth` in
  [`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md)
  has changed from `TRUE` to `FALSE`. Enable explicitly with
  `impute_missing_depth = TRUE` if needed (requires the `mgcv` package).

### Minor changes

- [`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)
  gains a `plus_group` argument (default `FALSE`), passed through to
  [`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md).
  Argument order changed: `per_minute` moved to the last position so
  shared filtering arguments (`max_length`, `max_weight`) align with
  [`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md).

- [`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md):
  default for `by` changed from `1` to `get_accuracy_cm(x)`, consistent
  with
  [`check_lengths()`](https://tokami.github.io/DATRASextra/reference/check_lengths.md)
  and
  [`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md).
  Surveys recorded at 0.5 cm resolution now use 0.5 cm bins by default.

- [`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)
  and
  [`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)
  gain a `lw_pars` argument for supplying custom length-weight
  parameters `a` and `b` directly, without modifying the internal
  `species_info` table. Accepts a named vector (`c(a = 0.01, b = 3.0)`),
  a named list, or a data frame with columns `a` and `b`. For
  multi-species objects, a data frame with a `Valid_Aphia` (or `aphia`)
  column can be used to supply per-species parameters; species not
  covered fall back to `lw_source`.

- `mgcv` and `icesDatras` are no longer hard dependencies. Both have
  been removed from `Imports`; `mgcv` is now listed under `Suggests`.
  The DATRAS API calls previously handled by `icesDatras` are now made
  directly in base R.

- [`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md)
  (simple method) now reports swept-area missingness and imputation. It
  adds a per-haul logical column `SweptArea_imputed` to `HH`, attaches a
  survey-by-gear summary as `attr(x, "swept_area_summary")`, and prints
  it unless `verbose = FALSE`. The summary reports `n_imputed` /
  `prop_imputed` and `n_NA` / `prop_NA`, the hauls whose swept area is
  still `NA` after imputation (e.g. gears that cannot be imputed). A new
  `full_report` argument (default `FALSE`) additionally reports
  per-column missingness counts (`na_DoorSpread`, `na_WingSpread`,
  `na_Distance`, `na_HaulDur`) of the original input columns.

- Added the article *Matching EMODnet seabed habitats to hauls*, showing
  how to download EUSeaMap polygons from the EMODnet Seabed Habitats WFS
  and attach a seabed habitat class to each haul in `HH` with a spatial
  join.

- Replaced the article *Constructing a prediction grid within a survey
  domain* with *Building a spatiotemporal prediction grid*, which uses
  the new
  [`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md)
  function to build the grid and add a year dimension.

## DATRASextra 0.1.1

### New features

- New
  [`make_survey_grid()`](https://tokami.github.io/DATRASextra/reference/make_survey_grid.md)
  function creates a regular prediction grid from coordinate vectors.
  Supports any coordinate system, optional pruning of grid nodes by
  maximum distance to observations (via `RANN`), and optional crossing
  with a time vector.

- New `spawning_info` dataset: a lookup table of spawning months by
  species and ICES area, including the WoRMS AphiaID for each species.

- [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md)
  gains a `ncores` argument (default `1`) for parallel reading of zip
  files using
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html).
  Effective on non-Windows systems; falls back silently to sequential on
  Windows.

### Minor changes

- Added vignette *Working with datras_raw objects* introducing the
  `datras_raw` / `DATRASraw` class structure and common workflows.

- Added the *Getting started* article *The datras_raw object*,
  describing the object structure, indexing, ICES vocabulary lookups,
  and the numbers- and weight-at-length matrices.

- [`download_datras()`](https://tokami.github.io/DATRASextra/reference/download_datras.md)
  gains a `timeout` argument (default `10` seconds). When the ICES
  DATRAS server does not respond within the given time (e.g. due to
  firewall restrictions), the function now falls back to cached
  survey/year information instead of hanging indefinitely. The timeout
  also applies to the internal survey-list lookup.

### Bug fixes

- Fixed `$` and `$<-` dispatch on `datras_raw` objects
  ([\#38](https://github.com/tokami/DATRASextra/issues/38)). The
  `DATRAS` package defines `$.DATRASraw` to look inside `x[[2]]`, which
  was written for an older internal structure and caused `x$HH` to
  return `NULL` instead of the HH data frame. New `$.datras_raw` and
  `$<-.datras_raw` methods intercept dispatch before the broken method
  is reached: if the name matches a top-level table (`CA`, `HH`, or
  `HL`) the table is returned or replaced; otherwise the call is routed
  to the HH data frame, preserving the existing column-shortcut
  convention used internally (e.g. `x$SweptArea <- ...`).

## DATRASextra 0.1.0

### Initial beta release

This is the first beta release of `DATRASextra`, an R package extending
the ICES DATRAS workflow with tools for downloading, processing,
cleaning, standardising, and analysing bottom-trawl survey data.

#### Main features

- Download and import ICES DATRAS survey data
- Read, write, clean, and subset `datras_raw` objects
- Reproduce key components of the FishGlob data-processing workflow
- Estimate swept area and standardise haul metrics
- Calculate numbers- and weight-at-length distributions
- Aggregate total numbers and biomass by haul and length group
- Support species harmonisation and WoRMS-based taxonomic information
- Visualise survey structure, catch composition, and length
  distributions
- Convert DATRAS data into FishGlob-like formats for downstream analyses

#### Notes

- This is an early beta release and the API may still change.
- Additional documentation, vignettes, and workflow examples are under
  development.
