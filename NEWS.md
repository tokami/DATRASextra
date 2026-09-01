# DATRASextra 0.4.1

## New features

* Data extracted from ICES DATRAS now carries a record of where it came from,
  retrievable with the new `extraction()` function. The record has one row per
  survey, year and quarter and reports the ICES calculation date, the
  extraction date, the source and endpoint, the archive file and its checksum,
  and the versions of DATRASextra, DATRAS, icesDatras and R that produced the
  object. It follows the data through the processing pipeline and is reconciled
  with the records still present, so subsetting narrows it instead of leaving
  stale entries behind.

  The central field is `DateofCalculation`, supplied by ICES, which records
  when a block of records was last recalculated. Because ICES revises
  historical data as well as appending to it, this is the only reliable way to
  tell that an analysis will no longer reproduce against the current database.
  It is reconstructed from the data themselves when no explicit record is
  available, so `extraction()` also works on archives and objects created
  before this release.

* New `write_manifest()`, `read_manifest()` and `verify_extraction()` describe
  and check a local archive. `write_manifest()` records a checksum and the ICES
  calculation date for every survey-year-quarter in a directory of exchange
  files, and `verify_extraction()` re-reads the archive and reports each entry
  as `ok`, `changed` (contents differ locally), `revised` (ICES recalculated
  the data upstream), `missing` or `new`. Two users can compare manifests to
  confirm they hold identical data without hosting anything.

  `download_datras()` maintains the manifest automatically, and it can be
  built for any directory of exchange files regardless of how it was produced.

* `write_datras()` now returns the path with `payload_hash`, `zip_hash` and
  `algo` attributes. The payload hash is taken over the exchange file inside
  the archive, so it is identical whenever the data are identical; the archive
  hash is not, because `utils::zip()` stores the modification time of the file
  it compresses.

* New `reference_tables()` reports the lookup tables bundled with the package
  - `species_info`, `survey_info`, `survey_info_full_raw`, `spawning_info` and
  the internal ICES area and gear-spread tables - together with when each was
  generated, which script generated it, what it was generated from, and a hash
  that shows whether it still matches the version recorded in the package
  registry (`inst/reference_tables.dcf`). These tables are snapshots of
  external sources such as WoRMS and the ICES web services, so an analysis can
  depend on how old they are; this makes that visible. Maintainers regenerate
  the registry with `DATRASextra:::.write_reference_registry()` after
  rebuilding any table in `data-raw/`, and a test fails if the two drift apart.

* The vignette `vignette("data-processing-and-qc")` gains a section on
  recording and verifying an extraction, and on the age of the bundled
  reference tables.

* New vignette `vignette("data-processing-and-qc")` documenting every
  processing and quality-control step from download to analysis-ready object.
  It covers what `DATRAS::getDatrasExchange()` and `DATRAS::readICES()` do
  before any DATRASextra function is called (column renaming, the `-9` missing
  value sentinel, matching of orphan `CA` records, and the derived `haul.id`,
  `LngtCm`, `Species` and `Count` columns), enumerates the filters applied by
  `clean_datras()` and how to change or replace them, documents the rule-based
  and percentile checks of `check_outliers()` together with the diagnostic
  attributes it attaches, and lists further checks left to the user.

* `read_datras()` gains a `strict` argument, passed through to the underlying
  DATRAS reader. It controls how `CA` records without a haul identifier are
  matched back to a haul: the default `strict = TRUE` leaves records with
  several candidate hauls unmatched, while `strict = FALSE` assigns records with
  several candidate hauls to one of them at random. This changes the default
  behaviour of `read_datras()`.

## Bug fixes

* `download_datras()` failed for every survey and year with `Error in Year +
  (Month - 1) * 1/12 : non-numeric argument to binary operator`. The ICES DATRAS
  field list declares `Year` and `TimeShot` as character fields, and icesDatras
  1.5.2 (released 2026-06-25) started applying that schema to downloaded data by
  default, so the arithmetic in `DATRAS:::addExtraVariables()` was handed
  character vectors. Reading archived exchange files was never affected, because
  those are parsed from CSV. The fix is in DATRAS, which now coerces the fields
  that must be numeric, so DATRASextra requires DATRAS >= 1.01.2. Users on an
  older DATRAS can work around it with
  `options(icesDatras.fix_types = FALSE)`.

* `check_outliers(action = "remove")` discarded every attribute of the object
  it returned, because the removal step rebuilt the object with `lapply()` and
  restored only the class. Objects lost `cm.breaks`, `swept_area_summary` and
  `swept_area_unit`, so a subsequent call to a function depending on them
  failed with a message about a missing spectrum. Attributes are now preserved.

* `c()` on two `datras_raw` objects discarded the attributes of both. This was
  invisible before extraction records existed, but it is the point at which
  survey-year files read separately are combined, so it now merges their
  records instead.

* `clean_datras(impute_missing_depth = TRUE)` failed for every input with
  `invalid type (list) for variable 'mgcv::s(lon, lat, k = 200)'`. `mgcv`
  identifies smooth terms by matching the bare symbol `s`, so the
  namespace-qualified call in the model formula was never recognised as a
  smooth. The formula is now built in an environment that provides `s`, and
  the basis dimension is capped at the number of unique haul positions so that
  imputation also works for small objects.

## Minor changes

* `prune_datras()` now retains `DateofCalculation` in `HH`. It was previously
  dropped, which removed the only indication of when ICES last recalculated the
  records. This adds one integer column per haul.

* The default discrete colour palette used by the plotting functions is now
  sampled at equally spaced CIE L* lightness along the package colour ramp
  instead of taking the first `n` anchor colours. Previously two or three
  groups were assigned neighbouring colours from the light end of the ramp
  (sand, algae green, sea green), which separated poorly on screen and in
  print, and were close to indistinguishable under red-green colour vision
  deficiency. The new selection spans the full ramp, keeps the light-to-dark
  ordering, and increases the smallest pairwise colour distance for two groups
  by roughly a factor of four. Plots that rely on the default palette will
  change appearance; passing `col` explicitly reproduces any previous colours.

* Plots with a single group now use the teal anchor as the default colour
  rather than the palest anchor of the ramp, which had very little contrast
  against a white background. This affects `plot_stratified_index()`,
  `plot_spatial_indicators()` and `plot_length_distribution()`.

* `calc_stratified_index()` and `calc_spatial_indicators()` now return
  grouping columns with their natural type. `HH$Year` is stored as a factor,
  which was carried into the result tables, so `Year` came back as a factor or
  a character string. Columns whose values are all numeric are converted back
  to numeric; genuinely categorical groups such as `Survey` are unchanged.

* `plot_spatial_indicators()` draws connected lines and a continuous axis
  whenever the x variable is numeric-valued, including years stored as a factor
  or character. Previously such an x variable took the categorical branch,
  which drew unconnected points and one tick mark per level. Non-numeric
  x variables are still drawn as categories.

* `plot_stratified_index()` gains `y_scale`. By default (`"auto"`) the index is
  divided by a power of 1000 chosen from the data and the factor is stated in
  the y-axis label, for example `Index (per km^2) [10^9]`, so that wide tick
  labels no longer overlap the axis label. Use `y_scale = "none"` for the
  previous behaviour or pass an exponent directly. `ylim` is still given in the
  original units.


# DATRASextra 0.4.0

This release focuses on API consistency. Several arguments and function names
have been renamed so that naming conventions are uniform across the package
(e.g. `verbose` instead of `warn_missing`, `legend` instead of `do_legend`,
`write_datras` instead of `write_exchange`). Two new arguments have been added:
`plus_group` in `add_total_weight_by_haul()` and `lw_pars` in the weight
functions for supplying custom length-weight parameters. The default bin width
in `add_numbers_at_length()` now matches the survey's native recording
resolution instead of always using 1 cm. All renaming changes are breaking; see
the detailed entries below.

## Breaking changes (API consistency)

* `prune_datras()`: arguments `remove_hl` and `remove_ca` renamed to `drop_hl`
  and `drop_ca` to match the verb used by `drop_hl()` and `drop_ca()`. Argument
  `warn_missing` renamed to `verbose` for consistency with all other functions.

* `plot_length_distribution()` and `plot_species_composition()`: argument
  `do_legend` renamed to `legend` for consistency with `plot_datras_overview()`,
  `plot_stratified_index()`, and `plot_spatial_indicators()`. `legend_ncol`
  default changed from `1L` to `1`.

* `get_aphia()`: first argument renamed from `x` to `species`.

* `get_latin()`: first argument renamed from `x` to `aphia`.

* `write_exchange()` renamed to `write_datras()` for consistency with
  `read_datras()`.

* `add_swept_area_simple()` is no longer exported. Use `add_swept_area()` (with
  default `method = "simple"`) instead.

* `add_swept_area()` output column `SweptArea.median` renamed to
  `SweptArea_median`, for consistency with the underscore naming convention used
  elsewhere (e.g. `SweptArea_imputed`).

## Breaking changes

* `check_lengths()` and `check_weights()` now return the input `datras_raw`
  object invisibly (consistent with `check_outliers()`), instead of a plain
  list. Results are attached as attributes: `attr(x, "length_check")` and
  `attr(x, "weight_check")`, respectively. Code that assigned the return value
  to a separate variable (e.g. `res <- check_lengths(x)`) and then accessed
  `res$lPars` should be updated to `x <- check_lengths(x)` and
  `attr(x, "length_check")$lPars`.

* The default for `impute_missing_depth` in `clean_datras()` has changed from
  `TRUE` to `FALSE`. Enable explicitly with `impute_missing_depth = TRUE` if
  needed (requires the `mgcv` package).

## Minor changes

* `add_total_weight_by_haul()` gains a `plus_group` argument (default `FALSE`),
  passed through to `add_weight_at_length()`. Argument order changed: `per_minute`
  moved to the last position so shared filtering arguments (`max_length`,
  `max_weight`) align with `add_weight_at_length()`.

* `add_numbers_at_length()`: default for `by` changed from `1` to
  `get_accuracy_cm(x)`, consistent with `check_lengths()` and
  `add_total_numbers_by_haul()`. Surveys recorded at 0.5 cm resolution now use
  0.5 cm bins by default.

* `add_weight_at_length()` and `add_total_weight_by_haul()` gain a `lw_pars`
  argument for supplying custom length-weight parameters `a` and `b` directly,
  without modifying the internal `species_info` table. Accepts a named vector
  (`c(a = 0.01, b = 3.0)`), a named list, or a data frame with columns `a` and
  `b`. For multi-species objects, a data frame with a `Valid_Aphia` (or `aphia`)
  column can be used to supply per-species parameters; species not covered fall
  back to `lw_source`.

* `mgcv` and `icesDatras` are no longer hard dependencies. Both have been
  removed from `Imports`; `mgcv` is now listed under `Suggests`. The DATRAS
  API calls previously handled by `icesDatras` are now made directly in base R.

* `add_swept_area()` (simple method) now reports swept-area missingness and
  imputation. It adds a per-haul logical column `SweptArea_imputed` to `HH`,
  attaches a survey-by-gear summary as `attr(x, "swept_area_summary")`, and
  prints it unless `verbose = FALSE`. The summary reports `n_imputed` /
  `prop_imputed` and `n_NA` / `prop_NA`, the hauls whose swept area is still
  `NA` after imputation (e.g. gears that cannot be imputed). A new
  `full_report` argument (default `FALSE`) additionally reports per-column
  missingness counts (`na_DoorSpread`, `na_WingSpread`, `na_Distance`,
  `na_HaulDur`) of the original input columns.

* Added the article *Matching EMODnet seabed habitats to hauls*, showing how to
  download EUSeaMap polygons from the EMODnet Seabed Habitats WFS and attach a
  seabed habitat class to each haul in `HH` with a spatial join.

* Replaced the article *Constructing a prediction grid within a survey domain*
  with *Building a spatiotemporal prediction grid*, which uses the new
  `make_survey_grid()` function to build the grid and add a year dimension.



# DATRASextra 0.1.1

## New features

* New `make_survey_grid()` function creates a regular prediction grid from
  coordinate vectors. Supports any coordinate system, optional pruning of
  grid nodes by maximum distance to observations (via `RANN`), and optional
  crossing with a time vector.

* New `spawning_info` dataset: a lookup table of spawning months by species and
  ICES area, including the WoRMS AphiaID for each species.

* `read_datras()` gains a `ncores` argument (default `1`) for parallel reading
  of zip files using `parallel::mclapply()`. Effective on non-Windows systems;
  falls back silently to sequential on Windows.

## Minor changes

* Added vignette *Working with datras_raw objects* introducing the
  `datras_raw` / `DATRASraw` class structure and common workflows.

* Added the *Getting started* article *The datras_raw object*, describing the
  object structure, indexing, ICES vocabulary lookups, and the numbers- and
  weight-at-length matrices.

* `download_datras()` gains a `timeout` argument (default `10` seconds). When
  the ICES DATRAS server does not respond within the given time (e.g. due to
  firewall restrictions), the function now falls back to cached survey/year
  information instead of hanging indefinitely. The timeout also applies to the
  internal survey-list lookup.

## Bug fixes

* Fixed `$` and `$<-` dispatch on `datras_raw` objects (#38). The `DATRAS`
  package defines `$.DATRASraw` to look inside `x[[2]]`, which was written
  for an older internal structure and caused `x$HH` to return `NULL` instead
  of the HH data frame. New `$.datras_raw` and `$<-.datras_raw` methods
  intercept dispatch before the broken method is reached: if the name matches
  a top-level table (`CA`, `HH`, or `HL`) the table is returned or replaced;
  otherwise the call is routed to the HH data frame, preserving the existing
  column-shortcut convention used internally (e.g. `x$SweptArea <- ...`).



# DATRASextra 0.1.0

## Initial beta release

This is the first beta release of `DATRASextra`, an R package extending the ICES DATRAS workflow with tools for downloading, processing, cleaning, standardising, and analysing bottom-trawl survey data.

### Main features

* Download and import ICES DATRAS survey data
* Read, write, clean, and subset `datras_raw` objects
* Reproduce key components of the FishGlob data-processing workflow
* Estimate swept area and standardise haul metrics
* Calculate numbers- and weight-at-length distributions
* Aggregate total numbers and biomass by haul and length group
* Support species harmonisation and WoRMS-based taxonomic information
* Visualise survey structure, catch composition, and length distributions
* Convert DATRAS data into FishGlob-like formats for downstream analyses

### Notes

* This is an early beta release and the API may still change.
* Additional documentation, vignettes, and workflow examples are under development.
