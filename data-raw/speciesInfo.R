## Species information
## created: 04/03/2026

## TODO revise when gear indices ready!

library(icesDatras)
library(DATRASextra)
library(worrms)
library(rfishbase)


## Species and life-history table ---------------------------------
tab <- read.csv("data-raw/WoRMSTable_updated.csv")
tab <- tab[,c("WoRMS_AphiaID","ScientificName_WoRMS")]

any(is.na(tab$WoRMS_AphiaID))
any(is.na(tab$ScientificName_WoRMS))



## Worms for taxonomy -----------

## Tests
curl::has_internet()
anyNA(tab$WoRMS_AphiaID)
worrms::wm_record(127160)

## Get data (takes long...)
tmp <- worrms::wm_record_(tab$WoRMS_AphiaID)
worms.rec <- do.call(rbind, tmp)


tab <- data.frame(tab,
                  as.data.frame(worms.rec[match(tab$WoRMS_AphiaID, worms.rec$AphiaID),
                                          c("genus","family","order","class","rank")]))

## TODO needed?
## ind <- which(is.na(tab$order))
## if(length(ind) > 0){
##     tab[ind,]
## }


## FishBase for traits -----------
fish <- as.data.frame(rfishbase:::fb_tbl("species"))
fish$SciName <- paste(fish$Genus, fish$Species, sep= " ")

mati <- maturity(tab$ScientificName_WoRMS)
lwi <- poplw(tab$ScientificName_WoRMS)
pgi <- popgrowth(tab$ScientificName_WoRMS)

tab$habitat <- fish$DemersPelag[match(tab$ScientificName_WoRMS, fish$SciName)]
tab$bodyShape <- fish$BodyShapeI[match(tab$ScientificName_WoRMS, fish$SciName)]
tab$maxL <- fish$Length[match(tab$ScientificName_WoRMS, fish$SciName)]

tab <- data.frame(tab,
                  as.data.frame(mati[match(tab$ScientificName_WoRMS, mati$Species),
                                     c("Lm")]))

tab <- data.frame(tab,
                  as.data.frame(lwi[match(tab$ScientificName_WoRMS, lwi$Species),
                                    c("a","b")]))

tab <- data.frame(tab,
                  as.data.frame(pgi[match(tab$ScientificName_WoRMS, pgi$Species),
                                    c("Loo","K","to")]))


## Functional groups -------------
unique(tab$habitat)
tab$habitat2 <- tab$habitat
tab$habitat2[tab$habitat2 %in% c("pelagic","pelagic-neritic",
                                 "pelagic-oceanic","bathypelagic")] <- "pelagic"
tab$habitat2[tab$habitat2 %in% c("demersal","bathydemersal")] <- "demersal"

table(tab$habitat2)
## TODO QUESTION: what about reef-associated? keep separate?

unique(tab$bodyShape)
tab$bodyShape[tab$bodyShape %in% c("elongated","Elongated")] <- "elongated"

tab$funcGroupFB <- paste0(tab$habitat2, ":", tab$bodyShape)

table(tab$funcGroupFB)

## TODO: some NA

## TODO: Manual corrections needed?
## For example:
## tab$habitat[tab$SciName %in% c("Clupea harengus",
##                                "Ammodytes marinus",
##                                "Gasterosteus aculeatus")] <- "pelagic"


## Walker / Daniel groups? -----------
tmp <- load("data-raw/Names_DATRAS_Walker_match.Rdata")
walker <- read.csv("data-raw/EfficiencyTab.csv")
walker_raw <- read.csv("data-raw/walker_raw.csv")
all(unique(q_names$q_group) %in% unique(walker$Code))


## Walker only
tab$funcGroupWalker <- walker_raw$Group[match(tab$ScientificName_WoRMS, walker_raw$Species)]
walker_raw$Species[which(is.na(match(walker_raw$Species,tab$ScientificName_WoRMS)))] ## all unaccepted names or misspelling
## "Phrynorhombus norvegius" (misspelled) -> Phrynorhombus norvegicus
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Phrynorhombus norvegicus")] <- walker_raw$Group[which(walker_raw$Species== "Phrynorhombus norvegius")]
## "Solea lascaris" (unaccepted) -> Pegusa lascaris (127156)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Pegusa lascaris")] <- walker_raw$Group[which(walker_raw$Species == "Solea lascaris")]
## "Phrynorhombus regius" (unaccepted) -> Zeugopterus regius (236488)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Zeugopterus regius")] <- walker_raw$Group[which(walker_raw$Species == "Phrynorhombus regius")]
## "Raja batis"  (unaccepted) -> Dipturus batis (105869)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Dipturus batis")] <- walker_raw$Group[which(walker_raw$Species == "Raja batis")]
## "Balistes carolinensis" (unaccepted) -> Balistes capriscus (154721)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Balistes capriscus")] <- walker_raw$Group[which(walker_raw$Species == "Balistes carolinensis")]
## "Trisopterus esmarki" (unaccepted) -> Trisopterus esmarkii (126444)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Trisopterus esmarkii")] <- walker_raw$Group[which(walker_raw$Species == "Trisopterus esmarki")]
## "Aspitrigla cuculus" (unaccepted) -> Chelidonichthys cuculus (127259)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Chelidonichthys cuculus")] <- walker_raw$Group[which(walker_raw$Species == "Aspitrigla cuculus")]
## "Trigla lucerna" (unaccepted) -> Chelidonichthys lucerna (127262)
tab$funcGroupWalker[which(tab$ScientificName_WoRMS == "Chelidonichthys lucerna")] <- walker_raw$Group[which(walker_raw$Species == "Trigla lucerna")]

## tab <- tab[!duplicated(tab$WoRMS_AphiaID),]


## Walker + Daniel
q_names$group <- walker$Group[match(q_names$q_group, walker$Code)]
tab$funcGroupDenderen <- q_names$group[match(tab$WoRMS_AphiaID, q_names$AphiaID)]
tab$funcGroupDenderen <- as.numeric(sapply(strsplit(tab$funcGroupDenderen,"GRP"),
                                           function(x) if(all(is.na(x))) NA else x[2]))

## Denderen matches with Walker where not NA
all(tab[!is.na(tab$funcGroupWalker) &
        !is.na(tab$funcGroupDenderen),
        "funcGroupWalker"] == tab[!is.na(tab$funcGroupWalker) &
                                  !is.na(tab$funcGroupDenderen),"funcGroupDenderen"])


## Walker + most abundant manually
tab$funcGroupMildenberger <- tab$funcGroupWalker

## Species to assign
tmp <- read.csv("data-raw/aphias_not_in_walker.csv")
tmp[tmp$perHaul > 1 | (tmp$relMax > 1 & !is.na(tmp$relMax)),]

## Callionymus genus
id <- "Callionymus"
tab[tab$genus == id & !is.na(tab$genus),]
## all 7
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 7

## Pomatoschistus
id <- "Pomatoschistus"
tab[tab$genus == id & !is.na(tab$genus),]
## one 2, all demersal / reef-associated & elongated
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 2

## Argentina
id <- "Argentina"
tab[tab$genus == id & !is.na(tab$genus),]
## all 5
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 5

## Capros aper
id <- "Capros aper"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Capros" & !is.na(tab$genus),]
## no other group matches (maybe 5, but more over shelf)
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 4

## Ciliata
id <- "Ciliata"
tab[tab$genus == id & !is.na(tab$genus),]
## one 2, all demersal elongated
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 2

## Mustelus
id <- "Mustelus"
tab[tab$genus == id & !is.na(tab$genus),]
## two 4, all demersal elongated
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 4

## Ammodytes
id <- "Ammodytes"
tab[tab$genus == id & !is.na(tab$genus),]
## one 1, all burrow
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 1

## Sardina pilchardus
id <- "Sardina pilchardus"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Sardina" & !is.na(tab$genus),]
## pelagic
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 6

## Liparis liparis
id <- "Liparis liparis"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Liparis" & !is.na(tab$genus),]
## lumpiform
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 7

## Gobiidae
id <- "Gobiidae"
tab[tab$family == id & !is.na(tab$family),]
## 2,6,7 in walker -> don't assign

## Gobius
id <- "Gobius"
tab[tab$genus == id & !is.na(tab$genus),]
## one 7, most demersal:elongated
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 7

## Gaidropsarus
id <- "Gaidropsarus"
tab[tab$genus == id & !is.na(tab$genus),]
## one 2
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 2

## Ammodytes marinus
id <- "Ammodytes marinus"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Liparis" & !is.na(tab$genus),]
## lumpiform
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 7

## Alosa
id <- "Alosa"
tab[tab$genus == id & !is.na(tab$genus),]
## two 6
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 6

## Molva macrophthalma
id <- "Molva macrophthalma"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Molva" & !is.na(tab$genus),]
## all 2
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 2

## Gasterosteus aculeatus
id <- "Gasterosteus aculeatus"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Gasterosteus" & !is.na(tab$genus),]
tab[tab$family == "Gasterosteidae" & !is.na(tab$family),]
## no Walker values
## tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- NA

## Coelorinchus caelorhincus
id <- "Coelorinchus caelorhincus"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Coelorinchus" & !is.na(tab$genus),]
tab[tab$family == "Macrouridae" & !is.na(tab$family),]
## no Walker values
## tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- NA

## Eutrigla
id <- "Eutrigla"
tab[tab$genus == id & !is.na(tab$genus),]
## one 7
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 7

## Chelidonichthys lastoviza
id <- "Chelidonichthys lastoviza"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Chelidonichthys" & !is.na(tab$genus),]
## two 7
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 7

## Liparis
id <- "Liparis"
tab[tab$genus == id & !is.na(tab$genus),]
## one 7
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 7

## Syngnathus
id <- "Syngnathus"
tab[tab$genus == id & !is.na(tab$genus),]
## two 4
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 4

## Malacocephalus laevis
id <- "Malacocephalus laevis"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Malacocephalus" & !is.na(tab$genus),]
tab[tab$family == "Macrouridae" & !is.na(tab$family),]
## No Walker values
## tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- NA

## Sebastes
id <- "Sebastes"
tab[tab$genus == id & !is.na(tab$genus),]
## two 4
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 4

## Dipturus intermedius
id <- "Dipturus intermedius"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Dipturus" & !is.na(tab$genus),]
## two 3, flat skate
tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- 3

## Lesueurigobius friesii
id <- "Lesueurigobius friesii"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Lesueurigobius" & !is.na(tab$genus),]
tab[tab$family == "Gobiidae" & !is.na(tab$family),]
## no Walker value for genus, family has 2,7,6 in Walker -> not clear
## tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- NA

## Blennius ocellaris
id <- "Blennius ocellaris"
tab[tab$ScientificName_WoRMS == id,]
tab[tab$genus == "Blennius" & !is.na(tab$genus),]
tab[tab$family == "Blenniidae" & !is.na(tab$family),]
## no Walker values
## tab$funcGroupWalkerAll[tab$ScientificName_WoRMS == id] <- NA

## Dipturus
id <- "Dipturus"
tab[tab$genus == id & !is.na(tab$genus),]
## all 3
tab$funcGroupWalkerAll[tab$genus == id & !is.na(tab$genus)] <- 3



## save
speciesInfo <- tab

format(object.size(speciesInfo), units = "auto") ## 626.2 Kb

usethis::use_data(speciesInfo, overwrite = TRUE)
