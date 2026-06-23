## survey info
## created: 04/03/2026

## check with
DATRASextra:::.datras_api_get("getSurveyList", tag = "Survey")


surveys <- c("NS-IBTS", "BITS", "SWC-IBTS", "EVHOE", "SP-PORC", "SP-NORTH",
             "SP-ARSA", "PT-IBTS", "FR-CGFS", "NIGFS", "ROCKALL", "BTS",
             "IE-IGFS", "BTS-VIII", "DWS", "DYFS", "IS-IDPS", "NS-IDPS",
             "SCOROC", "SCOWCGFS", "BTS-GSA17", "IE-IAMS", "SNS", "Can-Mar",
             "SE-SOUND", "NL-BSAS", "NSSS", "FR-WCGFS")

description <- c("North Sea International Bottom Trawl Survey",
                 "Baltic International Trawl Survey",
                 "Scottish West Coast Bottom Trawl Survey (up to 2010)",
                 "French Southern Atlantic Bottom Trawl Survey",
                 "Spanish Porcupine Bottom Trawl Survey",
                 "Spanish North Coast Bottom Trawl Survey",
                 "Spanish Gulf of Cadiz Bottom Trawl Survey",
                 "Portuguese International Bottom Trawl Survey",
                 "French Channel Ground Fish Survey",
                 "Northern Ireland Ground Fish Survey",
                 "Scottish Rockall Survey - old (until 2010)",
                 "Beam Trawl Survey", "Irish Ground Fish Survey",
                 "Beam Trawl Survey - Bay of Biscay (VIII)",
                 "Deepwater Surveys", "Inshore Beam Trawl Survey",
                 "Irminger Sea International Deep Pelagic Survey",
                 "Norwegian Sea International Deep Pelagic Survey",
                 "Scottish Rockall Survey - new (from 2011)",
                 "Scottish West Coast Groundfish Survey (from 2011)",
                 "Beam Trawl Survey - SoleMon (Adriatic survey) - GSA17 ",
                 "Irish Anglerfish and Megrim Survey", "Sole Net Survey",
                 "Canadian Maritimes trawl survey", "Sweden Sound Survey",
                 "Netherlands Industry survey on Turbot and Brill",
                 "North Sea Sandeel Survey",
                 "French Western English Channel Ground Fish Survey")

## years (takes a second):
## tmp <- sapply(surveys, function(x) DATRASextra:::.datras_api_get("getSurveyYearList", paste0("survey=", x), tag = "Year"))
## years <- apply(sapply(tmp, range), 2, paste, collapse = "-")
years <- c("1965-2025","1991-2025","1985-2010","1997-2024","2001-2024",
           "1990-2024","1996-2024","2002-2023","1988-2024","2005-2024",
           "1999-2009","1985-2024","2003-2024","2007-2024","2006-2009",
           "1985-2024","2009-2009","2009-2016","2011-2024","2011-2025",
           "2016-2023","2016-2024","1985-2024","1970-2021","2011-2023",
           "2019-2024","2008-2024","2018-2024")

## quarters (takes few seconds):
## tmp2 <- lapply(surveys, function(x){
##     tmpi <- sapply(tmp[[x]],
##                    function(y) DATRASextra:::.datras_api_get("getSurveyYearQuarterList", paste0("survey=", x, "&year=", y), tag = "Quarter"))
##     tabi <- table(unlist(tmpi))
##     paste(paste0(names(tabi), "(", tabi, ")"), collapse = ", ")
## })
## quarters <- unlist(tmp2)
quarters <- c("1(61), 2(14), 3(34), 4(9)", "1(35), 2(10), 3(6), 4(34)",
              "1(26), 2(1), 4(20)", "4(28)", "3(24), 4(5)", "3(9), 4(35)",
              "1(22), 4(21)", "4(19)", "4(37)", "1(20), 4(18)", "3(9)",
              "1(19), 3(40)", "4(22)", "4(15)", "3(3), 4(1)",
              "3(40), 4(40)", "3(1)", "1(1), 3(3)", "3(14)", "1(14), 4(14)",
              "4(8)", "1(9), 2(8)", "3(36), 4(16)", "1(9), 3(52), 4(8)",
              "1(13), 3(7), 4(6)", "3(6), 4(5)", "4(17)", "3(7)")

res <- data.frame(survey = surveys,
                  years = years,
                  quarters = quarters,
                  description = description
                  )
res <- res[order(res$survey),]
rownames(res) <- NULL

survey_info <- res

format(object.size(survey_info), units = "auto") ## 9.5 Kb

usethis::use_data(survey_info, overwrite = TRUE)
