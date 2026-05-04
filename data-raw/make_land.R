
if (!requireNamespace("rnaturalearth", quietly = TRUE)) stop("need rnaturalearth")
if (!requireNamespace("sf", quietly = TRUE)) stop("need sf")



## fine map ---------------------------------------------------------------

land <- rnaturalearth::ne_download(
  scale = 50,
  type = "land",
  category = "physical",
  returnclass = "sf"
)

land <- sf::st_make_valid(land)

## define Northeast Atlantic bounding box (lon/lat, WGS84)
## nea_bbox <- sf::st_bbox(
##   c(xmin = -45, xmax = 35,
##     ymin = 25,  ymax = 85),
##   crs = sf::st_crs(4326)
## )

## larger area when including Can-Mar survey
nea_bbox <- sf::st_bbox(
  c(xmin = -80, xmax = 40,
    ymin = 5,  ymax = 85),
  crs = sf::st_crs(4326)
)

## crop to bounding box
land <- sf::st_crop(land, nea_bbox)

## dissolve to a single geometry
land_geom <- sf::st_union(sf::st_geometry(land))

## create proper sf object
land <- sf::st_sf(geometry = land_geom, crs = 4326)

## plot(sf::st_geometry(land))

base::format(object.size(land), units = "auto") ## 387.6 Kb

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(land, "inst/extdata/land_nea_50m.rds")




## coarse map ---------------------------------------------------------------

land <- rnaturalearth::ne_download(
  scale = 110,
  type = "land",
  category = "physical",
  returnclass = "sf"
)

land <- sf::st_make_valid(land)

## larger area when including Can-Mar survey
nea_bbox <- sf::st_bbox(
  c(xmin = -80, xmax = 40,
    ymin = 5,  ymax = 85),
  crs = sf::st_crs(4326)
)

## crop to bounding box
land <- sf::st_crop(land, nea_bbox)

## dissolve to a single geometry
land_geom <- sf::st_union(sf::st_geometry(land))

## create proper sf object
land <- sf::st_sf(geometry = land_geom, crs = 4326)

## plot(sf::st_geometry(land))

base::format(object.size(land), units = "auto") ## 110 = 36.1Kb

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(land, "inst/extdata/land_nea_110m.rds")
