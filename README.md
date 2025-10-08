
<!-- README.md is generated from README.Rmd. Please edit that file -->

# DATRASextra <a href='https://github.com/tokami/DATRASextra'><img src='man/figures/logo.png' align="right" style="height:139px;"/></a>

> Useful functions for working with ICES DATRAS

<!-- badges: start -->
  [![R-CMD-check](https://github.com/tokami/DATRASextra/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tokami/DATRASextra/actions/workflows/R-CMD-check.yaml)
  [![Codecov test
  coverage](https://codecov.io/gh/tokami/DATRASextra/branch/main/graph/badge.svg)](https://app.codecov.io/gh/tokami/DATRASextra?branch=main)
  [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
<!-- badges: end -->

*DATRASextra* is a new R package that provides useful additional functions to
work with [DTU Aqua's *DATRAS* R package](https://github.com/DTUAqua/DATRAS) and
[ICES' DATRAS
database](https://www.ices.dk/data/data-portals/pages/datras.aspx).


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

To get started with *DATRASextra*, install and load the package,
download some survey information from DATRAS and start analyzing:

``` r
## remotes::install_github("tokami/DATRASextra")
library(DATRASextra)

survey <- "SNS"
tmp <- tempdir()
downloadDATRAS(surveys = survey, years = 2023, dir = tmp)

surv0 <- readDATRAS(file.path(tmp, survey))

surv <- clean(surv0)

plot(surv)
```

## Overview

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

## Advanced use

## Related software

## Funding

The development of *DATRASextra* was cofunded by the European Union.

------------------------------------------------------------------------

<figure>
<img src="man/figures/EN_Co-fundedbytheEU_RGB_POS.png" width="250"
alt="Co-funded by the EU logo" />
<figcaption aria-hidden="true">Co-funded by the EU logo</figcaption>
</figure>
