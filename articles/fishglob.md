# Processing ICES DATRAS Data for FishGlob

## Background

The **FishGlob** database is a global compilation of standardized
scientific trawl survey data used to study large-scale patterns in
marine fish biodiversity and community structure.

FishGlob harmonizes data from multiple regional monitoring programs by
standardizing:

- taxonomic information  
- sampling effort  
- catch metrics (abundance and biomass per unit area)

The dataset integrates numerous long-term fisheries-independent surveys,
including several surveys available through the **ICES DATRAS**
database.

**ICES DATRAS** (Database of Trawl Surveys) provides access to
standardized survey data collected in European seas, including
haul-level sampling information (HH), length distributions (HL), and
individual data (CA).

The **`DATRASextra`** package provides tools to process raw DATRAS
survey data and generate outputs that are compatible with the **FishGlob
data structure**.

This vignette demonstrates a workflow to:

- download DATRAS survey data  
- harmonize and clean raw survey tables  
- standardize species taxonomy  
- estimate swept area and biomass  
- generate FishGlob-compatible datasets

The workflow can be applied to a single species or to multiple species.
For illustration, this vignette uses `mini`.

``` r
data("mini", package = "DATRASextra")
```

an example dataset containing 5 species across 4 surveys (BITS, BTS,
EVHOE, NS-IBTS):

Amblyraja radiata, Hippoglossoides platessoides, Lophius piscatorius,
Trisopterus esmarkii, Lepidorhombus whiffiagonis

## References

Maureaud, A., et al. (2021) FISHGLOB_data: an integrated dataset of fish
biodiversity sampled with scientific bottom-trawl surveys. Sci Data 11,
24 (2024). <https://doi.org/10.1038/s41597-023-02866-w>

ICES Database on Trawl Surveys (DATRAS), ICES, Copenhagen, Denmark.
<https://datras.ices.dk>

## Libraries

``` r
library(DATRASextra)
```

    ## Loading required package: DATRAS

## Load the dataset

``` r
data(mini)
```

## Clean the dataset

The
[`cleanFishglob()`](https://tokami.github.io/DATRASextra/reference/cleanFishglob.md)
function harmonizes the raw DATRAS tables and prepares them for
processing. Species names and identifiers are standardized using WoRMS
taxonomy with
[`correctSpecies()`](https://tokami.github.io/DATRASextra/reference/correctSpecies.md)
This step ensures:

- consistent scientific names  
- valid **AphiaID identifiers**  
- standardized taxonomic classification

``` r
dat <- cleanFishglob(mini)
```

## Reduce dataset size

The raw dataset contains many variables that are not required for the
FishGlob output.

The
[`pruneFishglob()`](https://tokami.github.io/DATRASextra/reference/pruneFishglob.md)
function removes unnecessary columns to reduce memory usage and improve
processing speed.

``` r
dat <- pruneFishglob(dat)
```

## Compute swept area

Catch per unit area requires an estimate of the **area swept by each
haul**.

The function below:

- calculates swept area when gear information is available  
- imputes missing values when necessary

``` r
dat <- addSweptAreaFishGlob(dat)
```

## Estimate biomass

FishGlob reports both **numbers** and **biomass**.

The
[`addWeightFishglob()`](https://tokami.github.io/DATRASextra/reference/addWeightFishglob.md)
function converts length data to weight using species-specific
**length–weight relationships**.

``` r
dat <- addWeightFishglob(dat)
```

## Format the FishGlob output

Finally, the dataset is formatted to match the **FishGlob data
structure**.

``` r
datras <- formatFishglob.DATRASraw(dat)

head(datras)
```

    ##    survey      source timestamp                          haul_id
    ## 2    BITS DATRAS ICES   2026-03 BITS:2022:1:DE:06SL:TVS:22008:15
    ## 9    BITS DATRAS ICES   2026-03  BITS:2022:1:DE:06SL:TVS:22135:7
    ## 10   BITS DATRAS ICES   2026-03  BITS:2022:1:DE:06SL:TVS:22135:7
    ## 15   BITS DATRAS ICES   2026-03 BITS:2022:1:DE:06SL:TVS:22144:10
    ## 92   BITS DATRAS ICES   2026-03      BITS:2022:1:DK:26HF:TVS:1:1
    ## 98   BITS DATRAS ICES   2026-03     BITS:2022:1:DK:26HF:TVS:11:6
    ##            country sub_area continent stat_rec station stratum year month day
    ## 2  multi-countries     <NA>    europe     37G1    <NA>    <NA> 2022     2  27
    ## 9  multi-countries     <NA>    europe     38G1    <NA>    <NA> 2022     2  25
    ## 10 multi-countries     <NA>    europe     38G1    <NA>    <NA> 2022     2  25
    ## 15 multi-countries     <NA>    europe     37G1    <NA>    <NA> 2022     2  26
    ## 92 multi-countries     <NA>    europe     44G0    <NA>    <NA> 2022     2  22
    ## 98 multi-countries     <NA>    europe     43G1    <NA>    <NA> 2022     2  23
    ##    quarter latitude longitude haul_dur gear depth     num num_cpue   num_cpua
    ## 2        1  54.2901   11.9190      0.5  TVS    20   1.000    2.000   12.95883
    ## 9        1  54.5979   11.2168      0.5  TVS    27   4.000    8.000   52.26729
    ## 10       1  54.5979   11.2168      0.5  TVS    27   4.000    8.000   52.26729
    ## 15       1  54.3062   11.4463      0.5  TVS    24   1.000    2.000   13.51824
    ## 92       1  57.5363   10.6308      0.5  TVS    18  10.000   20.000  134.36219
    ## 98       1  57.2208   11.5636      0.5  TVS    60 201.488  402.976 2717.41887
    ##            wgt    wgt_cpue    wgt_cpua verbatim_name verbatim_aphia_id
    ## 2  0.004903505 0.009807011  0.06354367          <NA>                NA
    ## 9  0.034329711 0.068659423  0.44858023          <NA>                NA
    ## 10 0.012798297 0.025596595  0.16723307          <NA>                NA
    ## 15 0.007084435 0.014168869  0.09576912          <NA>                NA
    ## 92 0.076120170 0.152240341  1.02276730          <NA>                NA
    ## 98 3.546887926 7.093775851 47.83600107          <NA>                NA
    ##                   accepted_name aphia_id     class             order
    ## 2          Trisopterus esmarkii   126444 Teleostei        Gadiformes
    ## 9  Hippoglossoides platessoides   127137 Teleostei Pleuronectiformes
    ## 10         Trisopterus esmarkii   126444 Teleostei        Gadiformes
    ## 15 Hippoglossoides platessoides   127137 Teleostei Pleuronectiformes
    ## 92 Hippoglossoides platessoides   127137 Teleostei Pleuronectiformes
    ## 98 Hippoglossoides platessoides   127137 Teleostei Pleuronectiformes
    ##            family           genus    rank survey_unit
    ## 2         Gadidae     Trisopterus Species      BITS-1
    ## 9  Pleuronectidae Hippoglossoides Species      BITS-1
    ## 10        Gadidae     Trisopterus Species      BITS-1
    ## 15 Pleuronectidae Hippoglossoides Species      BITS-1
    ## 92 Pleuronectidae Hippoglossoides Species      BITS-1
    ## 98 Pleuronectidae Hippoglossoides Species      BITS-1

## Downloading the FishGlob DATRAS surveys

The previous example used a small dataset to keep the vignette
lightweight.  
To reproduce the **DATRAS part of the FishGlob dataset**, the full set
of surveys used in FishGlob can be downloaded like this:

``` r
library(DATRASextra)

surveys <- c("NS-IBTS", "EVHOE", "SWC-IBTS", "BITS", "IE-IGFS",
             "FR-CGFS", "NIGFS", "ROCKALL", "PT-IBTS",
             "SP-NORTH", "SP-ARSA", "SP-PORC")

# create temporary directory
tmp <- tempdir()

# download survey data
downloadDATRAS(surveys = surveys, dir = tmp)

# read raw DATRAS tables
raw <- readDATRAS(file.path(tmp, surveys))
```

Downloading and processing these surveys take some time, as they include
multiple decades of trawl survey data.
