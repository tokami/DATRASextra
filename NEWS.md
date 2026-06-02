# DATRASextra (development version)

# DATRASextra 0.1.1

## New features

* New `make_survey_grid()` function creates a regular prediction grid from
  coordinate vectors. Supports any coordinate system, optional pruning of
  grid nodes by maximum distance to observations (via `RANN`), and optional
  crossing with a time vector.

## Minor changes

* Added vignette *Working with datras_raw objects* introducing the
  `datras_raw` / `DATRASraw` class structure and common workflows.

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
