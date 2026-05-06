# Extract abundance or biomass per unit effort for a single species

``` r


library(DATRASextra)

# select survey

survey <- "NS-IBTS"

# create temporary directory

tmp <- file.path(tempdir(), "DATRASextra")

dir.create(tmp, recursive = TRUE, showWarnings = FALSE)

# download data

download_datras(
  surveys = survey,
  years = 2021,
  dir = tmp
)

# read in
surv0 <- read_datras(file.path(tmp, survey))

# clean data
surv <- clean_datras(surv0)

# subset for your species
surv <- subset(surv, Valid_Aphia == "126822") # Horse mackerel
```

To calculate abundance or biomass per unit effort, the information in
the `HL` table first needs to be raised to the haul level. A convenient
first step is to add numbers-at-length:

``` r


surv <- add_numbers_at_length(surv)
```

This adds a matrix `N` to the `HH` table, containing the estimated
numbers in each length class for each haul. The length classes can be
modified with the `cm_breaks` or `by` arguments. The total abundance by
haul can then be obtained by summing over length classes:

``` r


surv <- add_total_numbers_by_haul(surv)
```

By default, this adds a single column `HaulN` to the `HH` table. More
generally, custom bins can be specified via `length_cuts`. In that case,
the result may contain separate totals for broader user-defined length
groups.

If species-specific length and weight information are available in `CA`,
or suitable length-weight relationships are available in the
`species_info` table, the numbers can also be converted to biomass:

``` r


surv <- add_total_weight_by_haul(surv)
```

This adds `HaulWgt` to the `HH` table, containing the total estimated
biomass by haul. To standardize abundance and biomass by swept area, a
swept-area estimate can be added to each haul:

``` r


surv <- add_swept_area_simple(surv)
```

This adds swept-area estimates to the `HH` table based on haul distance
and gear width information. When gear information is missing, values are
imputed automatically (see
[`?add_swept_area_simple`](https://tokami.github.io/DATRASextra/reference/add_swept_area_simple.md)).
Abundance per unit effort and biomass per unit effort can then be
calculated by dividing haul-level totals by swept area:

``` r


# convert swept area from m2 to km2
surv[['HH']]$SweptArea_km2 <- surv$HH$SweptArea / 1e6

# abundance per km2
surv[['HH']]$CPUE_N <- surv$HH$HaulN / surv$HH$SweptArea_km2

# biomass per km2
surv[['HH']]$CPUE_W <- surv$HH$HaulWgt / surv$HH$SweptArea_km2
```

The resulting variables contain standardized density estimates expressed
as:

- numbers per \\km^2\\ (`CPUE_N`)

- biomass per \\km^2\\ (`CPUE_W`)
