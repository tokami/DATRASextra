# Clean data following FishGlob workflow

This function follows the workflow that was used to create the FishGlob
data set (Maureaud et al. 2021). Adjusted from:
<https://github.com/fishglob/FishGlob_data/tree/main/cleaning_codes>.

A Maureaud, A., Frelat, R., Pécuchet, L., Shackell, N., Mérigot, B.,
Pinsky, M.L., Amador, K., Anderson, S.C., Arkhipkin, A., Auber, A. and
Barri, I., 2021. Are we ready to track climate-driven shifts in marine
species across international boundaries? A global survey of scientific
bottom trawl data. Global change biology, 27(2), pp.220-236.

## Usage

``` r
cleanFishglob(x)
```

## Arguments

- x:

  a DATRASraw object

## Value

Cleaned DATRASraw object according to FishGlob workflow.
