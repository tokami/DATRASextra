# DATRASextra 0.5.2

## New features

* `download_datras()` downloads from the ICES DATRAS Download API by default,
  the service behind `icesDatras::getDatrasUnaggregated()`. It fetches several
  years and all quarters in one request per record type and receives a zipped
  CSV file, where the DATRAS web service needs one XML request per record type,
  year and quarter plus availability checks for each year. Downloading and
  reading EVHOE 2015-2022 took 28 seconds, against 94 seconds through the web
  service.

  The archive is the same as before: one `<survey>_<year>.zip` exchange file
  per year, with the same columns, entries in `DATRAS_manifest.csv` (with
  `source = "download_api"`) and the same haul identifiers. The new field names
  of the API are mapped back to the exchange names. Read back with
  `read_datras()`, EVHOE 2015-2022 and BTS 2022 gave the same records from both
  routes.

  The new `method` argument chooses the route: `"api"` (default),
  `"webservice"` for the previous `DATRAS::getDatrasExchange()` route, or
  `"php"` for `DATRAS::downloadExchange()`. `use_php = TRUE` still works and
  is the same as `method = "php"`. The new `years_per_request` argument
  (default 10) limits how many years are fetched in one request, to bound
  memory for large surveys.

  The API files are read by DATRASextra itself rather than through
  `icesDatras::getDatrasUnaggregated()`, which currently changes some values
  while parsing. It truncates HL numbers at length to integers
  (ices-tools-prod/icesDatras#65) and reads ICES rectangles such as `"13E1"`
  as numbers when all rectangles of a file have that form. DATRASextra reads
  every column as text. It also corrects for HH files whose header lists two
  fields (`EDOM`, `ReasonHaulDisruption`) that the rows do not contain, which
  would otherwise move `DateofCalculation` into the wrong column
  (ices-tools-prod/icesDatras#63).

* Survey-year-quarters that have hauls but no length data (`HL`) at all are
  now reported. Their hauls would otherwise be treated as empty hauls with zero
  catch, while their length data are missing. DATRAS holds a few such cases,
  for example test entries (ices-tools-prod/icesDatras#59; NS-IDPS 2012
  quarter 1 has a single test haul).

  `download_datras()` lists them in a warning and still writes the files as
  delivered. `clean_datras()` lists them in a message, and removes them with
  their `CA` records when the new argument `drop_without_hl = TRUE` is set
  (default `FALSE`). The check runs before `clean_datras()` filters species,
  and needs the complete `HL` table: it is skipped when there is no `HL`
  table, and data whose `HL` was subset to some species beforehand cannot be
  checked reliably.

* `as_table()` exports the length and individual data as well as the hauls,
  with the new argument `table`:
  - `table = "HL"` gives the raised numbers at length (`Count`) by haul,
    species and length class, summed over sex and catch category. By
    default (`zeros = TRUE`) it adds a row with `Count = 0` for every haul and
    species without a record, so that averages over hauls include the hauls
    where a species was not caught. `hl_by` changes the grouping, e.g. to keep
    sexes apart, and `type = "wide"` gives one row per haul and species with
    one column per length class.
  - `table = "CA"` gives one row per individual record. Records not matched
    to a haul are kept and reported instead of being dropped.

  Both carry the haul variables selected with `vars`, `add_vars` and
  `remove_vars`. Columns present in both tables are taken once, from `HH`.
  `table = "HH"`, the default, is unchanged. The numbers in `table = "HL"`
  are not rounded, whereas `add_numbers_at_length()` rounds each length class
  to whole fish, so their sum over a haul can differ slightly from `HaulN`.

* New `as_tibble()` method for `datras_raw` objects, so that
  `tibble::as_tibble(x)` and `x |> as_tibble()` return the table of
  `as_table()` as a tibble. It takes the same arguments as `as_table()`,
  including `table`. The method is registered only when tibble is installed,
  which is not required.

* `make_survey_grid()` gains `fill_gaps`, which closes holes and bays in the
  grid footprint narrower than about `2 * fill_gaps`, while the outer edge
  stays at `max_dist` from the outermost hauls. With `max_dist` alone, hauls
  farther apart than `2 * max_dist` leave holes inside the survey area. The
  grid is unchanged when `fill_gaps` is not used.

  This and the following four functions come from the FishMap project, where
  the same steps were repeated in several scripts. Rebuilt with them, the
  prediction grid of the FishMap cod model (quarters 1, 3 and 4) kept all but
  4 of the 20,483 nodes of the original, which was built with polygon
  buffers, and added 0.7-1 %; the per-year support agreed for 99.4-99.6 % of
  the nodes.

* New `add_grid_support()` flags where the survey sampled each year. It adds
  `supported`, whether the hauls of a year and its neighbouring years cover a
  grid node, and `coverage`, the share of years in which a node is covered.
  Predictions in unsupported nodes are extrapolations.

* New `add_bathymetry()` adds the depth from NOAA's ETOPO bathymetry, via the
  `marmap` package, to a grid or to `HH`. The download can be kept and
  reused, and `depth_range` flags positions within the depths the survey
  fishes.

* New `add_xy()` adds projected coordinates (by default EPSG:3035 in km) to
  `HH` or a data frame, and with `inverse = TRUE` longitude and latitude to a
  projected grid.

* New `suggest_length_cuts()` derives length groups with about equal numbers
  of fish, for `length_cuts` in `add_total_numbers_by_haul()`, with the
  realised share of fish and a label for each group.

* The article on building a spatiotemporal prediction grid covers projected
  coordinates, gap filling, support per year and depth.

* The package is much smaller: the source package went from 11.6 MB to
  3.4 MB, below the 5 MB that CRAN expects. The gear spread models used by
  `add_swept_area(method = "fishglob")` no longer carry the residuals, fitted
  values and model frames of the hauls they were fitted to. This takes them
  from 59 MB in memory, loaded with the package every time, to 0.3 MB; their
  predictions are unchanged. The example data are compressed with xz.

  "Data processing and quality control" is now an article on the package
  website (https://tokami.github.io/DATRASextra/articles/data-processing-and-qc.html)
  instead of a vignette, so it is no longer available with `vignette()`. The
  maps in the tutorial vignette are lighter, using `plot_datras_overview()`.

## Breaking changes

* `read_datras()` now defaults to `min_file_size = 0`, so only empty files are
  skipped; it was `1e4` bytes. Small archives, such as a survey year with few
  hauls or a subset written with `write_datras()`, were dropped without being
  read. Files that cannot be read are now skipped with the reason (see Bug
  fixes), so the size filter is no longer needed to protect the read. Skipped
  files are reported with `message()`, which `verbose = FALSE` silences.

* The two example data sets `mini` and `mini_fishglob` are merged into one,
  `mini`, which now holds the former `mini_fishglob`: the same four surveys
  (NS-IBTS, BITS, BTS, EVHOE) and five species as before, but for 2015-2020
  and all quarters instead of 2022-2023 (13,080 hauls instead of 3,939).
  These years overlap with the public FishGlob data, which the FishGlob
  article needs. `mini_fishglob` is removed; use `mini` instead. Code that
  relied on the years 2022-2023 in `mini` needs to use 2015-2020.

* `read_datras()` returns empty fields in exchange files as `NA` instead of an
  empty string or an empty factor level (`""`). Archives written by the web
  service route store missing values as empty fields, so these columns now
  read the same as from files that use the `-9` code. `haul.id` is not
  changed, so a haul without a station number keeps an identifier such as
  `"BTS:2022:1:GB:74E9:BT4P::5"`. Code that tests for `""` should test with
  `is.na()` instead.

## Bug fixes

* `read_datras()` no longer drops a whole exchange file because of an exact
  duplicate HH record. Such duplicates (e.g. in NS-IBTS 1991 as served by ICES)
  made `DATRAS::readICES()` stop with "Duplicated rows found in HH data", so
  the year was skipped with only "Error with: <file>". Identical HH lines are
  now removed before reading and reported. When a file still cannot be read,
  the message gives the reason.

  All inputs (a folder with or without `surveys`/`years`, or zip files) now
  go through the same reader, so `recursive`, `min_file_size` and the
  duplicated haul id check apply to all of them, and one unreadable file no
  longer stops the others from being read.

* `read_datras()` failed with "must have 'max' > 'min'" when every zip file
  was smaller than `min_file_size`. It now stops with an error that names the
  cause.

* `write_datras()` reported "Created zip file" even when no file was written.
  `utils::zip()` calls an external `zip` program, which is often missing on
  Windows unless Rtools is installed, and then fails with only a warning. The
  zip archive is now written with the `zip` package, which needs no external
  program, and `write_datras()` stops with an error if the file does not
  exist afterwards. This made `download_datras()` fail on such machines with
  errors that did not point to the cause. `zip` is a new dependency.


# DATRASextra 0.5.0

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
  behaviour of `read_datras()`. `download_datras()` takes the same argument and
  passes it on when `return_data = TRUE`; it has no effect on the files written
  to disk, which hold the exchange data as delivered by ICES.

* `plot_datras_overview()` gains `subset`, a filter applied to the haul table
  before anything is plotted. It takes an unquoted expression evaluated within
  the data, as in `subset()`, for example
  `plot_datras_overview(subset = Survey %in% c("DYFS", "SNS"), by_survey = TRUE)`
  to plot two surveys from the bundled overview instead of all of them. A
  character string or a logical vector are also accepted for filters built
  programmatically.

## Bug fixes

* `reference_tables()` reported every bundled table as `"unregistered"` on R
  older than 4.6.0. `read.dcf()` only learned to skip `#` comment lines in R
  4.6.0, so the comment header of `inst/reference_tables.dcf` made the parser
  fail and the registry read back empty. The header is now stripped before
  parsing.

* `plot_datras_overview(years = ...)` matched nothing when `Year` was stored as
  a character string, which is the case for the bundled
  `survey_info_full_raw` used when `x = NULL`. Years are now compared as
  character, so numeric `years` work for both character and integer columns.

* `reference_tables()` reported every bundled table as `"changed"` whenever it
  ran under an R version other than the one that wrote the registry. The hashes
  covered the serialisation header, which records the R version that produced
  the stream, so they changed on every R release even though the tables had
  not. The header is now excluded, and the registry has been regenerated; the
  hashes in it therefore differ from those shipped in earlier versions.
  `.hash_object()` also works again on R older than 4.5.0, where
  `tools::md5sum()` has no `bytes` argument.

* `download_datras()` returned data for the wrong years when several surveys
  were downloaded in one call without specifying `years`. The per-survey year
  list overwrote the `years` argument inside the download loop, so the archive
  was read back filtered to the year coverage of whichever survey came last:
  `download_datras(surveys = c("NS-IBTS", "BITS"))` returned no NS-IBTS data
  from before the first BITS year. Only the returned object was affected; the
  files written to disk were always complete, and re-reading such an archive
  with `read_datras()` gives the full data.

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
