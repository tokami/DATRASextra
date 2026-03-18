# Clean a `datras_raw` object following the FishGlob workflow

Apply the main cleaning steps used in the FishGlob data workflow to a
`datras_raw` / `DATRASraw` object.

## Usage

``` r
clean_fishglob(x)
```

## Arguments

- x:

  A `datras_raw` object.

## Value

A cleaned `datras_raw` object following the FishGlob workflow.

## Details

This function follows the ICES DATRAS cleaning workflow used to
construct the FishGlob data set, including filtering of valid hauls and
species records, selected survey renaming, removal of hauls affected by
incomplete bycatch recording, and species harmonization.

The cleaning steps are adapted from the FishGlob data-processing
workflow described in Maureaud et al. (2021) and the associated code
repository.

The function currently performs the following operations:

- retains only valid hauls (`HaulVal == "V"`),

- removes records with missing `Valid_Aphia`,

- keeps only selected `SpecVal` codes,

- keeps only selected `DataType` codes,

- renames selected surveys to match FishGlob conventions,

- removes hauls affected by incomplete bycatch recording for selected
  surveys,

- harmonizes species names and taxonomic identifiers using
  [`correct_species()`](https://tokami.github.io/DATRASextra/reference/correct_species.md).

Survey renaming currently includes:

- `"SCOWCGFS"` to `"SWC-IBTS"`

- `"SCOROC"` to `"ROCKALL"`

The treatment of bycatch-recording codes follows the FishGlob workflow
for the `NS-IBTS` and `BITS` surveys.

## References

Maureaud, A., Frelat, R., Pécuchet, L., Shackell, N., Mérigot, B.,
Pinsky, M. L., Amador, K., Anderson, S. C., Arkhipkin, A., Auber, A.,
Barri, I., et al. (2021). Are we ready to track climate-driven shifts in
marine species across international boundaries? A global survey of
scientific bottom trawl data. *Global Change Biology*, 27(2), 220–236.

FishGlob workflow code:
<https://github.com/fishglob/FishGlob_data/tree/main/cleaning_codes>

## See also

[`clean_datras()`](https://tokami.github.io/DATRASextra/reference/clean_datras.md),
[`correct_species()`](https://tokami.github.io/DATRASextra/reference/correct_species.md)

## Examples

``` r
if (FALSE) { # \dontrun{
x_clean <- clean_fishglob(x)
} # }
```
