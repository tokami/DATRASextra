## Build canonical raw survey overview dataset for DATRASextra
## created: 2026-04-30

library(DATRASextra)

ci <- 1
res.list <- list()
surveys <- DATRASextra:::.datras_api_get("getSurveyList", tag = "Survey")

for (si in seq_along(surveys)) {
  years <- as.integer(DATRASextra:::.datras_api_get(
    "getSurveyYearList",
    paste0("survey=", URLencode(surveys[si], reserved = TRUE)),
    tag = "Year"
  ))
  for (yi in seq_along(years)) {
    quarters <- as.integer(DATRASextra:::.datras_api_get(
      "getSurveyYearQuarterList",
      paste0("survey=", URLencode(surveys[si], reserved = TRUE), "&year=", years[yi]),
      tag = "Quarter"
    ))
    for (qi in seq_along(quarters)) {
      tmp <- getHHdata(surveys[si], years[yi], quarters[qi])
      res.list[[ci]] <- tmp[
        tmp$HaulVal == "V",
        c("Survey", "Year", "Quarter", "Country", "Ship", "Gear", "DayNight", "Depth", "StatRec", "ShootLong", "ShootLat")
      ]
      ci <- ci + 1
    }
  }
}

survey_info_full_raw <- do.call(rbind, res.list)

## Standardize coordinate names used by plotting utilities
survey_info_full_raw$lon <- survey_info_full_raw$ShootLong
survey_info_full_raw$lat <- survey_info_full_raw$ShootLat

## Remove invalid coordinates
survey_info_full_raw <- survey_info_full_raw[is.finite(survey_info_full_raw$lon) & is.finite(survey_info_full_raw$lat), ]
survey_info_full_raw <- survey_info_full_raw[survey_info_full_raw$lon != -9 & survey_info_full_raw$lat != -9, ]

## Remove surveys
survey_info_full_raw <- survey_info_full_raw[which(survey_info_full_raw$Survey != "NS-IBTS_UNIFtest"),]

## Optionally exclude far-west surveys (same filter as old script)
range(survey_info_full_raw$lon)
## plot(survey_info_full_raw$lon, survey_info_full_raw$lat)
## survey_info_full_raw <- survey_info_full_raw[survey_info_full_raw$lon > -40, ]

## Optional QA object: statrec-level aggregated counts (not saved as package data)
survey_info_full_grid <- aggregate(
  list(Hauls = rep(1, nrow(survey_info_full_raw))),
  by = list(
    Survey = survey_info_full_raw$Survey,
    Year = survey_info_full_raw$Year,
    Quarter = survey_info_full_raw$Quarter,
    Gear = survey_info_full_raw$Gear,
    StatRec = survey_info_full_raw$StatRec
  ),
  FUN = sum
)

## save memory
survey_info_full_raw$ShootLong <- NULL
survey_info_full_raw$ShootLat <- NULL
survey_info_full_raw$Depth <- NULL
survey_info_full_raw$DayNight <- NULL
survey_info_full_raw$Ship <- NULL
survey_info_full_raw$Country <- NULL

## Save canonical raw dataset only; plotting can aggregate internally.
usethis::use_data(survey_info_full_raw, overwrite = TRUE)

base::format(object.size(survey_info_full_raw), units = "auto") ## 15.5 Mb

head(survey_info_full_raw)
