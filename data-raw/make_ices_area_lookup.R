## Build StatRec → ICES area lookup table from ICES shapefiles.
##
## Shapefiles downloaded from https://gis.ices.dk/sf/index.html?widget=StatRec
## and stored in dev/ICES_areas/ and dev/ICES_rectangles/ (not shipped with
## the package because of size).
##
## Outputs: adds `ices_area_lookup` to R/sysdata.rda.

library(sf)

areas_path <- "../dev/ICES_areas/ICES_Areas_20160601_cut_dense_3857.shp"
rects_path <- "../dev/ICES_rectangles/ICES_Statistical_Rectangles_Eco.shp"

areas <- st_read(areas_path)
rects <- st_read(rects_path)

## Use centroids of rectangles for the join — faster and avoids edge artefacts.
rects_crs <- st_transform(rects, st_crs(areas))
centroids <- st_centroid(rects_crs)

joined <- st_join(centroids, areas[, c("Major_FA", "SubArea", "Division",
                                        "SubDivisio", "Area_Full", "Area_27")],
                  join = st_within, left = TRUE)

ices_area_lookup <- as.data.frame(joined)[, c("ICESNAME", "Ecoregion",
                                               "Major_FA", "SubArea",
                                               "Division", "SubDivisio",
                                               "Area_Full", "Area_27")]
colnames(ices_area_lookup)[colnames(ices_area_lookup) == "ICESNAME"] <- "StatRec"

## Remove geometry column (already dropped by as.data.frame above for non-sf
## columns, but guard against any sticky geometry).
ices_area_lookup <- ices_area_lookup[, !sapply(ices_area_lookup, inherits,
                                                "sfc")]
rownames(ices_area_lookup) <- NULL

str(ices_area_lookup, 1)
head(ices_area_lookup)
cat("Rows:", nrow(ices_area_lookup), "\n")
cat("Unmatched rectangles:", sum(is.na(ices_area_lookup$Area_27)), "\n")

## Add to sysdata.rda alongside existing objects
load("R/sysdata.rda")  ## loads spread_models
usethis::use_data(spread_models, ices_area_lookup,
                  internal = TRUE, overwrite = TRUE)
