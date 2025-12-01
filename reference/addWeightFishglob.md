# calculate weight by length classes and add to hh records

calculate weight by length classes using empirical a and b, and add to
hh records according to fishglob workflow

## Usage

``` r
addWeightFishglob(x)
```

## Arguments

- x:

  a DATRASraw object

## Value

a DATRASraw object with hl table updated with weight fields

## Details

- weight-at-length is calculated per individual using empirical a and b
  parameters

- total weight per length class is computed as number at length \*
  individual weight

- optionally, weight can be divided by haul duration in minutes

- final weight is returned in kg
