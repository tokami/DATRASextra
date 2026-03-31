---
title: "DATRASextra: An R package for streamlined workflows with ICES DATRAS bottom-trawl
  survey data"
tags:
- R
- fisheries
- ecology
- survey data
- reproducibility
date: "31 March 2026"
output:
  html_document:
    df_print: paged
authors:
- name: Tobias K. Mildenberger
  corresponding: true
  affiliation: 1
  orcid: 0000-0002-6631-7524
- name: Federico Maioli
  affiliation: 1
  orcid: 0000-0002-8305-1609
- name: Casper W. Berg
  affiliation: 1
  orcid: 0000-0002-3812-5269
affiliations:
- name: Technical University of Denmark, National Institute of Aquatic Resources (DTU
    Aqua), Denmark
  index: 1
csl: apa.csl
link-citations: true
bibliography: datrasextra.bib
---

# Summary

Fisheries-independent data from scientific marine bottom-trawl surveys are central to monitoring fish communities across space and time. These surveys provide abundance indices used to estimate stock status, recruitment, and biological reference points. In the Northeast Atlantic and adjacent seas, the ICES Database of Trawl Surveys (DATRAS) serves as a central repository for such data, currently compiling information from 28 surveys over 60 years [@ICESDATRAS].

DATRAS data underpin a wide range of scientific and advisory applications, including single-stock assessments, where survey indices inform trends in abundance, recruitment, and size structure, as well as biodiversity assessments based on long-term spatial monitoring. More recently, DATRAS data have also been used in large-scale syntheses such as the FISHGLOB initiative, which integrates bottom-trawl survey data across regions [@Maureaud2024FishGlobData; @Maureaud2025FishGlob].

Despite standardised data formats and internal validation within DATRAS, practical data workflows remain complex. Users typically need to download and combine multiple data tables (e.g. haul, length, and biological data), apply survey-specific filtering and harmonisation, implement quality control, and construct reproducible, analysis-ready datasets. These challenges have motivated the development of best-practice guidelines for survey data processing and integration [e.g. @WKFISHDISH2].

The `DATRASextra` R package addresses these challenges by providing a coherent and reproducible workflow for working with DATRAS data. It offers tools to (i) download and archive complete or user-defined subsets of DATRAS data, (ii) apply standardised data-cleaning and quality-control routines, including outlier detection, (iii) generate analysis-ready outputs such as abundance and biomass indices by length and age, and (iv) support these workflows through comprehensive documentation and end-to-end examples. `DATRASextra` builds on the DATRAS web services and existing R packages such as `icesDatras` [@icesDatras] and `DATRAS` [@kristensen2018datras], while integrating established community guidelines for bottom-trawl survey data processing and cross-survey integration [@WKFISHDISH2; @Maureaud2024FishGlobData].

# Statement of need

Working with large, heterogeneous ecological datasets requires substantial data processing, quality assurance, and documentation to ensure reproducible analyses. The DATRAS database contains long-term biological survey data from 28 bottom-trawl surveys in the Northeast Atlantic, with some time series extending back to 1965. The database comprises information from 142,000 hauls, about 2,000 AphiaIDs, and more than 20 million individual records across multiple linked tables, including haul-level, length-based, and biological observations.

Although DATRAS provides standardised data formats and validation procedures, there is currently no single, well-documented R package that supports complete end-to-end workflows for accessing, processing, and analysing these data. The existing packages icesDatras [@icesDatras] and DATRAS [@kristensen2018datras] facilitate data access and basic handling but do not provide integrated tools for data cleaning, quality control, and the generation of analysis-ready outputs.

`DATRASextra` fills this gap by providing a user-friendly and well-documented toolbox that supports the full workflow from raw data access to analysis-ready products. The package includes functions for harmonising multiple surveys and species, implementing reproducible quality-control procedures, and producing standard outputs such as abundance and biomass indices. In addition, it provides a suite of end-to-end vignettes that demonstrate typical workflows, including reproducing the Northeast Atlantic component of the FISHGLOB dataset [@Maureaud2024FishGlobData]. By consolidating these steps into a single, reproducible framework, DATRASextra reduces the complexity of working with DATRAS data and facilitates transparent and standardised analyses across users and applications. For example, reproducing the Northeast Atlantic component of the FISHGLOB dataset can be done with six lines of code rather than thousands of lines of code.

# Features

DATRASextra provides a set of tools that support end-to-end workflows for working with DATRAS data. Core functionality includes:

-   reproducible download and local archiving of complete or user-defined subsets of DATRAS data,

-   standardised data cleaning, quality-control procedures, and outlier screening with haul-level diagnostics,

-   generation of analysis-ready datasets, including haul-level abundance and biomass observations by length and age,

-   integration of multiple surveys to analyse spatial distributions beyond individual survey footprints, and

-   reproduction of standardised processing steps used in large-scale synthesis efforts (e.g. FISHGLOB-style workflows) [@Maureaud2024FishGlobData].

The following example illustrates how survey data can be downloaded, processed, and used to visualise haul-level catch rates for Atlantic cod (Gadus morhua) in space and time \autoref{fig:map}.

![Example output from `DATRASextra` showing the spatial distribution of Atlantic cod (*Gadus morhua*) based on haul observations from the NS-IBTS survey (2021--2024). Point size reflects haul-level catch rates standardised by swept area.\label{fig:map}](cod_map.png)

``` r
# Download NS-IBTS (2021–2024)
dat <- download_datras(surveys = "NS-IBTS", years = 2021:2024)

# Apply standard data processing and subset Atlantic cod
cod <- clean_datras(dat, aphias = "126436")

# Add total numbers per haul
cod <- add_total_numbers_by_haul(cod)

# Add swept area
cod <- add_swept_area(cod)

# Plot haul-level catch rates in space and time
plot_haul_map(cod)
```

The resulting haul-level quantities (e.g. total numbers or catch rates) can be used directly as input to standardisation models to derive abundance indices for trend analysis or stock assessment. With minor extensions, the same workflow can be applied to specific length or age groups, multiple species or surveys, or to biomass-based quantities. These and other use cases are demonstrated in the package vignettes.

Full documentation and examples are available at <https://tokami.github.io/DATRASextra> and via the package vignette (vignette("datrasextra-tutorial")).

# Licensing and availability

`DATRASextra` is an open-source R package [@RCoreTeam] released under the GNU General Public License (GPL-3.0). The source code is publicly available at <https://github.com/tokami/DATRASextra>. A dedicated pkgdown website [@wickham2025pkgdown] provides comprehensive documentation, including function references, tutorials, and example workflows.

# Acknowledgements

We acknowledge ICES and the national institutes contributing survey data to DATRAS for maintaining and curating this essential resource [@ICESDATRAS]. We thank the developers of the icesDatras package and participants in ICES workshops and working groups (including WKFISHDISH2) for developing and sharing best-practice guidance for survey data processing and integration [@icesDatras; @WKFISHDISH2]. We also acknowledge the developers and maintainers of the FISHGLOB data set [@Maureaud2024FishGlobData].

This work was funded by the European Maritime and Fisheries Fund (EMFF) through the project FISHMAP: Fish distribution and its role in fisheries management advice and marine spatial planning (EFMVB-23-0031), co-financed by the EU through the Danish Maritime, Fisheries and Aquaculture Fund.

# AI usage disclosure

OpenAI’s ChatGPT (GPT-5.2 Thinking; accessed March 2026) was used for copy-editing portions of the manuscript and suggesting wording and structure for documentation describing the package functionality. All AI-assisted outputs were reviewed, edited, and validated by the authors, who retain full responsibility for the accuracy, originality, licensing, and ethical and legal compliance of the manuscript, documentation, and software.

# References
