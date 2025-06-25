
##' @title Clean data
##'
##' @param x a DATRASraw object.
##'
##' @return Cleaned DATRASraw object.
##'
##' @importFrom mgcv gam s predict.gam
##'
##' @export
clean <- function(x, aphias = NULL, years = NULL, quarters = NULL,
                  gears = NULL, impute.missing.depth = TRUE,
                  correct.species = TRUE){

    ## Minimum cleaning
    x <- subset(x,
                HaulVal == "V",  ## keep valid hauls only
                StdSpecRecCode == 1 ## all standard species recorded
                )

    ## Optional subsetting
    if(!is.null(aphias)){
        x <- subset(x,
                       Valid_Aphia %in% aphias)
    }
    if(!is.null(years)){
        x <- subset(x,
                       Year %in% years)
    }
    if(!is.null(quarters)){
        x <- subset(x,
                       Quarter %in% quarters)
    }
    if(!is.null(gears)){
        x <- subset(x,
                       Gear %in% gears)
    }


    ## Impute depths
    if (impute.missing.depth && any(is.na(x[[2]]$Depth))) {
        dmodel <- mgcv::gam(log(Depth) ~ s(lon, lat, k = 200), data = x[[2]])
        sel <- subset(x, is.na(Depth))
        sel$Depth <- 0 ## Guard against NA-error
        x$Depth[is.na(x$Depth)] <- exp(mgcv::predict.gam(dmodel, newdata = sel[[2]]))
        sel <- dmodel <- NULL; gc()
    }


    ## Species correction
    x <- correctSpecies(x)

    return(x)
}
