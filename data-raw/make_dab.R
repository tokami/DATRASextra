## Limanda limanda (127139) as example datras object
## created: 04/03/2026

library(DATRASextra)

tmp <- tempdir()

download_datras(surveys = "NS-IBTS", years = 2020:2023, dir = tmp)

surv0 <- read_datras(file.path(tmp, "NS-IBTS"))

surv <- clean_datras(surv0)

dab <- subset(surv, Valid_Aphia == "127139")

format(object.size(dab), units = "auto") ## 8.9 Mb

class(dab)

usethis::use_data(dab, overwrite = TRUE)
