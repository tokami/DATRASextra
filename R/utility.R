
## Main functions ----------------------------------------------------------------


##' @title List all surveys in the DATRAS data base
##'
##' @return A vector with survey names.
##'
##' @export
list_surveys <- function() {

    survey_info_full <- get("survey_info", envir = asNamespace("DATRASextra"))

    return(survey_info)
}







## Internal functions ------------------------------------------------------------

.add_class_datras <- function(x) {
  class(x) <- c("datras_raw", "DATRASraw")
  x
}


.check_class_datras <- function(x, strict = FALSE) {
  if (strict) {
    stopifnot(inherits(x, "datras_raw"))
  } else {
    stopifnot(inherits(x, "datras_raw") || inherits(x, "DATRASraw"))
  }
}




map2bar <- function(value, midL, bar.x) {
    if (length(midL) > 1) {
        approx(midL, bar.x, xout = value, rule = 2)$y
    } else {
        midL
    }
}



quarter2months <- function(quarter) ((quarter - 1) * 3 + 1) : (quarter * 3)
