## Mini datras example data set
## created: 04/03/2026

library(DATRASextra)

tmp <- tempdir()

download_datras(surveys = c("NS-IBTS",
                           "BTS",
                           "EVHOE",
                           "BITS"),
               years = 2022:2023, path = tmp)

surv0 <- read_datras(file.path(tmp, c("NS-IBTS",
                                     "BTS",
                                     "EVHOE",
                                     "BITS")))

mini <- subset(surv0,
               Valid_Aphia %in% c(## Lophius piscatorius (European anglerfish /
                                    ## monkfish) — AphiaID 126555 Large,
                                  ## long-lived bathydemersal predator along
                                  ## shelf/shelf-edge (Barents→Biscay); shows
                                  ## broad, deep distribution.
                                  "126555",
                                  ## Lepidorhombus whiffiagonis (Megrim) —
                                  ## AphiaID 127146 Deeper-shelf flatfish,
                                  ## typically 100–400 m on soft bottoms; more
                                  ## western/southern shelf and slope.
                                  "127146",
                                  ## Hippoglossoides platessoides (Long rough
                                  ## dab / American plaice) — AphiaID 127137
                                  ## Cold-water flatfish, common in northern
                                  ## North Sea/Icelandic–Barents margins;
                                  ## relatively slow growth and long lifespan.
                                  "127137",
                                  ## Trisopterus esmarkii (Norway pout) —
                                  ## AphiaID 126444 Short-lived, schooling
                                  ## benthopelagic gadoid concentrated in the
                                  ## northern/central North Sea and Skagerrak;
                                  ## classic survey catch.
                                  "126444",
                                  ## Amblyraja radiata (Starry ray / thorny
                                  ## skate) — AphiaID 105865 Cold-water skate
                                  ## with slow maturation; widespread from
                                  ## Norwegian Sea to North Sea—regular in
                                  ## bottom trawls.
                                  "105865"))

format(object.size(mini), units = "auto") ## 10.1 Mb

class(mini)

usethis::use_data(mini, overwrite = TRUE)
