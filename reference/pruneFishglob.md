# Prune data according to FishGlob workflow

Prune data according to FishGlob workflow

## Usage

``` r
pruneFishglob(x)
```

## Arguments

- x:

  a DATRASraw object.

## Value

Pruned DATRASraw object according to FishGlb workflow.

## Details

DATRAS' CA data set, and some columns in the 'HH' and 'HL' data sets are
not needed to reproduce the FishGlob data set. Thus, these data sets and
columns can be removed to save some memory.
