##' @title Format DATRAS data
##'
##' @param x a datras_raw object.
##' @param ... extra options
##'
##' @return Dataframe in format x.
##'
##' @export
##' @method format datras_raw
format.datras_raw <- function(x, ...) {

    res <- x

    ## TODO different formatting, long format, short format...

    return(res)
}



##' @title Create long-format table
##'
##' @param x a datras_raw object.
##'
##' @return Long-format table
##'
##' @export
as_long_format <- function(x) {

    res <- x[[2]][,c("Survey","Gear","Country","Ship",
                     "Year","Quarter",
                     "Month","Day", "lon","lat",
                     "timeOfYear","abstime", "DayNight", "TimeShotHour",
                     "HaulDur")]
    if(any(colnames(x[[2]]) == "Area_27")){
        res <- data.frame(res, Area_27 = x[[2]]$Area_27)
    }
    if(any(colnames(x[[2]]) == "Area_km2")){
        res <- data.frame(res, Area_km2 = x[[2]]$Area_km2)
    }
    if(any(colnames(x[[2]]) == "HaulWgt")){
        res <- data.frame(res, HaulWgt = x[[2]]$HaulWgt)
    }
    res$Species <- unique(x[[3]]$Species)

    return(res)
}
