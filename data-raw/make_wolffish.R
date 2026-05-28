## Anarhichas lupus (126758) as example datras object
## created: 28/05/2026

library(DATRASextra)

tmp <- tempdir()

download_datras(surveys = "NS-IBTS", dir = tmp)

surv0 <- read_datras(file.path(tmp, "NS-IBTS"), years = 1991:2024)

wolffish <- clean_datras(surv0, aphias = "126758")

wolffish <- subset(wolffish, Gear == "GOV" & Quarter == 1)

format(object.size(wolffish), units = "auto") ## 9.1 Mb

class(wolffish)

usethis::use_data(wolffish, overwrite = TRUE)
