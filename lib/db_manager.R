library('RSQLite', quietly = TRUE)

dbConnect <- function(db, driverName = "SQLite"){
    drv <- DBI::dbDriver(driverName)
    conn <- RSQLite::dbConnect(drv, db)
    return(conn)
}

dbDisconnect <- function(conn){
    res <- RSQLite::dbDisconnect(conn)
}

#########################################################
# Get dates of recurrence
#--------------------------------------------------------
# conn       : connection to DB
# recurrence : name of recurrence
#--------------------------------------------------------
# return     : dates of recurrence
dbGetEventDates <- function(conn, recurrence){
    query <- paste0('SELECT id FROM recurrence WHERE name == "', recurrence, '"')
    recurrence_id <- RSQLite::dbGetQuery(conn, query)
    query <- paste0('SELECT * FROM event WHERE recurrence_id == "', recurrence_id, '"')
    events <- RSQLite::dbGetQuery(conn, query)
    datetimes <- sort(events$start_time)
    dates <- as.Date(datetimes)

    return(dates)
}

dbGetEvents <- function(conn, recurrence){
    query <- paste0('SELECT id FROM recurrence WHERE name == "', recurrence, '"')
    recurrence_id <- RSQLite::dbGetQuery(conn, query)
    if(nrow(recurrence_id) == 0) return(data.frame())
    query <- paste0('SELECT * FROM event WHERE recurrence_id == "', recurrence_id, '"')
    events <- RSQLite::dbGetQuery(conn, query)
    events.ord <- events[order(events$start_time), ]

    names <- events.ord$summary
    dates <- as.Date(events.ord$start_time)
    result <- data.frame(name=names, date=dates)

    return(result)
}

dbGetRecurrences <- function(conn){
    query <- paste0('SELECT id FROM recurrence')
    recurrence_ids <- RSQLite::dbGetQuery(conn, query)[ ,'id']
    result <- list()
    if(length(recurrence_ids) == 0) return(result)
    recurrence_names <- c()
    for(recurrence_id in recurrence_ids){
        query <- paste0('SELECT name FROM recurrence WHERE id = ', recurrence_id)
        recurrence_names <- c(recurrence_names, RSQLite::dbGetQuery(conn, query)[ ,'name'])

        query <- paste0('SELECT * FROM event WHERE recurrence_id == "', recurrence_id, '"')
        events <- RSQLite::dbGetQuery(conn, query)
        events.ord <- events[order(events$start_time), ]

        names <- events.ord$name
        dates <- as.Date(events.ord$start_time)
        result <- c(result, list(data.frame(name=names, date=dates)))
    }
    names(result) <- recurrence_names
    return(result)
}
