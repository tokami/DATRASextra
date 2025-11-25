# Add Swept Area index following the FishGlob calculations

Add Swept Area index following the FishGlob calculations

## Usage

``` r
addSweptAreaFishGlob(x)
```

## Arguments

- x:

  a DATRASraw object

## Value

DATRASraw object with SweptArea index, columns "SweptArea" and
"DoorArea".

## Details

The unit of the swept area indices are squaremeters (m^2).

The original functions were developed by Aurore Maureaud and Daniël van
Denderen and can be accessed here:
<https://github.com/fishglob/FishGlob_data/blob/main/cleaning_codes/source_DATRAS_wing_doorspread.R>.

Note, that this function only calculates the swept area for surveys that
are included in the FISHGLOB (EVHOE, SWC-IBTS, BITS, IE-IGFS, FR-CGFS,
NIGFS, ROCKALL, SP-NORTH, SP-ARSA, SP-PORC; status November 2025).
