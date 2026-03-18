# Standardize and correct species information in a `datras_raw` object

Correct selected species names, Aphia IDs, and taxonomic ranks in the
`CA` and `HL` tables of a `datras_raw` / `DATRASraw` object.

## Usage

``` r
correct_species(x)
```

## Arguments

- x:

  A `datras_raw` object.

## Value

A `datras_raw` object with corrected `Species`, `Valid_Aphia`, and
`Rank` fields in the `CA` and `HL` tables where applicable.

## Details

The function is intended to harmonize species information for cases
where records are better treated at genus level, where synonymous or
outdated species names occur, or where taxonomic information is
incomplete.

The function operates on the `CA` and `HL` components, if present and
non-empty.

If the column `Rank` is missing, it is added and initialized as
`"species"`. Selected taxa are then reassigned to genus level by
updating `Species`, `Valid_Aphia`, and `Rank`. In addition, a small
number of species name corrections are applied.

Examples of corrections include:

- collapsing selected taxa to genus level, for example `"Dipturus"` or
  `"Gobius"`,

- harmonizing alternative or inconsistent taxonomic names,

- updating corresponding `Valid_Aphia` identifiers,

- setting `Rank` to either `"species"` or `"genus"` as appropriate.

The function currently modifies only the `CA` and `HL` tables and leaves
`HH` unchanged.

## See also

[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md)

## Examples

``` r
if (FALSE) { # \dontrun{
## Correct species information after reading DATRAS data
x <- correct_species(x)
} # }
```
