## Build the StatRec -> ICES area lookup and the area pieces of the rectangles
## that cross an area boundary, from the ICES shapefiles.
##
## Shapefiles downloaded from https://gis.ices.dk/sf/index.html?widget=StatRec
## and stored in dev/ICES_areas/ and dev/ICES_rectangles/ (not shipped with
## the package because of size), i.e. in the folder above the package root.
##
## Run from the package root (see Makefile).
##
## Outputs: adds `ices_area_lookup` and `ices_area_split` to R/sysdata.rda.
##
## - ices_area_lookup: one row per rectangle, with the area that covers most
##   of its sea surface (NA for rectangles without sea) and its ecoregion.
## - ices_area_split: polygons (lon, lat) of the parts of the rectangles that
##   lie in more than one area, one piece per rectangle and area, simplified
##   to 100 m. add_ices_areas() assigns positions in these rectangles by
##   point in polygon.

library(sf)
sf_use_s2(FALSE)  ## planar in lon/lat: rectangle edges stay straight lines

areas_path <- "../dev/ICES_areas/ICES_Areas_20160601_cut_dense_3857.shp"
rects_path <- "../dev/ICES_rectangles/ICES_Statistical_Rectangles_Eco.shp"
tolerance <- 100  ## m, simplification of the pieces

areas <- st_read(areas_path, quiet = TRUE)
rects <- st_read(rects_path, quiet = TRUE)

## the area attributes follow from Area_Full (e.g. 27.3.d.28.1)
attrs <- .ices_area_attrs(areas$Area_Full)
stopifnot(identical(attrs$Major_FA, areas$Major_FA),
          identical(attrs$SubArea, areas$SubArea),
          identical(attrs$Division, areas$Division),
          identical(attrs$SubDivisio, areas$SubDivisio),
          identical(attrs$Area_27, areas$Area_27))

## the rectangle codes follow from the corners
stopifnot(identical(get_statrec(rects$WEST + 0.5, rects$SOUTH + 0.25),
                    rects$ICESNAME))

areas <- st_make_valid(st_zm(st_transform(areas[, "Area_Full"], 4326)))

## all rectangles: the shapefile leaves out most rectangles without sea in
## it, but some of them hold sea of the area shapefile (e.g. the Limfjord)
rect_eco <- st_drop_geometry(rects)[, c("ICESNAME", "Ecoregion")]
codes <- unlist(lapply(sprintf("%02d", 1:99), paste0,
                       c(paste0("A", 0:3),
                         paste0(rep(.statrec_letters[2:11], each = 10), 0:9),
                         paste0("M", 0:8))))
corner <- get_statrec_coords(codes, where = "corner")
stopifnot(!anyNA(corner), all(rect_eco$ICESNAME %in% codes))
rects <- st_sf(ICESNAME = codes,
               Ecoregion = rect_eco$Ecoregion[match(codes, rect_eco$ICESNAME)],
               geometry = st_sfc(lapply(seq_along(codes), function(k) {
                 x <- corner$lon[k] + c(0, 1, 1, 0, 0)
                 y <- corner$lat[k] + c(0, 0, 0.5, 0.5, 0)
                 st_polygon(list(cbind(x, y)))
               }), crs = 4326))

## sea surface of each rectangle by area
pieces <- suppressWarnings(st_intersection(rects, areas))
pieces <- pieces[st_geometry_type(pieces) %in% c("POLYGON", "MULTIPOLYGON"), ]
pieces$km2 <- as.numeric(st_area(st_transform(pieces, 3035))) / 1e6
pieces <- pieces[pieces$km2 > 0, ]
pieces$share <- ave(pieces$km2, pieces$ICESNAME, FUN = function(v) v / sum(v))

## lookup: area with the largest share of the sea surface
d <- st_drop_geometry(pieces)
d <- d[order(d$ICESNAME, -d$share), ]
major <- d[!duplicated(d$ICESNAME), ]
ices_area_lookup <- data.frame(StatRec = rects$ICESNAME,
                               Ecoregion = rects$Ecoregion)
ices_area_lookup$Area_Full <- major$Area_Full[match(ices_area_lookup$StatRec,
                                                    major$ICESNAME)]
## rectangles of the shapefile and rectangles with sea
ices_area_lookup <- ices_area_lookup[!is.na(ices_area_lookup$Area_Full) |
                                       ices_area_lookup$StatRec %in% rect_eco$ICESNAME, ]
ices_area_lookup <- cbind(ices_area_lookup[, c("StatRec", "Ecoregion")],
                          .ices_area_attrs(ices_area_lookup$Area_Full))
ices_area_lookup$Split <- ices_area_lookup$StatRec %in%
  d$ICESNAME[duplicated(d$ICESNAME)]
rownames(ices_area_lookup) <- NULL

## pieces of the split rectangles, as rings of vertices; ring 1 of a piece is
## the outer boundary, further rings are holes (islands) or further parts
split <- pieces[pieces$ICESNAME %in% ices_area_lookup$StatRec[ices_area_lookup$Split], ]
split <- st_transform(st_simplify(st_transform(split, 3035),
                                  dTolerance = tolerance), 4326)
split <- split[!st_is_empty(split), ]
rings <- lapply(seq_len(nrow(split)), function(k) {
  cc <- st_coordinates(st_geometry(split)[[k]])
  ## L1: ring of a polygon, L2: polygon of a multipolygon
  id <- if ("L2" %in% colnames(cc)) paste(cc[, "L2"], cc[, "L1"]) else cc[, "L1"]
  data.frame(StatRec = split$ICESNAME[k], Area_Full = split$Area_Full[k],
             ring = match(id, unique(id)),
             lon = round(cc[, "X"], 5), lat = round(cc[, "Y"], 5))
})
ices_area_split <- do.call(rbind, rings)
## one id per ring over all pieces
ices_area_split$ring <- match(paste(ices_area_split$StatRec, ices_area_split$Area_Full,
                                    ices_area_split$ring),
                              unique(paste(ices_area_split$StatRec,
                                           ices_area_split$Area_Full,
                                           ices_area_split$ring)))

## split: rectangles with more than one area left after the simplification
## (slivers along a rectangle edge vanish), the rest by the lookup alone
n_areas <- tapply(ices_area_split$Area_Full, ices_area_split$StatRec,
                  function(v) length(unique(v)))
ices_area_lookup$Split <- ices_area_lookup$StatRec %in% names(n_areas)[n_areas > 1]
ices_area_split <- ices_area_split[ices_area_split$StatRec %in%
                                     ices_area_lookup$StatRec[ices_area_lookup$Split], ]
ices_area_split$ring <- match(ices_area_split$ring, unique(ices_area_split$ring))
rownames(ices_area_split) <- NULL

str(ices_area_lookup, 1)
str(ices_area_split, 1)
cat("Rectangles:", nrow(ices_area_lookup),
    "| without sea:", sum(is.na(ices_area_lookup$Area_Full)),
    "| split:", sum(ices_area_lookup$Split), "\n")

## Add to sysdata.rda alongside existing objects; only spread_models is taken
## from the old file, which also holds the old versions of the tables above
old <- new.env()
load("R/sysdata.rda", envir = old)
spread_models <- old$spread_models
usethis::use_data(spread_models, ices_area_lookup, ices_area_split,
                  internal = TRUE, overwrite = TRUE, compress = "xz")
