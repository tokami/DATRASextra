# DATRASextra

Makes working with ICES **DATRAS** **extra** easy!

**DATRASextra** is an R package that extends the functionality of the
[ICES DATRAS
database](https://www.ices.dk/data/data-portals/pages/datras.aspx) and
the [DTU Aqua *DATRAS* R package](https://github.com/DTUAqua/DATRAS),
providing practical tools for downloading, cleaning, standardising,
analysing, and visualising bottom-trawl survey data.

Key features include:

- Streamlined workflows for downloading, cleaning, and preparing DATRAS
  data
- Calculation and visualisation of swept area, catch rates, biomass, and
  numbers-at-length for custom length classes
- Support for reproducing key components of the FishGlob data-processing
  workflow
- Tools for species harmonisation, taxonomic standardisation, and
  exploratory diagnostics

# Installation

*DATRASextra* can be installed from GitHub:

``` r

## Install the package
remotes::install_github("tokami/DATRASextra")
```

Or the development version:

``` r

## Install the package
remotes::install_github("tokami/DATRASextra", ref = "dev")
```

Note that if you want to install vignettes locally, you have to use an
extra argument:

``` r

## Install the package with vignettes
remotes::install_github("tokami/DATRASextra", build_vignettes = TRUE)
```

# Overview

*DATRASextra* provides a set of powerful functions that guide you
through a typical workflow with the ICES DATRAS database: from
discovering available surveys, to downloading, cleaning and checking the
data, and finally making quick plots of survey coverage and hauls. The
table below summarises the main user-facing functions.

| Function | Description |
|----|----|
| [`list_surveys()`](https://tokami.github.io/DATRASextra/reference/list_surveys.md) | List available surveys in the ICES DATRAS database. |
| [`plot_datras_overview()`](https://tokami.github.io/DATRASextra/reference/plot_datras_overview.md) | Plot haul locations |
| [`download_datras()`](https://tokami.github.io/DATRASextra/reference/download_datras.md) | Download the full or filtered subset of the DATRAS database. |
| [`read_datras()`](https://tokami.github.io/DATRASextra/reference/read_datras.md) | Read DATRAS data into R. |
| [`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md) | Clean and harmonise DATRAS data. |
| [`check_outliers()`](https://tokami.github.io/DATRASextra/reference/check_outliers.md) | Flag (and remove) hauls with invalid or extreme values. |
| [`prune_datras()`](https://tokami.github.io/DATRASextra/reference/prune_datras.md) | Prune DATRAS data by removing or filtering problematic records. |
| [`add_swept_area()`](https://tokami.github.io/DATRASextra/reference/add_swept_area.md) | Calculate swept area per haul using gear-specific median values by gear type. |
| [`check_lengths()`](https://tokami.github.io/DATRASextra/reference/check_lengths.md) | Check length information and identify suspicious length distributions. |
| [`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md) | Calculate the numbers by specified length classes and add it to the HH data set. |
| [`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md) | Calculate total numbers by haul and add it to the HH data set. |
| [`check_weights()`](https://tokami.github.io/DATRASextra/reference/check_weights.md) | Check weight information and length–weight consistency. |
| [`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md) | Convert the numbers at length classes to weight at length classes and add it to the HH data set. |
| [`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md) | Calculate total weight by haul and add it to the HH data set. |

# Getting started

The best introduction to *DATRASextra* is the tutorial vignette, which
walks through a complete workflow: downloading data from the DATRAS
database, performing recommended quality checks and data processing
steps, and transforming survey observations into standardised numbers
and biomass by species, haul, and length class for use in abundance and
biomass index calculations.

The tutorial is available on the package website under **Articles →
Getting started**:
<https://tokami.github.io/DATRASextra/articles/datrasextra-tutorial.html>

If you installed the package with `build_vignettes = TRUE`, you can also
open the tutorial directly from R:

``` r

vignette("datrasextra-tutorial")
```

# Getting help

All functions in *DATRASextra* are documented and include examples. Help
pages can be accessed using
[`help()`](https://rdrr.io/r/utils/help.html) or `?`, for example:

``` r

?check_lengths
```

Additional tutorials and worked examples are available on the package
website, demonstrating common workflows and applications of DATRAS
survey data: <https://tokami.github.io/DATRASextra/>

If your question is not answered by the package documentation or the
`pkgdown` site, you are welcome to contact the maintainer, [Tobias
Mildenberger](mailto:t.k.mildenberger@gmail.com). If you find a bug or
would like to request a feature, please open an issue on GitHub with:
<https://github.com/tokami/DATRASextra/issues/new/choose>

# Citation

To see how to cite *DATRASextra* in your work, run:

``` r

citation("DATRASextra")
```

# Related software

*DATRASextra* was originally developed to extend the functionality of
the R package *DATRAS*, which provides tools for accessing and working
with ICES DATRAS survey data. While *DATRASextra* continues to build on
some of this functionality, it has evolved into a broader framework for
downloading, managing, processing, and analysing DATRAS data, with an
increasing share of functionality implemented directly within the
package.

An alternative R package for accessing DATRAS data is *icesDatras*,
which is maintained by ICES and provides a direct interface to the
DATRAS database.

# Funding

The development of *DATRASextra* was funded by the European Maritime and
Fisheries Fund (EMFF) through the project: *FISHMAP - FISH distribution
and its role in fisheries Management Advice and marine spatial Planning*
(EFMVB-23-0031), which is co-financed by the EU through the Danish
Maritime, Fisheries and Aquaculture Fund.

------------------------------------------------------------------------

![Logo: Co-funded by the
EU](reference/figures/EN_Co-fundedbytheEU_RGB_POS.png)

Logo: Co-funded by the EU
