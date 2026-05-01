# Plotting DATRAS overviews

## Overview

This vignette demonstrates the unified plotting function
[`plot_datras_overview()`](https://tokami.github.io/DATRASextra/reference/plot_datras_overview.md).
The function allows to generate a quick overview of all haul locations
in DATRAS or number of hauls per ICES Statistical Rectangle, but also
allows to generate more complicated maps of any variables (and offset
variable) by haul location in a point plot or gridded plot of a specific
data set. Specifically, the function supports:

- point maps (`mode = "points"`)
- gridded maps (`mode = "grid"`)
- multiple grid metrics (`presence`, `count_hauls`, `count_surveys`,
  `sum`, `mean`)
- grouping and faceting (`by_survey`, `by_gear`, `by_quarter`,
  `multi_panels`)
- raw or StatRec spatial basis (`spatial_basis = "raw"` or `"statrec"`)
- value/offset/transform workflows for quantitative overlays

Load the package with:

``` r

library(DATRASextra)
```

## Quick Start

If no object is supplied (`x = NULL`), the function uses package survey
overview data, which contains all surveys and hauls in DATRAS:

``` r

plot_datras_overview()
```

![](plot-datras-overview_files/figure-html/quick-null-1.png)

To get an overview over the surveys:

``` r

plot_datras_overview(by_survey = TRUE)
```

![](plot-datras-overview_files/figure-html/quick-null-by-survey-1.png)

If the legend is in the way, the multiple different control arguments
can be used to place and modify the legend:

``` r

plot_datras_overview(by_survey = TRUE,
                     legend_ncol = 6,
                     legend_pos = "bottom",
                     legend_cex = 0.8)
```

![](plot-datras-overview_files/figure-html/quick-null-by-survey-legend-1.png)

With so many surveys and repeating colours, it might be easier to plot
the surveys in separate panels:

``` r

plot_datras_overview(by_survey = TRUE,
                     multi_panels = TRUE)
```

![](plot-datras-overview_files/figure-html/quick-null-by-survey-multi-pannel-1.png)

Besides the general overview over all surveys, the function also allows
to create a visual overview of a specific data set, using for example
the `mini` data set of `DATRASextra`:

``` r

plot_datras_overview(mini)
```

![](plot-datras-overview_files/figure-html/quick-mini-points-1.png)

## Aggregate by

Besides surveys, the function allows to quickly create a comparison
between gears:

``` r

plot_datras_overview(mini, by_gear = TRUE)
```

![](plot-datras-overview_files/figure-html/agg-gear-1.png)

by quarter:

``` r

plot_datras_overview(mini, by_quarter = TRUE)
```

![](plot-datras-overview_files/figure-html/agg-quarter-1.png)

by year:

``` r

plot_datras_overview(mini, by_year = TRUE)
```

![](plot-datras-overview_files/figure-html/agg-year-1.png)

or day and night:

``` r

plot_datras_overview(mini, by_daynight = TRUE)
```

![](plot-datras-overview_files/figure-html/agg-dn-1.png)

or any combination of them:

``` r

plot_datras_overview(mini,
                     by_gear = TRUE,
                     by_survey = TRUE)
```

![](plot-datras-overview_files/figure-html/agg-gear-survey-1.png)

setting the `multi_panel` argument to `TRUE` avoids the overlap and
might help interpretation:

``` r

plot_datras_overview(mini, by_gear = TRUE,
                     by_survey = TRUE,
                     multi_panel = TRUE)
```

![](plot-datras-overview_files/figure-html/agg-gear-survey-multi-1.png)

## Points vs. gridded

By default, the function plots the actual haul locations, but it might
be preferrable to aggregate the hauls and plot them by ICES statistical
rectangle midpoints by setting the argument `spatial_basis = "statrec"`:

``` r

plot_datras_overview(mini,
                     by_gear = TRUE,
                     spatial_basis = "statrec")
```

![](plot-datras-overview_files/figure-html/spat_basis-1.png)

As multiple levels (here gears) might be present in a single ICES
statistical rectangle, by default, the dominant level is assigned to
that rectangle, but the argument `grid_group_strategy` allows to change
that behaviour.

Instead of plots by statistical rectangle, the function also allows to
plot an gridded image plot. This can be done by setting the
`mode = "grid"`:

``` r

plot_datras_overview(mini, by_gear = TRUE, mode = "grid")
```

![](plot-datras-overview_files/figure-html/mode-grid-1.png)

Again, by default the dominant level is shown for each grid cell.

## Plotted quantity

While so far, the plots only quantified the absence / presence of a haul
with a specific charactistics in each area, the function also allows us
to plot various quantities by using the `metric` argument. We can for
example plot the number of hauls with:

``` r

plot_datras_overview(mini,
                     mode = "grid",
                     metric = "count_hauls")
```

![](plot-datras-overview_files/figure-html/metric-count-hauls-1.png)

Note that this only works for the gridded mode and if requires the
`multi_panels = TRUE` if you want to split it by another variable:

``` r

plot_datras_overview(mini,
                     mode = "grid",
                     metric = "count_hauls",
                     by_year = TRUE,
                     multi_panels = TRUE)
```

![](plot-datras-overview_files/figure-html/metric-count-hauls-year-1.png)

Similarly, you can plot the number of surveys by quarter:

``` r

plot_datras_overview(mini,
                     mode = "grid",
                     metric = "count_surveys",
                     by_quarter = TRUE,
                     multi_panels = TRUE)
```

![](plot-datras-overview_files/figure-html/metric-count-surveys-quarter-1.png)

Other options of the `metric` argument are `"sum"` or `"mean"`, but they
become more meaningful when combined with the `value_var` argument (see
below).

## Value / Offset / Transform Workflows

If your DATRAS data set includes quantitative columns (for example a
response and an effort-like offset), you can map transformed values in
both grid and point modes. For example, a quick map of mean `Depth` can
be created by:

``` r

plot_datras_overview(mini,
                     metric = "mean",
                     value_var = "Depth")
```

![](plot-datras-overview_files/figure-html/value-depth-1.png)

or as gridded version with squareroot transformation:

``` r

plot_datras_overview(mini,
                     mode = "grid",
                     metric = "mean",
                     value_var = "Depth",
                     transform = "sqrt")
```

![](plot-datras-overview_files/figure-html/value-depth-grid-1.png)

If your data set contains the number of individuals for example by using
the `DATRASextra` workflow:

``` r

dab <- add_total_numbers_by_haul(dab)
```

Then the plotting function can be used to generate an overview of the
hauls with the largest number of individuals:

``` r

plot_datras_overview(dab,
                     metric = "mean",
                     value_var = "HaulN")
```

![](plot-datras-overview_files/figure-html/value-dab-1.png)

or as a gridded version:

``` r

plot_datras_overview(dab,
                     mode = "grid",
                     metric = "mean",
                     value_var = "HaulN")
```

![](plot-datras-overview_files/figure-html/value-dab-grid-1.png)

If in addition, a meaningful offset variable is available, such as haul
duration or swept area for example by:

``` r

dab <- add_swept_area(dab)
```

Then this information can also be incorporated and the hauls with the
largest numbers of individuals per offset can be plotted:

``` r

plot_datras_overview(dab,
                     metric = "mean",
                     value_var = "HaulN",
                     offset_var = "HaulDur")
```

![](plot-datras-overview_files/figure-html/value-dab-hauldur-1.png)

or as a gridded version with swept area:

``` r

plot_datras_overview(dab,
                     mode = "grid",
                     metric = "mean",
                     value_var = "HaulN",
                     offset_var = "SweptArea")
```

![](plot-datras-overview_files/figure-html/value-dab-sweptarea-1.png)

## Troubleshooting

- If `spatial_basis = "statrec"` fails, check that `StatRec` exists and
  has valid values.
- If no rows appear, verify `xlim`/`ylim` filters and coordinate
  columns.
- If legends are suppressed in multi-panel mode, set
  `legend_mode = "global"`.
