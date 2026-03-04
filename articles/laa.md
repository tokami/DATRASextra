# Extracting Length-at-Age (LAA) from DATRAS

## Goal

This vignette demonstrates how to extract and explore length-at-age
(LAA) data from a cleaned DATRAS object and how to estimate stochastic
age-length keys (ALKs).

## Setup

``` r
library(DATRASextra)
```

This vignette assumes you already have a cleaned DATRAS object (see the
tutorial vignette on data preparation). Here we use the example data:

``` r
data("dab")
```

A typical DATRAS object is a list with three core data sets:

``` r
str(dab, max.level = 1)
#> Class 'DATRASraw'  hidden list of 3
#>  $ CA:'data.frame':  8034 obs. of  39 variables:
#>  $ HH:'data.frame':  2651 obs. of  76 variables:
#>  $ HL:'data.frame':  26737 obs. of  36 variables:
```

- `CA`: individual-level biological data (e.g., length, weight, sex,
  maturity, age)
- `HH`: haul/station-level metadata (e.g., position, time, gear,
  environment)
- `HL`: catch-at-length and subsampling information

When a species appears in `CA`, a corresponding `HL` record should also
exist (even if values are missing codes such as `-9`).

------------------------------------------------------------------------

## Select years and clean data

For LAA analyses, `CA` is essential because it contains age readings.
However, `CA` is not catch-representative by itself, so ALKs are needed
to convert catch-at-length (`HL`) into catch-at-age.

We first select years of interest:

``` r
years <- 2020:2024
```

Then apply a quick standard cleaning/filtering step:

``` r
dab <- clean(dab, years = years)
```

Equivalent manual filtering (shown for reference):

``` r
dab <- subset(
  dab,
  Year %in% years &
    HaulVal == "V" &
    DayNight == "D" &
    StdSpecRecCode == 1
)
```

------------------------------------------------------------------------

## Investigate length-at-age data

``` r
ca <- dab[["CA"]]
str(ca, max.level = 1)
#> 'data.frame':    8034 obs. of  39 variables:
#>  $ RecordType       : Factor w/ 1 level "CA": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ Survey           : Factor w/ 1 level "NS-IBTS": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ Quarter          : Factor w/ 2 levels "1","3": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ Country          : Factor w/ 4 levels "DK","GB","GB-SCT",..: 4 4 4 4 4 4 4 4 4 4 ...
#>  $ Ship             : Factor w/ 5 levels "26D4","58G2",..: 2 2 2 2 2 2 2 2 2 2 ...
#>  $ Gear             : Factor w/ 1 level "GOV": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ SweepLngt        : int  110 110 110 110 110 110 110 110 110 110 ...
#>  $ GearEx           : Factor w/ 3 levels "B","S","D": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ DoorType         : Factor w/ 1 level "P": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ StNo             : chr  "60052" "60052" "60052" "60052" ...
#>  $ HaulNo           : int  52 52 52 52 52 52 52 52 52 52 ...
#>  $ Year             : Factor w/ 4 levels "2020","2021",..: 1 1 1 1 1 1 1 1 1 1 ...
#>  $ SpecCodeType     : chr  "W" "W" "W" "W" ...
#>  $ SpecCode         : int  127139 127139 127139 127139 127139 127139 127139 127139 127139 127139 ...
#>  $ AreaType         : int  0 0 0 0 0 0 0 0 0 0 ...
#>  $ AreaCode         : Factor w/ 104 levels "34F2","34F4",..: 71 71 71 71 71 71 71 71 71 71 ...
#>  $ LngtCode         : Factor w/ 3 levels ".","0","1": 3 3 3 3 3 3 3 3 3 3 ...
#>  $ LngtClas         : int  12 13 14 14 14 14 15 15 15 15 ...
#>  $ Sex              : Factor w/ 3 levels "","F","M": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ Maturity         : chr  NA NA NA NA ...
#>  $ PlusGr           : Factor w/ 1 level "": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ Age              : int  NA NA NA NA NA NA NA NA NA NA ...
#>  $ NoAtALK          : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ IndWgt           : num  NA NA NA NA NA NA NA NA NA NA ...
#>  $ FishID           : int  40 72 100 19 47 57 24 41 83 90 ...
#>  $ GenSamp          : Factor w/ 2 levels "","N": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ StomSamp         : Factor w/ 2 levels "","N": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ AgeSource        : Factor w/ 1 level "": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ AgePrepMet       : Factor w/ 1 level "": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ OtGrading        : int  NA NA NA NA NA NA NA NA NA NA ...
#>  $ ParSamp          : Factor w/ 2 levels "","N": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ MaturityScale    : Factor w/ 3 levels "","M6","SMSF": 2 2 2 2 2 2 2 2 2 2 ...
#>  $ Valid_Aphia      : num  127139 127139 127139 127139 127139 ...
#>  $ DateofCalculation: int  20220125 20220125 20220125 20220125 20220125 20220125 20220125 20220125 20220125 20220125 ...
#>  $ StatRec          : Factor w/ 104 levels "34F2","34F4",..: 71 71 71 71 71 71 71 71 71 71 ...
#>  $ LngtCm           : num  12 13 14 14 14 14 15 15 15 15 ...
#>  $ Species          : Factor w/ 1 level "Limanda limanda": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ haul.id          : Factor w/ 2651 levels "NS-IBTS:2020:1:DE:26D4:GOV:104:25",..: 298 298 298 298 298 298 298 298 298 298 ...
#>  $ Rank             : chr  "species" "species" "species" "species" ...
```

### Sample size by year

``` r
# Number of individual rows per Year
xtabs(~ Year, ca)
#> Year
#> 2020 2021 2022 2023 
#> 2911 2757 1595  771

# Number of unique hauls per Year
xtabs(~ Year, data = unique(ca[c("Year", "haul.id")]))
#> Year
#> 2020 2021 2022 2023 
#>  118  123  110   94
```

### Add spatial information from HH

Some variables (e.g., haul position) are in `HH` rather than `CA`. Merge
them by `haul.id`:

``` r
ca <- merge(
  ca,
  dab[["HH"]][c("haul.id", "lon", "lat")],
  by = "haul.id",
  all.x = TRUE,
  sort = FALSE,
  suffixes = c("", ".HH")
)
```

Now you can inspect spatial patterns in LAA observations:

``` r
plot(ca$lon, ca$lat, cex = pmax(0.6, ca$Age / 3), xlab = "Longitude", ylab = "Latitude")
```

![](laa_files/figure-html/unnamed-chunk-9-1.png)

### Age availability and missingness

``` r
table(ca$Age, useNA = "ifany")
#> 
#>    1    2    3    4    5    6    7    8 <NA> 
#>    4   72   99  138  104   47   15    5 7550
```

``` r
sum(is.na(ca$Age))
#> [1] 7550
```

Around 94% of `CA` entries have missing age.

For ALK estimation, `NoAtALK` is the frequency/count associated with
each age-length observation.

------------------------------------------------------------------------

## Estimate age-length keys (ALKs)

First, add the length spectrum from `HL`:

``` r
dab <- addSpectrum(dab)
```

ALKs are often estimated by quarter for stock-assessment workflows.
Example for Q1:

``` r
dab_Q1 <- subset(dab, Quarter == 1)
```

Fit a basic stochastic ALK:

``` r
ALK <- fitALK(
  dab_Q1,
  minAge = 3, ## TODO
  maxAge = 8
)
```

A more flexible model can include random year effects and spatial
smooths:

``` r
ALK_spatial <- fitALK(
  dab_Q1,
  minAge = 2,
  maxAge = 8,
  model = "cra ~ LngtCm + s(Year, bs = 're') + s(lon, lat, bs = 'ts')"
)
```

### Model interpretation

[`fitALK()`](https://rdrr.io/pkg/DATRAS/man/fitALK.html) uses a
continuation-ratio formulation. For each age threshold `a`, the data are
restricted to fish with `Age >= a`, and the binary response is
`Age > a`. This estimates:

\\ P(\text{Age} \> a \mid \text{Age} \ge a,\\ x) \\

Combining these conditional probabilities across ages yields the full
ALK.

------------------------------------------------------------------------

## Predict from the fitted ALK

Exact prediction workflows depend on your package version and chosen
downstream pipeline. A typical pattern is:

``` r
# Example pattern (adapt to your object structure)
newdata <- dab_Q1[["HL"]]
pred <- predict(ALK_spatial, newdata = newdata, type = "response")

# Continue with conversion from catch-at-length to catch-at-age per haul
# using the predicted age probabilities.
```

If your workflow uses a package-specific helper (e.g., an ALK
application function), use that helper in place of
[`predict()`](https://rdrr.io/r/stats/predict.html).

------------------------------------------------------------------------

## Summary

In this vignette, we:

1.  Loaded and cleaned DATRAS data
2.  Explored individual age data in `CA`
3.  Added haul-level spatial context from `HH`
4.  Estimated stochastic ALKs (basic and spatially enriched)
5.  Outlined how to predict/apply ALKs to convert catch-at-length to
    catch-at-age
