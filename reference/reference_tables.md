# Versions of the bundled reference tables

Report which reference tables are distributed with the package, when
they were generated, what they were generated from, and whether they
still match the versions that were registered.

## Usage

``` r
reference_tables(check = TRUE)
```

## Arguments

- check:

  Logical. If `TRUE` (default), hash each table and compare it with the
  hash recorded in the registry. Set to `FALSE` to skip hashing, which
  is faster for large tables.

## Value

A data frame with one row per reference table and the columns `table`,
`kind`, `rows`, `columns`, `generated`, `script`, `source`, and, when
`check = TRUE`, `hash` and `status`.

## Details

The package ships lookup tables for species and life-history
information, survey coverage, spawning times and ICES area assignment.
These are snapshots of external sources taken at a particular time, so
an analysis can depend on how old they are. This function makes that
visible, in the same way
[`extraction()`](https://tokami.github.io/DATRASextra/reference/extraction.md)
does for the survey data itself.

Two kinds of table are reported. Tables marked `"exported"` are
documented data sets that users can load directly, such as
[species_info](https://tokami.github.io/DATRASextra/reference/species_info.md).
Tables marked `"internal"` are used by the package but not exported,
such as the statistical-rectangle to ICES-area lookup used by
[`add_ices_areas()`](https://tokami.github.io/DATRASextra/reference/add_ices_areas.md).

The example survey data sets (`dab`, `mini`, `wolffish`) are not
reference tables and are not reported here; use
[`extraction()`](https://tokami.github.io/DATRASextra/reference/extraction.md)
on those.

When `check = TRUE`, the `status` column takes one of:

- `"ok"`: the table matches the registered hash,

- `"changed"`: the table has been regenerated since the registry was
  written, so `generated` and `source` may be out of date,

- `"unregistered"`: the table is present but absent from the registry,

- `"missing"`: the registry lists a table that is not available.

Hashes are taken over the serialised object and are comparable within an
installation and between installations of the same package version. They
are intended to detect that a table has been regenerated, not as a
cryptographic guarantee across R versions.

## See also

[`extraction()`](https://tokami.github.io/DATRASextra/reference/extraction.md),
[`verify_extraction()`](https://tokami.github.io/DATRASextra/reference/verify_extraction.md),
[`add_species_info()`](https://tokami.github.io/DATRASextra/reference/add_species_info.md)

## Examples

``` r
## Which reference tables are bundled, and how old are they
reference_tables()
#>                  table     kind   rows columns  generated
#> 1        spawning_info exported   1023       7 2026-09-15
#> 2         species_info exported   2064      24 2026-09-15
#> 3          survey_info exported     28       4 2026-09-15
#> 4 survey_info_full_raw exported 144401       7 2026-09-15
#> 5     ices_area_lookup internal   6758       8 2026-09-15
#> 6        spread_models internal     12      NA 2026-09-15
#>                             script
#> 1    data-raw/make_spawning_info.R
#> 2     data-raw/make_species_info.R
#> 3      data-raw/make_survey_info.R
#> 4 data-raw/make_survey_info_full.R
#> 5 data-raw/make_ices_area_lookup.R
#> 6         data-raw/spread_models.R
#>                                                                                                                                                                                                   source
#> 1                                                                                                length_at_maturity repository (GoFish and WKMAT), https://github.com/federico-maioli/length_at_maturity
#> 2 WoRMS via the worrms package; FishBase via rfishbase; DATRAS length-weight table (August 2023); functional groups from Walker et al. (2017), van Denderen et al. (2020) and Mildenberger et al. (2025)
#> 3                                                                                                                                          ICES DATRAS web service (getSurveyList and related endpoints)
#> 4                                                                                                                                             ICES DATRAS web service, haul positions by survey and year
#> 5                                                                                                                                    ICES statistical rectangle and area shapefiles, https://gis.ices.dk
#> 6                                                                                                                                                Gear spread models fitted to DATRAS haul data by survey
#>                                                               hash status
#> 1 89337a35c063f5079b6ed8838ccc6ee9662c9fe5d48e55b519d810c5b8e952ae     ok
#> 2 86ed4c635c8ee59492d58e20677a35108375dd59fca2f5d9e64b16bb98760773     ok
#> 3 6df10ac0133c50eb3da2cb7ce82adc3575523900d970968f98f8ec44f964ec8c     ok
#> 4 7133f1af5504269225148ceba7d3edaa8fe1a0424477c13d87112c1702010906     ok
#> 5 2e6472424908d13790351f2aa44027b3994941f6b5b9c055ecea5b379caf8268     ok
#> 6 2a0875426ba67e4b66ec9b1ea3e2c6a5c92376e1206bcd5f1a0f7e7ecd7ef24e     ok

## Skip hashing
reference_tables(check = FALSE)
#>                  table     kind   rows columns  generated
#> 1        spawning_info exported   1023       7 2026-09-15
#> 2         species_info exported   2064      24 2026-09-15
#> 3          survey_info exported     28       4 2026-09-15
#> 4 survey_info_full_raw exported 144401       7 2026-09-15
#> 5     ices_area_lookup internal   6758       8 2026-09-15
#> 6        spread_models internal     12      NA 2026-09-15
#>                             script
#> 1    data-raw/make_spawning_info.R
#> 2     data-raw/make_species_info.R
#> 3      data-raw/make_survey_info.R
#> 4 data-raw/make_survey_info_full.R
#> 5 data-raw/make_ices_area_lookup.R
#> 6         data-raw/spread_models.R
#>                                                                                                                                                                                                   source
#> 1                                                                                                length_at_maturity repository (GoFish and WKMAT), https://github.com/federico-maioli/length_at_maturity
#> 2 WoRMS via the worrms package; FishBase via rfishbase; DATRAS length-weight table (August 2023); functional groups from Walker et al. (2017), van Denderen et al. (2020) and Mildenberger et al. (2025)
#> 3                                                                                                                                          ICES DATRAS web service (getSurveyList and related endpoints)
#> 4                                                                                                                                             ICES DATRAS web service, haul positions by survey and year
#> 5                                                                                                                                    ICES statistical rectangle and area shapefiles, https://gis.ices.dk
#> 6                                                                                                                                                Gear spread models fitted to DATRAS haul data by survey
```
