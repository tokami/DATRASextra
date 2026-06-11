## Spawning information lookup table
## created: 11/06/2026

## Source: length_at_maturity repository (Federico Maioli)
## https://github.com/federico-maioli/length_at_maturity/blob/main/data/metadata/spawning_lookup.rds

url <- paste0("https://github.com/federico-maioli/length_at_maturity/",
              "raw/main/data/metadata/spawning_lookup.rds")

tmp <- tempfile(fileext = ".rds")
download.file(url, tmp, mode = "wb")

spawning_info <- readRDS(tmp)

## Add the WoRMS AphiaID by matching scientific names against species_info
load("data/species_info.rda")
spawning_info$aphia <- species_info$WoRMS_AphiaID[
  match(spawning_info$species, species_info$ScientificName_WoRMS)
]

## Drop the extended spawning window
spawning_info$spawn_months_ext <- NULL

## Place aphia right after species
spawning_info <- spawning_info[, c("species", "aphia",
                                   setdiff(names(spawning_info),
                                           c("species", "aphia")))]

stopifnot(!anyNA(spawning_info$aphia))

format(object.size(spawning_info), units = "auto")

usethis::use_data(spawning_info, overwrite = TRUE)
