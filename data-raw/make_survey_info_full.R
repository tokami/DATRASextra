## full survey info (with positions)
## created: 04/03/2026

library(icesDatras)
library(DATRASextra)

## takes some minutes
ci <- 1
res.list <- list()
surveys <- icesDatras::getSurveyList()
for(si in 1:length(surveys)){
    years <- icesDatras::getSurveyYearList(surveys[si])
    for(yi in 1:length(years)){
        quarters <- icesDatras::getSurveyYearQuarterList(surveys[si], years[yi])
        for(qi in 1:length(quarters)){
            tmp <- getHHdata(surveys[si], years[yi], quarters[qi])
            res.list[[ci]] <- tmp[tmp$HaulVal == "V",
                                  c("Survey","Quarter","Country","Ship","Gear","Year",
                                    "HaulDur","DayNight","ShootLong","ShootLat","Depth")]
            ci <- ci + 1
        }
    }
}

res <- do.call(rbind, res.list)

survey_info_full <- res

survey_info_full <- survey_info_full[,c("Survey","Year","Quarter","Gear",
                                    "ShootLong","ShootLat")]
head(survey_info_full)
colnames(survey_info_full) <- c("Survey","Year","Quarter","Gear",
                              "lon","lat")
survey_info_full <- survey_info_full[survey_info_full$lon != -9,]
survey_info_full <- survey_info_full[survey_info_full$lat != -9,]

## Exclude Canadian survey
survey_info_full <- survey_info_full[survey_info_full$lon > -40,]

##
plot(survey_info_full$lon, survey_info_full$lat,
     col = factor(survey_info_full$Survey))


survey_info_full$StatRec <- icesSquare(survey_info_full)

sq <- unique(icesSquare(survey_info_full))
pol <- icesSquare2coord(sq,"polygons")
point <- icesSquare2coord(sq,"midpoint")

survey_info_full$Freq <- 1

agg <- aggregate(list(Hauls = survey_info_full$Freq),
                 by = list(Survey = survey_info_full$Survey,
                           Year = survey_info_full$Year,
                           Quarter = survey_info_full$Quarter,
                           Gear = survey_info_full$Gear,
                           StatRec = survey_info_full$StatRec),
                 FUN = sum)

agg <- data.frame(agg,
                  point[match(agg$StatRec, rownames(point)),])
agg <- agg[order(agg$Year),]
agg <- agg[order(agg$Survey),]
rownames(agg) <- NULL


survey_info_full <- agg


format(object.size(survey_info_full), units = "auto") ## 9.5 Kb


usethis::use_data(survey_info_full, overwrite = TRUE)
