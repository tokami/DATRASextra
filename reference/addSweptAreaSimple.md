# Add Swept Area based on wing spread / beam width using a simple approach.

Add Swept Area based on wing spread / beam width using a simple
approach.

## Usage

``` r
addSweptAreaSimple(
  d,
  minSpeed = 1,
  minDist = 0,
  maxDistDev = 0.2,
  impute.missing = FALSE
)
```

## Arguments

- d:

  a DATRASraw object.

- minSpeed:

  x

- minDist:

  x

- maxDistDev:

  x

- impute.missing:

  FALSE

## Value

DATRASraw object with two SweptArea indices: SweptArea and
SweptArea.median. The latter assumes a fixed trawl width for each gear
category (the median).

## Details

In m^2.
