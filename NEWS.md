# DATRASextra 0.2.3

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
