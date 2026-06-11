#' Dab survey data (example dataset)
#'
#' Example ICES DATRAS data for *Limanda limanda* (dab) from survey NS-IBTS in
#' years 2020-2023.
#'
#' @format A list of class 'datras_raw' with 3 elements:
#' \describe{
#'   \item{CA}{Biological data}
#'   \item{HH}{Survey level information}
#'   \item{HL}{Length measurements}
#' }
#' @source ICES DATRAS database \url{https://datras.ices.dk}
"dab"


#' Mini DATRAS survey data (example dataset)
#'
#' Example ICES DATRAS data for 2 years (2022-2023), 4 surveys (NS-IBTS, BITS,
#' BTS, and EVHOE), and 5 species: Lophius piscatorius (European anglerfish),
#' Lepidorhombus whiffiagonis (Megrim), Hippoglossoides platessoides (American
#' plaice), Trisopterus esmarkii (Norway pout), and Amblyraja radiata (Starry
#' ray).
#'
#' @format A list of class 'datras_raw' with 3 elements:
#' \describe{
#'   \item{CA}{Biological data}
#'   \item{HH}{Survey level information}
#'   \item{HL}{Length measurements}
#' }
#' @source ICES DATRAS database \url{https://datras.ices.dk}
"mini"


#' Mini DATRAS survey data for fishglob comparison (example dataset)
#'
#' Example ICES DATRAS data for 5 years (2015-2020), 4 surveys (NS-IBTS, BITS,
#' BTS, and EVHOE), and 5 species: Lophius piscatorius (European anglerfish),
#' Lepidorhombus whiffiagonis (Megrim), Hippoglossoides platessoides (American
#' plaice), Trisopterus esmarkii (Norway pout), and Amblyraja radiata (Starry
#' ray).
#'
#' @format A list of class 'datras_raw' with 3 elements:
#' \describe{
#'   \item{CA}{Biological data}
#'   \item{HH}{Survey level information}
#'   \item{HL}{Length measurements}
#' }
#' @source ICES DATRAS database \url{https://datras.ices.dk}
"mini_fishglob"


#' Species information lookup table
#'
#' A lookup table linking ICES species codes to names and ecological groups.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{WoRMS_AphiaID}{Numeric AphiaID identifier from the World Register of Marine Species (WoRMS).}
#'   \item{ScientificName_WoRMS}{Full scientific name of the species according to WoRMS.}
#'   \item{genus}{Genus name of the species.}
#'   \item{family}{Family name of the species.}
#'   \item{order}{Taxonomic order of the species.}
#'   \item{class}{Taxonomic class of the species.}
#'   \item{rank}{Taxonomic rank of the record (e.g., species, genus).}
#'   \item{habitat}{General habitat category (e.g., marine, brackish, freshwater).}
#'   \item{bodyShape}{General body shape category (e.g., fusiform, elongate, flat).}
#'   \item{maxL}{Maximum observed length (cm).}
#'   \item{Lm}{Length at maturity (cm).}
#'   \item{a}{Length–weight relationship parameter \(a\) (in \(W = a L^b\)).}
#'   \item{b}{Length–weight relationship parameter \(b\) (in \(W = a L^b\)).}
#'   \item{Loo}{Asymptotic length from the von Bertalanffy growth model (cm).}
#'   \item{K}{Growth coefficient from the von Bertalanffy model (1/year).}
#'   \item{to}{Theoretical age at zero length \(t_0\) from the von Bertalanffy model (years).}
#'   \item{habitat2}{Alternative or refined habitat classification.}
#'   \item{funcGroupFB}{Functional group according to FishBase.}
#'   \item{funcGroupWalker}{Functional group following Walker et al. (2017).}
#'   \item{funcGroupDenderen}{Functional group following van Denderen et al. (2020).}
#'   \item{funcGroupMildenberger}{Functional group following Mildenberger et al. (2025).}
#'   \item{funcGroupWalkerAll}{Unified or merged functional grouping combining multiple classification sources.}
#'   \item{aFG}{Length–weight relationship parameter \(a\) (in \(W = a L^b\)) used in FishGlobe.}
#'   \item{bFG}{Length–weight relationship parameter \(b\) (in \(W = a L^b\)) used in FishGlobe.}
#' }
#' @source ICES DATRAS species reference list.
"species_info"


#' Survey information table
#'
#' Metadata for ICES bottom trawl surveys, including survey names, areas,
#' and available time ranges.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{survey}{Survey code (e.g. NS-IBTS)}
#'   \item{years}{Years}
#'   \item{quarters}{Quarters}
#'   \item{description}{Description}
#' }
#' @source ICES DATRAS metadata.
"survey_info"


#' Full survey information table
#'
#' Extended version of `survey_info` with additional coverage and technical
#' details for each DATRAS survey.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{Survey}{Survey code (e.g. NS-IBTS)}
#'   \item{Year}{Years}
#'   \item{Quarter}{Quarters}
#'   \item{Gear}{Gear}
#'   \item{StatRec}{ICES Statistical rectangle}
#'   \item{lon}{Longitude}
#'   \item{lat}{Latitude}
#' }
#' @source ICES DATRAS metadata.
"survey_info_full_raw"


#' Wolffish survey data (example dataset)
#'
#' Example ICES DATRAS data for *Anarhichas lupus* (wolffish) from survey
#' NS-IBTS Q1 in years 1991-2024.
#'
#' @format A list of class 'datras_raw' with 3 elements:
#' \describe{
#'   \item{CA}{Biological data}
#'   \item{HH}{Survey level information}
#'   \item{HL}{Length measurements}
#' }
#' @source ICES DATRAS database \url{https://datras.ices.dk}
"wolffish"


#' Spawning information lookup table
#'
#' A lookup table giving the spawning months of fish species by ICES area,
#' compiled from the GoFish and WKMAT sources.
#'
#' @format A data frame with the columns:
#' \describe{
#'   \item{species}{Scientific name of the species.}
#'   \item{aphia}{WoRMS AphiaID of the species.}
#'   \item{ices_area}{ICES area the record applies to (e.g. 3.d.27).}
#'   \item{spawn_months}{List column of integer months (1-12) in which the species spawns in that area.}
#'   \item{source}{Source(s) the spawning information was compiled from (e.g. gofish, wkmat).}
#'   \item{match_type}{How the area was matched to the source (e.g. exact_area, parent_area, neighbour_region).}
#'   \item{source_area}{ICES area of the original source record used for the match.}
#' }
#' @source \url{https://github.com/federico-maioli/length_at_maturity}
"spawning_info"
