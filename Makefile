## Rebuild the bundled data and run package tasks. Run from the package root.
##
##   make            list the targets
##   make reference  rebuild out-of-date reference tables and the registry
##   make -n <tgt>   show what would run, without running it
##   make -B <tgt>   force a rebuild, e.g. to pick up new data from ICES
##
## Outputs are rebuilt when their script or a local input is newer. Remote
## inputs (ICES, WoRMS, FishBase, GitHub, Natural Earth) are not tracked: use
## -B to refresh them. Each script is sourced after devtools::load_all(), so
## it uses the package source, not the installed version.

RSCRIPT = Rscript
LOAD = devtools::load_all(quiet = TRUE)
## source the first prerequisite (the script) with the package loaded
SOURCE = $(RSCRIPT) -e '$(LOAD); source("$<")'

REFERENCE = data/species_info.rda data/spawning_info.rda \
            data/survey_info.rda data/survey_info_full_raw.rda R/sysdata.rda
EXAMPLES = data/dab.rda data/mini.rda data/wolffish.rda
LAND = inst/extdata/land_nea_50m.rds inst/extdata/land_nea_110m.rds

.DEFAULT_GOAL := help
.PHONY: help reference examples land data registry \
        document test check install site

help:
	@echo "Data (rebuild when script or local input changed; -B forces):"
	@echo "  reference  species_info, spawning_info, survey_info,"
	@echo "             survey_info_full_raw, R/sysdata.rda + registry"
	@echo "  examples   dab, mini, wolffish (download from ICES, slow)"
	@echo "  land       land polygons in inst/extdata (Natural Earth)"
	@echo "  data       all of the above"
	@echo "  registry   rewrite inst/reference_tables.dcf"
	@echo "Package:"
	@echo "  document test check install site"


## Reference tables --------------------------------------------------------------

reference: inst/reference_tables.dcf

data/species_info.rda: data-raw/make_species_info.R \
                       data-raw/WoRMSTable_updated.csv \
                       data-raw/Names_DATRAS_Walker_match.Rdata \
                       data-raw/EfficiencyTab.csv data-raw/walker_raw.csv \
                       data-raw/aphias_not_in_walker.csv \
                       data-raw/length.weight_DATRAS_3August2023.csv
	$(SOURCE)

## matches species names against species_info for the AphiaID
data/spawning_info.rda: data-raw/make_spawning_info.R data/species_info.rda
	$(SOURCE)

data/survey_info.rda: data-raw/make_survey_info.R
	$(SOURCE)

## one request per survey, year and quarter: slow
data/survey_info_full_raw.rda: data-raw/make_survey_info_full.R
	$(SOURCE)

## spread_models.R rewrites R/sysdata.rda with spread_models only, then sources
## make_ices_area_lookup.R, which adds ices_area_lookup back
R/sysdata.rda: data-raw/spread_models.R data-raw/make_ices_area_lookup.R
	$(SOURCE)

## the registry hashes the tables, so it is rewritten whenever one changes
inst/reference_tables.dcf: $(REFERENCE)
	$(RSCRIPT) -e '$(LOAD); .write_reference_registry()'

registry:
	$(RSCRIPT) -e '$(LOAD); .write_reference_registry()'


## Example data sets and land polygons -------------------------------------------

examples: $(EXAMPLES)

data/dab.rda: data-raw/make_dab.R
	$(SOURCE)

data/mini.rda: data-raw/make_mini.R
	$(SOURCE)

data/wolffish.rda: data-raw/make_wolffish.R
	$(SOURCE)

land: $(LAND)

$(LAND) &: data-raw/make_land.R
	$(SOURCE)

data: reference examples land


## Package tasks -----------------------------------------------------------------

document:
	$(RSCRIPT) -e 'devtools::document()'

test:
	$(RSCRIPT) -e 'devtools::test()'

check:
	$(RSCRIPT) -e 'devtools::check()'

install:
	$(RSCRIPT) -e 'devtools::install()'

site:
	$(RSCRIPT) -e 'pkgdown::build_site()'
