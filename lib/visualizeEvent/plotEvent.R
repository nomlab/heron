###################################################################################################
## このプログラムの描画するグラフは，作業における1年ごとの動きを視覚的に捉えることを目的としている
## このため，どの年でも横軸を閏年として見た目をあわせている
###################################################################################################
library(ggplot2)
library(scales)

SPECIAL_DATES <- as.Date(read.csv('./db/special_date.csv', header=F)[ ,2])

datesToOccurrences <- function(recurrence, first , last){
    dates <- seq(from=first, to=last, by='day')
    occurrences <- rep(0, length=length(dates))
    len <- length(recurrence)
    for(i in 1:len){
        index <- which(dates == recurrence[i])
        occurrences[index] <- 1
    }
    return(occurrences)
}

####### USAGE #####################################################
## d <- read.csv('hogehoge.csv', header=F)
## recurrence.dates <- as.Date(d[ , 2])
## range <- c(as.Date('2011-04-01'), as.Date('2014-03-31'))
## recurrence.name <- 'GN Meeting'
## plotRecurrencePerYear(recurrence.dates, range, recurrence.name)
plotRecurrencePerYear <- function(recurrence.dates, range, recurrence.name, holidayView=TRUE){
    occurrences <- datesToOccurrences(recurrence.dates, range[1], range[2])
    
    range.dates <- seq(range[1], range[2], by='day')
    range.years <- seq(range[1], range[2], by='year')
    breaks <- c(range.years, range.years[length(range.years)] + 366)
    years <- cut(range.dates, breaks=breaks)
    dummy.dates <- as.Date(NA)
    for(i in 1:length(range.dates)){
        dummy.year <- ifelse(any(format(range.dates[i], '%m') == c('01','02','03')), '2012-', '2011-')
        dummy.dates[i] <- as.Date(paste0(dummy.year, format(range.dates[i],'%m-%d')))
    }
    
    df <- data.frame(date  = dummy.dates,
                     year  = format(as.Date(years),'%Y'),
                     occur = occurrences)

    Sys.setlocale('LC_TIME','C')
    p <- qplot(date, occur, data=df, geom='segment', yend=0, xend=date, size=I(1))
    p <- p + xlab('Date')
    p <- p + ylab('Occurred')
    p <- p + facet_grid(year~.)
    p <- p + scale_x_date(breaks='month', labels=date_format("%b"),
                          limits=c(as.Date("2011-04-01"), as.Date("2012-03-31")))
    p <- p + scale_y_continuous(breaks=seq(0, 1, by=1))
    p <- p + ggtitle(recurrence.name)
    
    if(holidayView){
        special.occur <- datesToOccurrences(SPECIAL_DATES, range[1], range[2])
        df.holiday <- data.frame(date  = dummy.dates,
                                 year  = format(as.Date(years),'%Y'),
                                 occur = special.occur)    
        p <- p + geom_segment(data=df.holiday, aes(x=date, y=occur, yend=0, xend=date),
                              size=I(0.5), col='red')
    }
    
    print(p)
}

plotInterval <- function(recurrence.dates){
    dates.diff <- as.integer(diff(recurrence.dates))
    x <- NULL
    for(i in 1:length(dates.diff)){ x[i] <- paste0(recurrence.dates[i], '~', recurrence.dates[i+1]) }
    df <- data.frame(Interval=dates.diff, Period=1:length(dates.diff))
    p <- ggplot(df, aes(x=Period, y=Interval))
    p <- p + geom_line()
    p <- p + geom_point()
    p <- p + scale_x_continuous(breaks = seq(1, length(dates.diff), by = 1),
                                labels = x)
    p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
    print(p)
}
