## Anarhichas lupus (126758) as example datras object
## created: 28/05/2026

library(DATRASextra)

tmp <- tempdir()

## tmp <- "~/Documents/data/makeData/DATRAS"

surv0 <- download_datras(surveys = "NS-IBTS", dir = tmp, years = 1983:2024)

## surv0 <- read_datras(file.path(tmp, "NS-IBTS"), years = 1983:2024)

surv <- prune_datras(surv0,
                      add = c("DoorType", "StdSpecRecCode","BySpecRecCode",
                              "Netopening","Rigging","Tickler", "Warplngt",
                              "Warpdia","WarpDen", "DoorSurface",
                              "DoorWgt","Roundfish"),
                      remove_ca = TRUE)

wolffish <- clean_datras(surv, aphias = "126758")

wolffish <- subset(wolffish, Gear == "GOV" & Quarter == 1)

format(object.size(wolffish), units = "auto") ## 6.8 Kb

class(wolffish)

usethis::use_data(wolffish, overwrite = TRUE)



## wolffish2 <- add_total_numbers_by_haul(wolffish)

## wolffish2 <- add_swept_area(wolffish2)

## plot_datras_overview(wolffish2, metric = "mean", value_var = "HaulN", by_year = TRUE,
##                     multi_panels = FALSE, positive_only = TRUE)
