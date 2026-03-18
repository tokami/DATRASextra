
if (!requireNamespace("rnaturalearth", quietly = TRUE)) stop("need rnaturalearth")
if (!requireNamespace("sf", quietly = TRUE)) stop("need sf")

## much finer land polygons
land <- rnaturalearth::ne_download(
  scale = 50, ## 10
  type = "land",
  category = "physical",
  returnclass = "sf"
)

land <- sf::st_make_valid(land)

## define Northeast Atlantic bounding box (lon/lat, WGS84)
nea_bbox <- sf::st_bbox(
  c(xmin = -45, xmax = 35,
    ymin = 25,  ymax = 85),
  crs = sf::st_crs(4326)
)

## crop to bounding box
land <- sf::st_crop(land, nea_bbox)

## dissolve to a single geometry
land_geom <- sf::st_union(sf::st_geometry(land))

## create proper sf object
land <- sf::st_sf(geometry = land_geom, crs = 4326)

## plot(sf::st_geometry(land))

base::format(object.size(land), units = "auto") ## 10 = 1.6 Mb; 50 = 201.2 Kb

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(land, "inst/extdata/land_nea_50m.rds")
