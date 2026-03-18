# Get length measurement accuracy in cm

Derives the length measurement resolution, in centimetres, from the
`LngtCode` column of the `HL` table in a `DATRASraw` object.

## Usage

``` r
get_accuracy_cm(x)
```

## Arguments

- x:

  A `DATRASraw` object containing an `HL` table with a `LngtCode`
  column.

## Value

A numeric scalar giving the inferred length measurement accuracy in cm.

## Details

The returned value is the coarsest available resolution found in the
data. If multiple length accuracies are present, the largest value is
returned and a warning is issued. If unknown or missing `LngtCode`
values are present, they are ignored when possible and a warning is
issued.

The mapping from `LngtCode` to centimetres is:

- `"."` = 0.1 cm

- `"0"` = 0.5 cm

- `"1"` = 1 cm

- `"2"` = 2 cm

- `"5"` = 5 cm

The function returns the maximum recognised length resolution present in
`x[["HL"]]$LngtCode`, corresponding to the coarsest measurement accuracy
in the data.

## Examples

``` r
if (FALSE) { # \dontrun{
acc <- get_accuracy_cm(x)
} # }
```
