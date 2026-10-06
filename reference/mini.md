# Mini DATRAS survey data (example dataset)

Example ICES DATRAS data for 6 years (2015-2020), 4 surveys (NS-IBTS,
BITS, BTS, and EVHOE), all quarters, and 5 species: Lophius piscatorius
(European anglerfish), Lepidorhombus whiffiagonis (Megrim),
Hippoglossoides platessoides (American plaice), Trisopterus esmarkii
(Norway pout), and Amblyraja radiata (Starry ray).

## Usage

``` r
mini
```

## Format

A list of class 'datras_raw' with 3 elements:

- CA:

  Biological data

- HH:

  Survey level information

- HL:

  Length measurements

## Source

ICES DATRAS database <https://datras.ices.dk>

## Details

The years overlap with the public FishGlob data, so the data set is also
used to compare
[`clean_fishglob()`](https://tokami.github.io/DATRASextra/reference/clean_fishglob.md)
with FishGlob.
