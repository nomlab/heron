FiscalYearFirstDate <- function(date){
    y <- as.integer(format(date, "%Y"))
    m <- as.integer(format(date, "%m"))
    if(any(m == c(1,2,3))) y <- y - 1
    return(as.Date(paste0(y, "-4-1")))
}

DatePrettyPrint <- function(date){
    return(cat(format(forecasted, '%Y-%m-%d\n')))
}

monthweek <- function(date){
    return(paste0(format(date, '%b'), floor((as.integer(format(date, '%d')) - 1) / 7) + 1, 'w'))
}

monthweeks <- function(dates){
    return(sapply(dates, monthweek))
}
