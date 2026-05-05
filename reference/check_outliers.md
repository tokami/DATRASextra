# Check outliers in a datras_raw object

Rule-based quality control for key variables in a datras_raw object.
Optionally adds percentile-based extreme-value flagging (group-wise).

## Usage

``` r
check_outliers(
  x,
  vars = NULL,
  strict = TRUE,
  pct = FALSE,
  pct_probs = c(0.01, 0.99),
  pct_by = list(HH = c("Survey", "Quarter", "Gear", "Ship"), HL = c("Survey", "Quarter",
    "Gear", "Valid_Aphia"), CA = c("Survey", "Quarter", "Gear", "Valid_Aphia")),
  pct_vars = list(HH = c("HaulDur", "Depth", "DoorSpread", "WingSpread"), HL =
    c("LngtCm"), CA = c("Age", "IndWgt", "LngtClas")),
  pct_min_n = 50,
  pct_log_vars = list(HH = character(0), HL = character(0), CA = c("IndWgt")),
  remove_extremes = FALSE,
  action = c("report", "remove"),
  verbose = TRUE
)
```

## Arguments

- x:

  A datras_raw object, i.e. a list with components HH, HL, and CA.

- vars:

  Optional character vector of variable names to check. If NULL, all
  default rules are used. If provided, percentile checks are also
  limited to these variables.

- strict:

  Logical; if TRUE, use stricter upper bounds for rule-based checks.

- pct:

  Logical; if TRUE, also flag extreme values using percentiles.

- pct_probs:

  Numeric length-2 vector of lower/upper probabilities, e.g. c(0.01,
  0.99).

- pct_by:

  Named list with elements HH/HL/CA giving grouping variables for
  percentile calculations. Only columns present in the data are used;
  missing columns are silently dropped rather than collapsing all
  groups.

- pct_vars:

  Named list with elements HH/HL/CA giving variables to check via
  percentiles.

- pct_min_n:

  Minimum number of non-missing observations required per group to
  compute percentiles.

- pct_log_vars:

  Named list with elements HH/HL/CA giving variables for which
  percentiles are computed on log-scale.

- remove_extremes:

  Logical; if TRUE and action = "remove", also remove hauls flagged by
  percentile checks. Default FALSE (safer).

- action:

  Character; either "report" or "remove".

- verbose:

  Logical; print a summary?

## Value

A datras_raw object. The object is returned unchanged when
`action = "report"`, and with flagged hauls removed when
`action = "remove"`.

Attributes added:

- `attr(res, "outlier_report")` data.frame with all flagged rows

- `attr(res, "outlier_hauls")` union of all flagged haul IDs

- `attr(res, "outlier_hauls_invalid")` haul IDs flagged by rule-based
  checks

- `attr(res, "outlier_hauls_extreme")` haul IDs flagged by percentile
  checks
