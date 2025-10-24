
<!-- badges: start -->
  [![R-CMD-check](https://github.com/tokami/DATRASextra/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tokami/DATRASextra/actions/workflows/R-CMD-check.yaml)
  [![Codecov test
  coverage](https://codecov.io/gh/tokami/DATRASextra/branch/main/graph/badge.svg)](https://app.codecov.io/gh/tokami/DATRASextra?branch=main)
  [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

<h1 style="border-bottom:none;">DATRASextra <a href='https://github.com/tokami/DATRASextra'><img src='man/figures/DATRASextra_logo.png' alt="DATRASextra logo" align="right" style="height:200px; margin-top:-40px;"/></a></h1>

<br>
Makes working with ICES **DATRAS** **extra** easy.
<br>

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
- [Basic use](#basic-use)
- [Advanced use](#advanced-use)
- [Related software](#related-software)
- [Funding](#funding)

<!-- README.md is generated from README.Rmd. Please edit that file -->

## Installation

The current version of the package allows to follow described data
processing protocols, estimate swept area indices and plot results.

To get started with *DATRASextra*, install and load the package:

``` r

## Install the package
remotes::install_github("tokami/DATRASextra")

## Load the package into R
library(DATRASextra)
```

## Overview

Overview over DATRASextra

## Getting help

More detailed examples and documentation for *DATRASextra* can be found
at <https://tokami.github.io/DATRASextra/>. The *pkgdown* page includes
links to articles, vignettes, functions descriptions, information to
version updates, and much more. In case, your question is not answered
by the package documentation and on the *pkgdown* pages, please write an
email to the maintainer: [Tobias
Mildenberger](mailto:t.k.mildenberger@gmail.com). In case you find bugs,
please post an issue on
[here](https://github.com/tokami/DATRASextra/issues).

## Citation

Please use the R command `citation("DATRASextra")` to receive
information on how to cite this package.

## Basic use

DATRASextra makes it easy to download survey data from ICES DATRAS
database:

``` r
survey <- "SNS"
tmp <- tempdir()
downloadDATRAS(surveys = survey, years = 2023, dir = tmp)
```

This mainly uses the functionality of the DATRAS R package but allows a
bit more flexibility, like specifying the path were the data should be
installed to.

Next, the data can be read into R with:

``` r
surv0 <- readDATRAS(file.path(tmp, survey))
```

Now, you can process, subset, modify and analyse the data:

``` r
surv <- clean(surv0)

plot(surv)
```

## Advanced use

Demo of one advanced use case.

``` r
surv <- clean(surv0)

plot(surv)
```

More advanced options are shown in the vignettes.

## Related software

## Funding

The development of *DATRASextra* was cofunded by the European Union.

------------------------------------------------------------------------

<figure>
<img src="man/figures/EN_Co-fundedbytheEU_RGB_POS.png" width="250"
alt="Logo: Co-funded by the EU" />
<figcaption aria-hidden="true">Logo: Co-funded by the EU</figcaption>
</figure>
