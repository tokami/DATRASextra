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

surveyInfoFull <- res

surveyInfoFull <- surveyInfoFull[,c("Survey","Year","Quarter","Gear",
                                    "ShootLong","ShootLat")]
head(surveyInfoFull)
colnames(surveyInfoFull) <- c("Survey","Year","Quarter","Gear",
                              "lon","lat")
surveyInfoFull <- surveyInfoFull[surveyInfoFull$lon != -9,]
surveyInfoFull <- surveyInfoFull[surveyInfoFull$lat != -9,]

## Exclude Canadian survey
surveyInfoFull <- surveyInfoFull[surveyInfoFull$lon > -40,]

##
plot(surveyInfoFull$lon, surveyInfoFull$lat,
     col = factor(surveyInfoFull$Survey))


surveyInfoFull$StatRec <- icesSquare(surveyInfoFull)

sq <- unique(icesSquare(surveyInfoFull))
pol <- icesSquare2coord(sq,"polygons")
point <- icesSquare2coord(sq,"midpoint")

surveyInfoFull$Freq <- 1

agg <- aggregate(list(Hauls = surveyInfoFull$Freq),
                 by = list(Survey = surveyInfoFull$Survey,
                           Year = surveyInfoFull$Year,
                           Quarter = surveyInfoFull$Quarter,
                           Gear = surveyInfoFull$Gear,
                           StatRec = surveyInfoFull$StatRec),
                 FUN = sum)

agg <- data.frame(agg,
                  point[match(agg$StatRec, rownames(point)),])
agg <- agg[order(agg$Year),]
agg <- agg[order(agg$Survey),]
rownames(agg) <- NULL


surveyInfoFull <- agg


format(object.size(surveyInfoFull), units = "auto") ## 9.5 Kb

usethis::use_data(surveyInfoFull, overwrite = TRUE)
