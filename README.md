
<!-- badges: start -->
  [![R-CMD-check](https://github.com/tokami/DATRASextra/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tokami/DATRASextra/actions/workflows/R-CMD-check.yaml)
  [![codecov](https://codecov.io/gh/tokami/DATRASextra/graph/badge.svg?token=GLS9FJ47IP)](https://codecov.io/gh/tokami/DATRASextra)
  [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

<h1 style="border-bottom:none;">DATRASextra <a href='https://github.com/tokami/DATRASextra'><img src='man/figures/DATRASextra_logo.png' alt="DATRASextra logo" align="right" style="height:200px; margin-top:-40px;"/></a></h1>

Makes working with ICES **DATRAS** **extra** easy.

---

**DATRASextra** is an R package that simplifies working with the [ICES DATRAS
database](https://www.ices.dk/data/data-portals/pages/datras.aspx) by providing
practical functions and detailed documentation.

It builds on [DTU Aqua’s *DATRAS* R package](https://github.com/DTUAqua/DATRAS),
which provides the core functionality to download and modify DATRAS data —
commonly used to prepare abundance indices for ICES stock assessments.


**DATRASextra** adds tools for:
- Estimating spatial distributions and abundance indices across multiple surveys
- Calculating catch rates by custom length classes for single species or
  aggregations
- Streamlining the processing and preparation of *DATRAS* data for analysis

---


## Table of contents

- [Installation](#installation)
  - [Overview](#overview)
- [Getting help](#getting-help)
- [Citation](#citation)
- [Related software](#related-software)
- [Funding](#funding)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# Installation

The current version of the package allows to follow recommended data
processing protocols, reproduce the FishGlobe data set, estimate swept
area indices, and plot results. *DATRASextra* can be installed from
GitHub:

``` r
## Install the package
remotes::install_github("tokami/DATRASextra")
```

## Overview

*DATRASextra* provides a small set of functions that guide you through a
typical workflow with the ICES DATRAS database: from discovering
available surveys, to downloading, cleaning and checking the data, and
finally making quick plots of survey coverage and hauls. The table below
summarises the main user-facing functions.

| Function               | Description                                                                   |
|------------------------|-------------------------------------------------------------------------------|
| `listSurveys()`        | List available surveys in the ICES DATRAS database.                           |
| `downloadDATRAS()`     | Download the full DATRAS database or a filtered subset of it.                 |
| `readDATRAS()`         | Read DATRAS data into R.                                                      |
| `clean()`              | Clean and harmonise DATRAS data.                                              |
| `check()`              | Run general checks and flag potential outliers in DATRAS.                     |
| `prune()`              | Prune DATRAS data by removing or filtering problematic records.               |
| `addSweptAreaSimple()` | Calculate swept area per haul using gear-specific median values by gear type. |
| `checkLength()`        | Check length information and identify suspicious length distributions.        |
| `checkWeight()`        | Check weight information and length–weight consistency.                       |
| `plotHauls()`          | Plot haul locations.                                                          |
| `plotHaulsBySurvey()`  | Plot haul locations by survey.                                                |
| `plotSurveys()`        | Plot survey coverage and footprint.                                           |

# Getting help

A good starting point to start working with *DATRASextra* is the
tutorial vignette (`vignette("tutorial")`). More articles and help
documentation for *DATRASextra* can be found at
<https://tokami.github.io/DATRASextra/>.

In case, your question is not answered by the package documentation and
on the *pkgdown* pages, please write an email to the maintainer: [Tobias
Mildenberger](mailto:t.k.mildenberger@gmail.com). In case you find bugs,
please post an issue on
[here](https://github.com/tokami/DATRASextra/issues).

# Citation

Please use the R command `citation("DATRASextra")` to receive
information on how to cite this package.

# Related software

The foundation of *DATRASextra* is the R package
[*DATRAS*](https://github.com/DTUAqua/DATRAS). An alternative R package
for working with the DATRAS data base is
[*icesDATRAS*](https://github.com/ices-tools-prod/icesDatras) maintained
by ICES.

# Funding

The development of *DATRASextra* was funded by the European Maritime and
Fisheries Fund (EMFF) through the project: *FISHMAP - FISH distribution
and its role in fisheries Management Advice and marine spatial Planning*
(EFMVB-23-0031), which is co-financed by the EU through the Danish
Maritime, Fisheries and Aquaculture Fund.

------------------------------------------------------------------------

<figure>
<img src="man/figures/EN_Co-fundedbytheEU_RGB_POS.png" width="250"
alt="Logo: Co-funded by the EU" />
<figcaption aria-hidden="true">Logo: Co-funded by the EU</figcaption>
</figure>
