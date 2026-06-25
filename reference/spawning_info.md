# Spawning information lookup table

A lookup table giving the spawning months of fish species by ICES area,
compiled from the GoFish and WKMAT sources.

## Usage

``` r
spawning_info
```

## Format

A data frame with the columns:

- species:

  Scientific name of the species.

- aphia:

  WoRMS AphiaID of the species.

- ices_area:

  ICES area the record applies to (e.g. 3.d.27).

- spawn_months:

  List column of integer months (1-12) in which the species spawns in
  that area.

- source:

  Source(s) the spawning information was compiled from (e.g. gofish,
  wkmat).

- match_type:

  How the area was matched to the source (e.g. exact_area, parent_area,
  neighbour_region).

- source_area:

  ICES area of the original source record used for the match.

## Source

<https://github.com/federico-maioli/length_at_maturity>
