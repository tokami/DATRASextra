


##' @title List all surveys in the DATRAS data base
##'
##' @return A vector with survey names.
##'
##' @export
listSurveys <- function() {

    data("surveyInfo")

    return(surveyInfo)
}


##' @title Correct species names
##'
##' @param x a DATRASraw object.
##'
##' @return An object of DATRASraw object
##'
##' @export
correctSpecies <- function(x) {

    for(i in c("CA","HL")){

        if (nrow(x[[i]]) == 0) next()

        if (!any(colnames(x[[i]]) == "Rank")) {
            x[[i]]$Rank <- "species"
            ## This is not right! get worms function (or later full updated species table to include this!)
        }

        specs <- as.character(x[[i]]$Species)
        aphias <- x[[i]]$Valid_Aphia
        ranks <- x[[i]]$Rank

        ## Some species not robustly identified --------------------------------
        keep.genus <- data.frame(genus = c("Dipturus", "Liparis", "Chelon",
                                           "Mustelus", "Alosa", "Argentina",
                                           "Callionymus", "Ciliata",
                                           "Gaidropsarus", "Sebastes",
                                           "Syngnatus", "Pomatoschistus",
                                           "Gobius"),
                                 aphia = c(105762, 126160, 126030, 105732, 125715,
                                           125885, 125930, 125741, 125743, 126175,
                                           126227, 125999, 125988))


        for (j in 1:nrow(keep.genus)) {
            ind <- grep(keep.genus$genus[j], specs)
            if (length(ind) > 0) {
                specs[ind] <- keep.genus$genus[j]
                aphias[ind] <- keep.genus$aphia[j]
                ranks[ind] <- "genus"
            }
        }

        ## Extra for species with different genus names ----------------------
        ind <- grep("Nerophis ophidion", specs)
        if (length(ind) > 0) {
            specs[ind] <- "Syngnatus"
            aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Syngnatus"]
            ranks[ind] <- "genus"
        }
        ind <- grep("Leusueurigobius", specs)
        if (length(ind) > 0) {
            specs[ind] <- "Gobius"
            aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Gobius"]
            ranks[ind] <- "genus"
        }
        ind <- grep("Neogobius", specs)
        if (length(ind) > 0) {
            specs[ind] <- "Gobius"
            aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Gobius"]
            ranks[ind] <- "genus"
        }
        ind <- grep("Argentinidae", specs)
        if (length(ind) > 0) {
            specs[ind] <- "Argentina"
            aphias[ind] <- keep.genus$aphia[keep.genus$genus == "Argentina"]
            ranks[ind] <- "genus"
        }


        ## Species name corrections -----------------------------------------
        ind <- grep("Synaphobranchus kaupi", specs)
        if (length(ind) > 0) {
            specs[ind] <- "Synaphobranchus kaupii"
            aphias[ind] <- 126328
            ranks[ind] <- "species"
        }
        ind <- grep("Dipturus linteus", specs)
        if (length(ind) > 0) {
            specs[ind] <- "Rajella lintea"
            aphias[ind] <- 1019159
            ranks[ind] <- "species"
        }

        x[[i]]$Species <- factor(specs)
        x[[i]]$Valid_Aphia <- aphias
        x[[i]]$Rank <- ranks

    }


    ## BySpecRecCode corrections -----------------------------------------
    ## not used currently - neither in FishGlob
    species.keep0  <- c('Clupea harengus','Sprattus sprattus',
                        'Scomber scombrus','Gadus morhua',
                        'Melanogrammus aeglefinus', 'Merlangius merlangus',
                        'Trisopterus esmarkii')

    species.keep1 <- c("Chelidonichthys cuculus", "Chelidonichthys lucerna",
                     "Eutrigla gurnardus", "Gadus morhua","Limanda limanda",
                     "Lophius piscatorius", "Merlangius merlangus",
                     "Microstomus kitt","Mullus surmuletus",
                     "Mustelus asterias","Pegusa lascaris",
                     "Platichthys flesus", "Pleuronectes platessa",
                     "Raja brachyura","Raja clavata", "Raja montagui",
                     "Scophthalmus maximus", "Scophthalmus rhombus",
                     "Scyliorhinus canicula", "Solea solea",
                     "Trispoterus luscus")

    species.keep2 <- c('Ammodytidae','Anarhichas lupus', 'Argentina silus',
                       'Argentina sphyraena', 'Chelidonichthys cuculus',
                       'Callionymus lyra', 'Eutrigla gurnardus',
                       'Lumpenus lampretaeformis', 'Mullus surmuletus',
                       'Squalus acanthias', 'Trachurus trachurus',
                       'Platichthys flesus', 'Pleuronectes platessa',
                       'Limanda limanda', 'Lepidorhombus whiffiagoni',
                       'Hippoglossus hippoglossus',
                       'Hippoglossoides platessoi',
                       'Glyptocephalus cynoglossu', 'Microstomus kitt',
                       'Scophthalmus maximus', 'Scophthalmus rhombus',
                       'Solea solea', 'Pollachius virens',
                       'Pollachius pollachius', 'Trisopterus luscus',
                       'Trisopterus minutus', 'Micromesistius poutassou',
                       'Molva molva', 'Merluccius merluccius',
                       'Brosme brosme', 'Clupea harengus',
                       'Sprattus sprattus', 'Scomber scombrus',
                       'Gadus morhua', 'Melanogrammus aeglefinus',
                       'Merlangius merlangus','Trisopterus esmarkii')

    species.keep3 <- c('Pollachius virens','Pollachius pollachius',
                       'Trisopterus luscus','Trisopterus minutus',
                       'Micromesistius poutassou','Molva molva',
                       'Merluccius merluccius','Brosme brosme',
                       'Clupea harengus','Sprattus sprattus',
                       'Scomber scombrus','Gadus morhua',
                       'Melanogrammus aeglefinus', 'Merlangius merlangus',
                       'Trisopterus esmarkii')

    species.keep4 <- c('Platichthys flesus','Pleuronectes platessa',
                        'Limanda limanda', 'Lepidorhombus whiffiagoni',
                        'Hippoglossus hippoglossus',
                        'Hippoglossoides platessoi',
                        'Glyptocephalus cynoglossu', 'Microstomus kitt',
                        'Scophthalmus maximus', 'Scophthalmus rhombus',
                        'Solea solea', 'Clupea harengus',
                        'Sprattus sprattus', 'Scomber scombrus',
                        'Gadus morhua', 'Melanogrammus aeglefinus',
                        'Merlangius merlangus', 'Trisopterus esmarkii')

    species.keep5 <- c('Ammodytidae','Anarhichas lupus', 'Argentina silus',
                       'Argentina sphyraena', 'Chelidonichthys cuculus',
                       'Callionymus lyra', 'Eutrigla gurnardus',
                       'Lumpenus lampretaeformis', 'Mullus surmuletus',
                       'Squalus acanthias', 'Trachurus trachurus',
                       'Clupea harengus', 'Sprattus sprattus',
                       'Scomber scombrus', 'Gadus morhua',
                       'Melanogrammus aeglefinus', 'Merlangius merlangus',
                       'Trisopterus esmarkii')

    species.keep6 <- c("Chelidonichthys lucerna","Conger conger",
                       "Eutrigla gurnardus", "Galeus melastomus",
                       "Helicolenus dactylopterus", "Lepidorhombus boscii",
                       "Lepidorhombus whiffiagoni", "Leucoraja circularis",
                       "Leucoraja naevus", "Lophius budegassa",
                       "Lophius piscatorius", "Merluccius merluccius",
                       "Micromesistius poutassou", "Phycis blennoides",
                       "Raja clavata", "Raja montagui", "Scomber scombrus",
                       "Scyliorhinus canicula", "Trachurus trachurus",
                       "Trisopterus luscus", "Zeus faber")

    species.keep7 <- c("Argentina silus","Chelidonichthys lucerna",
                       "Conger conger", "Eutrigla gurnardus",
                       "Gadus morhua","Galeus melastomus",
                       "Glyptocephalus cynoglossu",
                       "Helicolenus dactylopterus", "Hexanchus griseus",
                       "Hippoglossoides platessoi", "Lepidorhombus boscii",
                       "Lepidorhombus whiffiagoni", "Leucoraja circularis",
                       "Leucoraja naevus", "Lophius budegassa",
                       "Lophius piscatorius", "Melanogrammus aeglefinus",
                       "Merluccius merluccius", "Micromesistius poutassou",
                       "Molva dypterygia","Molva molva",
                       "Phycis blennoides","Raja clavata", "Raja montagui",
                       "Scomber scombrus", "Scyliorhinus canicula",
                       "Trachurus trachurus","Zeus faber")

    ## From Anna, what is NS-IBTS1 and NS-IBTS3?  q1 and q3?
    ## data <- subset(data, !(BySpecRecCode==0 & Data %in% c("NS-IBTS1","NS-IBTS3") &
    ##                !Species %in% c("Clupea harengus","Sprattus sprattus","Scomber scombrus","Gadus morhua",
    ##                                "Melanogrammus aeglefinus","Merlangius merlangus","Trisopterus esmarkii")))

    ## Not used here currently, neither in FishGlob ... TODO: quantify how many entries that would be!
    ## out_data <- data[
    ##     !(data$BycSpecRecCode == 0 & data$Survey == "NS-IBTS" &
    ##       !(data$Species %in% species.keep0)) &
    ##     !(data$BycSpecRecCode == 0 & data$Survey == "BTS" &
    ##       !(data$Species %in% species.keep1)) &
    ##     !(data$BycSpecRecCode == 2 & !(data$Species %in% species.keep2)) &
    ##     !(data$BycSpecRecCode == 3 & !(data$Species %in% species.keep3)) &
    ##     !(data$BycSpecRecCode == 4 & !(data$Species %in% species.keep4)) &
    ##     !(data$BycSpecRecCode == 5 & !(data$Species %in% species.keep5)) &
    ##     !(data$BycSpecRecCode == 0 & data$Survey == "SP-NORTH" &
    ##       !(data$Species %in% species.keep6)) &
    ##     !(data$BycSpecRecCode == 0 & data$Survey == "SP-PORC" &
    ##       !(data$Species %in% species.keep7)),
    ##     ]


    return(x)
}








##' @title Create long-format table
##'
##' @param x a DATRASraw object.
##'
##' @return Long-format table
##'
##' @export
getLongFormat <- function(x) {

    res <- x[[2]][,c("Survey","Gear","Country","Ship",
                     "Year","Quarter",
                     "Month","Day", "lon","lat",
                     "timeOfYear","abstime", "DayNight", "TimeShotHour",
                     "HaulDur")]
    if(any(colnames(x[[2]]) == "Area_27")){
        res <- data.frame(res, Area_27 = x[[2]]$Area_27)
    }
    if(any(colnames(x[[2]]) == "Area_km2")){
        res <- data.frame(res, Area_km2 = x[[2]]$Area_km2)
    }
    if(any(colnames(x[[2]]) == "HaulWgt")){
        res <- data.frame(res, HaulWgt = x[[2]]$HaulWgt)
    }
    res$Species <- unique(x[[3]]$Species)

    return(res)
}
