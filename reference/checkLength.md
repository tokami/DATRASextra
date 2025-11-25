# Create and inspect length spectrum

Create and inspect length measurements (in HL)

## Usage

``` r
checkLength(
  x,
  cm.breaks = seq(min(x[[3]]$LngtCm, na.rm = TRUE), max(x[[3]]$LngtCm, na.rm = TRUE) +
    by, by = by),
  by = NULL,
  length.percentile = 99.9999,
  plot = TRUE
)
```

## Arguments

- x:

  DATRASraw object

- cm.breaks:

  x

- by:

  If NULL, most coarse accuracy is used (using DATRAS internal function
  getAccuracyCM)

- length.percentile:

  x

- plot:

  TRUE

## Value

N at length matrix
