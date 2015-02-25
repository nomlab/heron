FiscalYearFirstDate <- function(date){
    y <- as.integer(format(date, "%Y"))
    m <- as.integer(format(date, "%m"))
    if(any(m == c(1,2,3))) y <- y - 1
    return(as.Date(paste0(y, "-4-1")))
}
