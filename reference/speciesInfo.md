# Species information lookup table

A lookup table linking ICES species codes to names and ecological
groups.

## Usage

``` r
speciesInfo
```

## Format

A data frame with columns:

- WoRMS_AphiaID:

  Numeric AphiaID identifier from the World Register of Marine Species
  (WoRMS).

- ScientificName_WoRMS:

  Full scientific name of the species according to WoRMS.

- genus:

  Genus name of the species.

- family:

  Family name of the species.

- order:

  Taxonomic order of the species.

- class:

  Taxonomic class of the species.

- rank:

  Taxonomic rank of the record (e.g., species, genus).

- habitat:

  General habitat category (e.g., marine, brackish, freshwater).

- bodyShape:

  General body shape category (e.g., fusiform, elongate, flat).

- maxL:

  Maximum observed length (cm).

- Lm:

  Length at maturity (cm).

- a:

  Length–weight relationship parameter \\a\\ (in \\W = a L^b\\).

- b:

  Length–weight relationship parameter \\b\\ (in \\W = a L^b\\).

- Loo:

  Asymptotic length from the von Bertalanffy growth model (cm).

- K:

  Growth coefficient from the von Bertalanffy model (1/year).

- to:

  Theoretical age at zero length \\t_0\\ from the von Bertalanffy model
  (years).

- habitat2:

  Alternative or refined habitat classification.

- funcGroupFB:

  Functional group according to FishBase.

- funcGroupWalker:

  Functional group following Walker et al. (2017).

- funcGroupDenderen:

  Functional group following van Denderen et al. (2020).

- funcGroupMildenberger:

  Functional group following Mildenberger et al. (2025).

- funcGroupWalkerAll:

  Unified or merged functional grouping combining multiple
  classification sources.

- aFG:

  Length–weight relationship parameter \\a\\ (in \\W = a L^b\\) used in
  FishGlobe.

- bFG:

  Length–weight relationship parameter \\b\\ (in \\W = a L^b\\) used in
  FishGlobe.

## Source

ICES DATRAS species reference list.
