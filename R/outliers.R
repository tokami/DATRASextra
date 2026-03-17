##' @title Check outliers in a DATRASraw object
##'
##' @description
##' Rule-based quality control for key variables in a DATRASraw object.
##' Optionally adds percentile-based extreme-value flagging (group-wise).
##'
##' @param x A DATRASraw object, i.e. a list with components HH, HL, and CA.
##' @param vars Optional character vector of variable names to check. If NULL,
##'   all default rules are used. If provided, percentile checks are also limited
##'   to these variables.
##' @param strict Logical; if TRUE, use stricter upper bounds for rule-based checks.
##' @param pct Logical; if TRUE, also flag extreme values using percentiles.
##' @param pct_probs Numeric length-2 vector of lower/upper probabilities, e.g.
##'   c(0.01, 0.99).
##' @param pct_by Named list with elements HH/HL/CA giving grouping variables for
##'   percentile calculations.
##' @param pct_vars Named list with elements HH/HL/CA giving variables to check via percentiles.
##' @param pct_min_n Minimum number of non-missing observations required per group to compute percentiles.
##' @param pct_log_vars Named list with elements HH/HL/CA giving variables for which percentiles are computed on log-scale.
##' @param remove_extremes Logical; if TRUE and action = "remove", also remove hauls
##'   flagged by percentile checks. Default FALSE (safer).
##' @param action Character; either "report" or "remove".
##' @param verbose Logical; print a summary?
##'
##' @return
##' A DATRASraw object. The object is returned unchanged when
##' \code{action = "report"}, and with flagged hauls removed when
##' \code{action = "remove"}.
##'
##' Attributes added:
##' \itemize{
##'   \item \code{attr(res, "outlier_report")} data.frame with all flagged rows
##'   \item \code{attr(res, "outlier_hauls")} union of all flagged haul IDs
##'   \item \code{attr(res, "outlier_hauls_invalid")} haul IDs flagged by rule-based checks
##'   \item \code{attr(res, "outlier_hauls_extreme")} haul IDs flagged by percentile checks
##' }
##'
##' @export
checkOutliers <- function(x,
                          vars = NULL,
                          strict = TRUE,
                          pct = FALSE,
                          pct_probs = c(0.01, 0.99),
                          pct_by = list(
                            HH = c("Survey", "Quarter", "Gear", "Ship"),
                            HL = c("Survey", "Quarter", "Gear", "SpecCode"),
                            CA = c("Survey", "Quarter", "Gear", "SpecCode")
                          ),
                          pct_vars = list(
                            HH = c("HaulDur", "Depth", "DoorSpread", "WingSpread"),
                            HL = c("LngtCm"),
                            CA = c("Age", "IndWgt", "LngtClas")
                          ),
                          pct_min_n = 50,
                          pct_log_vars = list(
                            HH = character(0),
                            HL = character(0),
                            CA = c("IndWgt")
                          ),
                          remove_extremes = FALSE,
                          action = c("report", "remove"),
                          verbose = TRUE) {

  action <- match.arg(action)

  ## basic checks
  if (!is.list(x)) {
    stop("'x' must be a list-like DATRASraw object.")
  }
  if (!all(c("HH", "HL", "CA") %in% names(x))) {
    stop("'x' must contain components 'HH', 'HL', and 'CA'.")
  }
  if (is.null(x[["HH"]]) || !is.data.frame(x[["HH"]]) || nrow(x[["HH"]]) == 0) {
    stop("'x[['HH']]' must be a non-empty data.frame.")
  }

  ## validate pct_probs
  if (!is.numeric(pct_probs) || length(pct_probs) != 2L || any(is.na(pct_probs))) {
    stop("'pct_probs' must be a numeric vector of length 2, e.g. c(0.01, 0.99).")
  }
  pct_probs <- sort(pct_probs)
  if (pct_probs[1] <= 0 || pct_probs[2] >= 1 || pct_probs[1] >= pct_probs[2]) {
    stop("'pct_probs' must satisfy 0 < p1 < p2 < 1.")
  }

  rules <- .datras_default_outlier_rules(strict = strict)

  ## optional variable subset (applies to rule checks + percentile checks)
  if (!is.null(vars)) {
    rules <- lapply(
      rules,
      function(z) {
        Filter(function(r) any(r$vars %in% vars), z)
      }
    )

    pct_vars <- lapply(pct_vars, function(v) v[v %in% vars])
    pct_log_vars <- lapply(pct_log_vars, function(v) v[v %in% vars])
  }

  ## rule-based checks
  rep_hh <- .apply_outlier_rules(x[["HH"]], table_name = "HH", rules = rules$HH)
  rep_hl <- .apply_outlier_rules(x[["HL"]], table_name = "HL", rules = rules$HL)
  rep_ca <- .apply_outlier_rules(x[["CA"]], table_name = "CA", rules = rules$CA)

  report_rules <- rbind(rep_hh, rep_hl, rep_ca)

  ## percentile checks (optional)
  report_pct <- .empty_outlier_report()
  if (isTRUE(pct)) {
    rep2_hh <- .apply_percentile_checks(
      d = x[["HH"]],
      table_name = "HH",
      vars = pct_vars$HH,
      by = pct_by$HH,
      probs = pct_probs,
      min_n = pct_min_n,
      log_vars = pct_log_vars$HH
    )
    rep2_hl <- .apply_percentile_checks(
      d = x[["HL"]],
      table_name = "HL",
      vars = pct_vars$HL,
      by = pct_by$HL,
      probs = pct_probs,
      min_n = pct_min_n,
      log_vars = pct_log_vars$HL
    )
    rep2_ca <- .apply_percentile_checks(
      d = x[["CA"]],
      table_name = "CA",
      vars = pct_vars$CA,
      by = pct_by$CA,
      probs = pct_probs,
      min_n = pct_min_n,
      log_vars = pct_log_vars$CA
    )
    report_pct <- rbind(rep2_hh, rep2_hl, rep2_ca)
  }

  report <- rbind(report_rules, report_pct)

  ## haul sets
  bad_hauls_invalid <- if (nrow(report_rules) == 0) {
    character(0)
  } else {
    unique(report_rules$haul.id[!is.na(report_rules$haul.id) & nzchar(report_rules$haul.id)])
  }

  bad_hauls_extreme <- if (nrow(report_pct) == 0) {
    character(0)
  } else {
    unique(report_pct$haul.id[!is.na(report_pct$haul.id) & nzchar(report_pct$haul.id)])
  }

  bad_hauls_all <- unique(c(bad_hauls_invalid, bad_hauls_extreme))

  ## decide what to remove
  bad_hauls_remove <- bad_hauls_invalid
  if (action == "remove" && isTRUE(remove_extremes)) {
    bad_hauls_remove <- bad_hauls_all
  }

  res <- x

  if (action == "remove" && length(bad_hauls_remove) > 0) {
    res <- lapply(res, function(d) {
      if (!is.data.frame(d) || nrow(d) == 0) {
        return(d)
      }
      if (!"haul.id" %in% names(d)) {
        return(d)
      }
      d[!(as.character(d$haul.id) %in% bad_hauls_remove), , drop = FALSE]
    })
    class(res) <- class(x)
  }

  attr(res, "outlier_report") <- report
  attr(res, "outlier_hauls") <- bad_hauls_all
  attr(res, "outlier_hauls_invalid") <- bad_hauls_invalid
  attr(res, "outlier_hauls_extreme") <- bad_hauls_extreme

  if (verbose) {
    if (nrow(report) == 0) {
      message("No outliers detected.")
    } else {
      message(
        "Detected ", nrow(report), " flagged row(s) in ",
        length(bad_hauls_all), " haul(s). ",
        if (pct) "(includes percentile checks)" else ""
      )

      tmp <- transform(report, one = 1L)
      tmp$severity <- ifelse(is.na(tmp$severity), "unknown", tmp$severity)
      print(stats::aggregate(one ~ table + var + severity, data = tmp, FUN = sum))
    }

    if (action == "remove") {
      message(
        "Removed hauls: ", length(bad_hauls_remove),
        if (pct && !remove_extremes) " (invalid only; extremes kept)." else "."
      )
    }
  }

  return(res)
}


.datras_rule <- function(vars, reason, flag_fun, value_vars = vars) {
  list(
    vars = vars,
    reason = reason,
    flag_fun = flag_fun,
    value_vars = value_vars
  )
}


.datras_default_outlier_rules <- function(strict = TRUE) {

  ## TODO: review these values
  ## broad but useful defaults
  max_hauldur   <- if (strict) 240 else 600
  max_depth     <- if (strict) 2000 else 4000
  max_doorspread <- if (strict) 250 else 400
  max_wingspread <- if (strict) 80 else 150
  max_lngtcm    <- if (strict) 200 else 400
  max_age       <- if (strict) 80 else 120
  max_lngtclas  <- if (strict) 2000 else 4000
  max_indwgt    <- if (strict) 1e5 else 5e5

  list(

    HH = list(

      .datras_rule(
        vars = "TimeShot",
        reason = "invalid HHMM time",
        flag_fun = function(d) {
          if (!"TimeShot" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.integer(as.character(d$TimeShot)))
          !is.na(v) & (v < 0L | v > 2359L | (v %% 100L) > 59L)
        }
      ),

      .datras_rule(
        vars = "HaulDur",
        reason = paste0("HaulDur outside 0-", max_hauldur, " min"),
        flag_fun = function(d) {
          if (!"HaulDur" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$HaulDur))
          !is.na(v) & (v <= 0 | v > max_hauldur)
        }
      ),

      .datras_rule(
        vars = "ShootLat",
        reason = "ShootLat outside [-90, 90]",
        flag_fun = function(d) {
          if (!"ShootLat" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$ShootLat))
          !is.na(v) & (v < -90 | v > 90)
        }
      ),

      .datras_rule(
        vars = "ShootLong",
        reason = "ShootLong outside [-180, 180]",
        flag_fun = function(d) {
          if (!"ShootLong" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$ShootLong))
          !is.na(v) & (v < -180 | v > 180)
        }
      ),

      .datras_rule(
        vars = "Depth",
        reason = paste0("Depth outside 0-", max_depth, " m"),
        flag_fun = function(d) {
          if (!"Depth" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$Depth))
          !is.na(v) & (v <= 0 | v > max_depth)
        }
      ),

      .datras_rule(
        vars = "DoorSpread",
        reason = paste0("DoorSpread outside 0-", max_doorspread, " m"),
        flag_fun = function(d) {
          if (!"DoorSpread" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$DoorSpread))
          !is.na(v) & (v <= 0 | v > max_doorspread)
        }
      ),

      .datras_rule(
        vars = "WingSpread",
        reason = paste0("WingSpread outside 0-", max_wingspread, " m"),
        flag_fun = function(d) {
          if (!"WingSpread" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$WingSpread))
          !is.na(v) & (v <= 0 | v > max_wingspread)
        }
      ),

      .datras_rule(
        vars = c("WingSpread", "DoorSpread"),
        reason = "WingSpread >= DoorSpread",
        flag_fun = function(d) {
          if (!all(c("WingSpread", "DoorSpread") %in% names(d))) {
            return(rep(FALSE, nrow(d)))
          }
          ws <- suppressWarnings(as.numeric(d$WingSpread))
          ds <- suppressWarnings(as.numeric(d$DoorSpread))
          !is.na(ws) & !is.na(ds) & (ws >= ds)
        },
        value_vars = c("WingSpread", "DoorSpread")
      )
    ),

    HL = list(

      .datras_rule(
        vars = "LngtCm",
        reason = paste0("LngtCm outside 0-", max_lngtcm, " cm"),
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"LngtCm" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$LngtCm))
          !is.na(v) & (v <= 0 | v > max_lngtcm)
        }
      )
    ),

    CA = list(

      .datras_rule(
        vars = "Sex",
        reason = "Sex not in allowed set ('', 'F', 'M', 'U')",
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"Sex" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- trimws(as.character(d$Sex))
          !(is.na(v) | v %in% c("", "F", "M", "U"))
        }
      ),

      .datras_rule(
        vars = "Age",
        reason = paste0("Age outside 0-", max_age),
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"Age" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$Age))
          !is.na(v) & (v < 0 | v > max_age | abs(v - round(v)) > 1e-8)
        }
      ),

      .datras_rule(
        vars = "NoAtALK",
        reason = "NoAtALK must be a non-negative integer",
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"NoAtALK" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$NoAtALK))
          !is.na(v) & (v < 0 | abs(v - round(v)) > 1e-8)
        }
      ),

      .datras_rule(
        vars = "IndWgt",
        reason = paste0("IndWgt outside 0-", max_indwgt),
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"IndWgt" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$IndWgt))
          !is.na(v) & (v <= 0 | v > max_indwgt)
        }
      ),

      .datras_rule(
        vars = "LngtCode",
        reason = "LngtCode not in allowed set ('', '.', '0', '1')",
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"LngtCode" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- trimws(as.character(d$LngtCode))
          !(is.na(v) | v %in% c("", ".", "0", "1"))
        }
      ),

      .datras_rule(
        vars = "LngtClas",
        reason = paste0("LngtClas outside 0-", max_lngtclas),
        flag_fun = function(d) {
          if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
            return(logical(0))
          }
          if (!"LngtClas" %in% names(d)) return(rep(FALSE, nrow(d)))
          v <- suppressWarnings(as.numeric(d$LngtClas))
          !is.na(v) & (v <= 0 | v > max_lngtclas | abs(v - round(v)) > 1e-8)
        }
      )
    )
  )
}


.apply_outlier_rules <- function(d, table_name, rules) {

  if (is.null(d) || !is.data.frame(d) || nrow(d) == 0 || length(rules) == 0) {
    return(.empty_outlier_report())
  }

  out <- vector("list", length(rules))
  k <- 0L

  for (rule in rules) {

    idx <- rule$flag_fun(d)

    if (length(idx) == 0) {
      next
    }

    idx[is.na(idx)] <- FALSE

    if (!any(idx)) {
      next
    }

    k <- k + 1L
    rows <- which(idx)

    values <- .collapse_rule_values(d[idx, , drop = FALSE], rule$value_vars)

    haul_id <- if ("haul.id" %in% names(d)) {
      as.character(d$haul.id[idx])
    } else {
      rep(NA_character_, length(rows))
    }

    out[[k]] <- data.frame(
      table = table_name,
      var = paste(rule$vars, collapse = ","),
      row = rows,
      haul.id = haul_id,
      value = values,
      reason = rule$reason,
      method = "rule",
      severity = "invalid",
      p_lo = NA_real_,
      p_hi = NA_real_,
      thr_lo = NA_real_,
      thr_hi = NA_real_,
      group = NA_character_,
      stringsAsFactors = FALSE
    )
  }

  if (k == 0L) {
    return(.empty_outlier_report())
  }

  do.call(rbind, out[seq_len(k)])
}


.apply_percentile_checks <- function(d,
                                    table_name,
                                    vars,
                                    by,
                                    probs = c(0.01, 0.99),
                                    min_n = 50,
                                    log_vars = character(0)) {

  if (is.null(d) || !is.data.frame(d) || nrow(d) == 0) {
    return(.empty_outlier_report())
  }
  if (length(vars) == 0) {
    return(.empty_outlier_report())
  }

  ## group key
  use_by <- by
  if (length(use_by) > 0 && !all(use_by %in% names(d))) {
    use_by <- character(0)
  }

  key <- if (length(use_by) > 0) {
    do.call(paste, c(d[use_by], sep = "\r"))
  } else {
    rep("ALL", nrow(d))
  }

  out <- list()
  k <- 0L

  for (vname in vars) {

    if (!vname %in% names(d)) {
      next
    }

    v <- suppressWarnings(as.numeric(d[[vname]]))
    ok <- !is.na(v)

    if (!any(ok)) {
      next
    }

    use_log <- vname %in% log_vars
    vv <- v
    if (use_log) {
      ok <- ok & (vv > 0)
      vv <- log(vv)
    }

    lev <- unique(key)
    lo <- hi <- rep(NA_real_, length(lev))
    names(lo) <- names(hi) <- lev

    for (g in lev) {
      sel <- which(key == g & ok)
      if (length(sel) >= min_n) {
        qs <- stats::quantile(vv[sel], probs = probs, na.rm = TRUE, names = FALSE, type = 7)
        lo[g] <- qs[1]
        hi[g] <- qs[2]
      }
    }

    thr_lo_row <- lo[key]
    thr_hi_row <- hi[key]

    idx <- ok & !is.na(thr_lo_row) & !is.na(thr_hi_row) & (vv < thr_lo_row | vv > thr_hi_row)

    if (!any(idx)) {
      next
    }

    rows <- which(idx)

    haul_id <- if ("haul.id" %in% names(d)) {
      as.character(d$haul.id[idx])
    } else {
      rep(NA_character_, length(rows))
    }

    ## value shown on original scale
    values <- as.character(v[idx])

    k <- k + 1L
    out[[k]] <- data.frame(
      table = table_name,
      var = vname,
      row = rows,
      haul.id = haul_id,
      value = values,
      reason = paste0(
        "outside ", probs[1], "-", probs[2], " percentiles",
        if (length(use_by) > 0) paste0(" by ", paste(use_by, collapse = "+")) else ""
      ),
      method = "percentile",
      severity = "extreme",
      p_lo = probs[1],
      p_hi = probs[2],
      thr_lo = thr_lo_row[idx],
      thr_hi = thr_hi_row[idx],
      group = key[idx],
      stringsAsFactors = FALSE
    )
  }

  if (k == 0L) {
    return(.empty_outlier_report())
  }

  do.call(rbind, out[seq_len(k)])
}


.collapse_rule_values <- function(d, value_vars) {
  value_vars <- value_vars[value_vars %in% names(d)]

  if (length(value_vars) == 0) {
    return(rep(NA_character_, nrow(d)))
  }

  if (length(value_vars) == 1L) {
    return(as.character(d[[value_vars]]))
  }

  vals <- lapply(value_vars, function(v) as.character(d[[v]]))
  vals <- as.data.frame(vals, stringsAsFactors = FALSE)
  names(vals) <- value_vars

  apply(vals, 1L, function(z) {
    paste(paste(names(z), z, sep = "="), collapse = "; ")
  })
}


.empty_outlier_report <- function() {
  data.frame(
    table = character(0),
    var = character(0),
    row = integer(0),
    haul.id = character(0),
    value = character(0),
    reason = character(0),
    method = character(0),
    severity = character(0),
    p_lo = numeric(0),
    p_hi = numeric(0),
    thr_lo = numeric(0),
    thr_hi = numeric(0),
    group = character(0),
    stringsAsFactors = FALSE
  )
}
