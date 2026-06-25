# The datras_raw object

This article describes the `datras_raw` object, the data structure used
throughout **DATRASextra**. We use the example data set `dab` (dab,
*Limanda limanda*, from NS-IBTS in 2020-2023).

``` r

## Load the package
library(DATRASextra)

## Load the example data
data(dab)
```

## Structure

A `datras_raw` object is a list of three data frames, with classes
`datras_raw` and `DATRASraw`:

``` r

## Class and elements
class(dab)
#> [1] "datras_raw" "DATRASraw"
names(dab)
#> [1] "CA" "HH" "HL"
```

The `DATRASraw` class is kept for backward compatibility with the
[**DATRAS** R package](https://github.com/DTUAqua/DATRAS), so its
functions keep working on a `datras_raw` object.

The three tables follow the DATRAS exchange format:

- `HH`: haul data. One row per haul (position, time, depth, gear,
  environment).
- `HL`: length data. Catch-at-length per species and length class.
- `CA`: age-length data. Individual length, weight, sex, maturity, age.

They are linked by `haul.id`, which is present in all three tables.

Printing the object gives a survey overview:

``` r

## Survey overview
dab
#> Object of class 'datras_raw'
#> ===========================
#> Number of hauls: 2651 
#> Number of species: 1 
#> Number of countries: 8 
#> Years: 2020 - 2023 
#> Quarters: 1 3 
#> Gears: GOV 
#> Haul duration: 5 - 34 minutes
#> Valid hauls: 2651
#> Hauls with catch: 2255 (zero catch: 396)
#> Longitude range: -3.96 - 12.61 deg
#> Latitude range: 49.57 - 61.75 deg
#> Depth range: 14 - 257 m
```

## Indexing

Use `[[ ]]` to reach a table:

``` r

## The haul table
hh <- dab[["HH"]]
dim(hh)
#> [1] 2651   76
```

Within a table, columns are accessed and assigned with `$` as usual:

``` r

## A single column and a few columns
head(dab[["HH"]]$Depth)
#> [1] 151 144 105  72 102 128
head(dab[["HH"]][, c("Year", "Quarter", "Gear", "Depth")])
#>   Year Quarter Gear Depth
#> 1 2020       1  GOV   151
#> 2 2020       1  GOV   144
#> 3 2020       1  GOV   105
#> 4 2020       1  GOV    72
#> 5 2020       1  GOV   102
#> 6 2020       1  GOV   128

## Add or modify a column
dab[["HH"]]$DepthLog <- log(dab[["HH"]]$Depth)
head(dab[["HH"]]$DepthLog)
#> [1] 5.017280 4.969813 4.653960 4.276666 4.624973 4.852030
```

[`subset()`](https://rdrr.io/r/base/subset.html) filters the whole
object and keeps the three tables consistent (dropping a haul from `HH`
also drops its `HL` and `CA` records):

``` r

## Keep valid hauls from quarter 1
q1 <- subset(dab, Quarter == 1 & HaulVal == "V")
q1
#> Object of class 'datras_raw'
#> ===========================
#> Number of hauls: 1268 
#> Number of species: 1 
#> Number of countries: 7 
#> Years: 2020 - 2023 
#> Quarters: 1 
#> Gears: GOV 
#> Haul duration: 15 - 34 minutes
#> Valid hauls: 1268
#> Hauls with catch: 1133 (zero catch: 135)
#> Longitude range: -3.96 - 12.61 deg
#> Latitude range: 49.57 - 61.74 deg
#> Depth range: 14 - 257 m
```

## Coded variables (ICES vocabulary)

Many variables are stored as codes (`Gear`, `Country`, `Ship`,
`StatRec`), and species as a WoRMS AphiaID in `Valid_Aphia`:

``` r

## Gear codes and species AphiaID
levels(factor(as.character(dab[["HH"]][["Gear"]])))
#> [1] "GOV"
unique(dab[["HL"]][["Valid_Aphia"]])
#> [1] 127139
```

Definitions for these codes are in the [ICES
vocabulary](https://vocab.ices.dk/) and the [DATRAS data
resources](https://datras.ices.dk/Data_products/DataResources.aspx). The
`species_info` table also maps AphiaIDs to scientific names and
ecological groups.

## Numbers-at-length: the `N` matrix

[`add_numbers_at_length()`](https://tokami.github.io/DATRASextra/reference/add_numbers_at_length.md)
raises the `HL` counts to the haul level and stores the result as a
matrix `N` in `HH`, one row per haul and one column per length class:

``` r

## Add numbers-at-length
dab <- add_numbers_at_length(dab)

## One row per haul, one column per length class
## (showing the five largest catches and a few length classes)
big <- head(order(rowSums(dab[["HH"]][["N"]]), decreasing = TRUE), 5)
dab[["HH"]][["N"]][big, 13:17]
#>                                    sizeGroup
#> haul.id                             [15,16) [16,17) [17,18) [18,19) [19,20)
#>   NS-IBTS:2021:3:DE:26D4:GOV:140:15    1452    1340    2345    1005     782
#>   NS-IBTS:2020:1:SE:77SE:GOV:3:3       4454    3093    2846    1485     495
#>   NS-IBTS:2021:3:GB:74E9:GOV:6:7        662     993     794     728     331
#>   NS-IBTS:2020:3:DK:26D4:GOV:175:55     490    2082    2817     857     245
#>   NS-IBTS:2022:3:GB:74E9:GOV:29:25      607     700     677     443     513
```

Length classes can be changed with `cm_breaks` or `by`; see
[`vignette("articles/custom-length-classes")`](https://tokami.github.io/DATRASextra/articles/custom-length-classes.md).

## Weight-at-length: the `Wgt` matrix

[`add_weight_at_length()`](https://tokami.github.io/DATRASextra/reference/add_weight_at_length.md)
converts numbers to weight using a length-weight relationship and adds a
matrix `Wgt` to `HH` with the same shape as `N`:

``` r

## Add weight-at-length
dab <- add_weight_at_length(dab)

## Same hauls and length classes as above, now in weight
dab[["HH"]][["Wgt"]][big, 13:17]
#>                                    sizeGroup
#> haul.id                               [15,16)   [16,17)   [17,18)   [18,19)
#>   NS-IBTS:2021:3:DE:26D4:GOV:140:15  63737.80  70670.56 147078.61  74281.74
#>   NS-IBTS:2020:1:SE:77SE:GOV:3:3    195515.27 163122.41 178501.37 109759.58
#>   NS-IBTS:2021:3:GB:74E9:GOV:6:7     29059.52  52370.05  49799.75  53808.07
#>   NS-IBTS:2020:3:DK:26D4:GOV:175:55  21509.31 109803.06 176682.49  63342.74
#>   NS-IBTS:2022:3:GB:74E9:GOV:29:25   26645.21  36917.46  42461.50  32743.09
#>                                    sizeGroup
#> haul.id                               [19,20)
#>   NS-IBTS:2021:3:DE:26D4:GOV:140:15  67556.18
#>   NS-IBTS:2020:1:SE:77SE:GOV:3:3     42762.54
#>   NS-IBTS:2021:3:GB:74E9:GOV:6:7     28594.75
#>   NS-IBTS:2020:3:DK:26D4:GOV:175:55  21165.30
#>   NS-IBTS:2022:3:GB:74E9:GOV:29:25   44317.54
```

Summing these matrices over their columns gives total numbers and weight
per haul, via
[`add_total_numbers_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_numbers_by_haul.md)
and
[`add_total_weight_by_haul()`](https://tokami.github.io/DATRASextra/reference/add_total_weight_by_haul.md)
(see the [step-by-step
guide](https://tokami.github.io/DATRASextra/articles/datrasextra-tutorial.md)).
