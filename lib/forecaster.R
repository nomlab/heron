source('./lib/acf.R')

csvpath <- './db/holidays.csv'
NHOLIDAYS <- as.Date(read.table(csvpath, header=F)[ ,1])
NHOLIDAY <- '祝'

# events : array of date sorted by date
# date   : target date
closestEventIndex <- function(events, date){
    last <- length(events)
    for(i in 1:(last-1)){
        if(events[i] <= date && date <= events[i+1]){
            # closer date of i and i+1
            return(ifelse(date - events[i] < events[i+1] - date, i, i+1))
        }
    }

    # ここに入ると，近傍の日付は返せるが，予測はできない
    if(events[last] < date){
        return(last)
    }else if(date < events[1]){
        return(1)
    }
}

closestEvent <- function(events, date){
    return(events[closestEventIndex(events, date)])
}

# range  : range of candidate dates
# period : 閏年はひとまず無視，また自己相関関数での利用も無視
getCandidates <- function(events, range, period){
    latest <- events[length(events)]
    criterion <- latest - period

    i <- closestEventIndex(events, criterion)
    d <- events[i+1] - events[i]
    if(d > 365) d <- 365
    pivot <- latest + d
    candidates <- pivot + range

    ## 1年前の発生間隔が非常に短いとき，予測日としてリカーレンスの最後の日付より前が選ばれる可能性有り
    ## これを防ぐために候補日を限定
    candidates <- candidates[latest < candidates]

    return(candidates)
}

smoothingOccurred <- function(recurrences){
    dates <- seq(as.Date('2000-1-1'), length=366, by=1)
    dates <- format(dates, '%m-%d')
    occurred <- rep(0, length(dates))
    for(i in 1:length(recurrences)){
        occurred[which(dates == names(recurrences)[i])] <- recurrences[i] / min(recurrences)
    }
    o <- which(occurred != 0)
    for(i in 1:(length(o)-1)){
        len <- floor((o[i+1] - o[i])/2)
        if(len != 0){
            occurred[o[i] + 1:len] <- occurred[o[i]] / (1 + 1:len)
            occurred[o[i+1] - 1:len] <- occurred[o[i+1]] / (1 + 1:len)
        }
    }
    names(occurred) <- dates
    return(occurred)
}

##########################################
# Smoothing Teacher Signal
#-----------------------------------------
# ts     : ts (logical) of vector
# return : smooth ts (numeric) of vector
##########################################
# Example
#-----------------------------------------
# ts     : c(  0,   0,   0,  1,   0,   0)
# return : c(0.1, 0.3, 0.6,  1, 0.6, 0.3)
##########################################
smoothingTS <- function(ts){
    ts.smooth <- ts
    o <- which(ts != 0)
    for(i in 1:(length(o)-1)){
        len <- floor((o[i+1] - o[i])/2)
        if(len != 0){
            ts[o[i] + 1:len] <- ts[o[i]] / (1 + 1:len)
            ts[o[i+1] - 1:len] <- ts[o[i+1]] / (1 + 1:len)
        }
    }
    return(ts)
}

##########################################
# Generate logistic matrix
#-----------------------------------------
# cdv    : Categorical data of vector
# return : matrix
##########################################
# Example
#-----------------------------------------
# cdv    : c('Sun', 'Mon', 'Thu', ...)
# return :
#           Sun Mon Tue Wed Thu Fir Sat
#          (  1,  0,  0,  0,  0,  0,  0,
#             0,  1,  0,  0,  0,  0,  0,
#             0,  0,  0,  0,  1,  0,  0,
#           ...
##########################################
genLM <- function(cdv){
    nrow <- length(cdv)
    col.uniq <- unique(cdv)
    ncol <- length(col.uniq)
    m <- matrix(0, nrow=nrow, ncol=ncol)
    colnames(m) <- col.uniq
    for(i in 1:nrow){
        index <- which(cdv[i] == col.uniq)
        m[i, index] <- 1
    }
    return(m)
}

getLMAll <- function(plist, first, last){
    dates <- seq(from=first, to=last, by='day')
    plist.alldate <- getParamsList(dates, mode)
    cols <- colnames(plist.alldate)
    LM <- genLM(plist.alldate[ ,cols[1]])
    if(length(cols) > 1){
        for(col in cols[2:length(cols)]){
            LM <- cbind(LM, genLM(plist.alldate[ ,col]))
        }
    }
    return(LM)
}

# Read all files in 'path'
myReadCSV <- function(path){
    filenames <- list.files(path, full.names=T)
    d <- numeric(0)
    for(f in filenames){
        tmp <- read.csv(f, header=F)
        d <- rbind(d, tmp)
    }
    return(d)
}

# Teacher Signal
getTS <- function(recurrence, first , last){
    dates <- seq(from=first, to=last, by='day')
    ts <- rep(0, length=length(dates))
    nrow <- length(recurrence)
    for(i in 1:nrow){
        index <- which(dates == recurrence[i])
        ts[index] <- 1
    }
    return(ts)
}

# Is national holiday?
is.nholiday <- function(date){
    return(any(NHOLIDAYS == date))
}

# Is holiday?
is.holiday <- function(date){
    return(is.nholiday(date) || weekdays(date)=='土曜日' || weekdays(date)=='日曜日')
}

nholidays <- function(dates){
    return(sapply(dates, is.nholiday))
}

holidays <- function(dates){
    return(sapply(dates, is.holiday))
}

weekday_string_considering_nholiday <- function(date){
    if(is.nholiday(date))
        return(NHOLIDAY)
    else
        return(weekdays(date))
}

weekdays_considering_nholiday <- function(dates){
    return(sapply(dates, weekday_string_considering_nholiday))
}

# week of month
monthweek <- function(date){
    ## return(paste0(format(date, '%b'), 'm',floor((as.integer(format(date, '%d')) - 1) / 7) + 1, 'w'))
    return(floor((as.integer(format(date, '%d')) - 1) / 7) + 1)
}

monthweeks <- function(dates){
    return(sapply(dates, monthweek))
}

# FIXME 適当過ぎ
annualLM <- function(dates, first, last){
    LMs <- numeric(0)
    monthdays.uni <- unique(format(dates, '%m-%d'))
    alldates <- seq(from=first, to=last, by=1)
    cnttable.max <- table(format(alldates, '%m-%d'))
    cnttable.target <- table(format(dates, '%m-%d'))
    for(monthday in monthdays.uni){
        len.max <- cnttable.max[monthday]
        len.target <- cnttable.target[monthday]
        if(len.max == len.target){
            index <- which(format(alldates, '%m-%d') == monthday)
            LM <- rep(0, length = last - first + 1)
            LM[index] <- 1
            LMs <- cbind(LMs, LM)
            colnames(LMs)[ncol(LMs)] <- monthday
        }
    }
    return(LMs)
}

##########################################
# Generate parameters list
#-----------------------------------------
# dates  : date of vector
# return : list of parameters
##########################################
# Example
#-----------------------------------------
# dates  : c('2013/4/2', '2013/4/3', ...)
# return :
#           date  wday week month monthday
#    ('2013/4/2',  Wed,   1,    4,       2
#     '2013/4/3',  Thu,   1,    4,       3
#      ...
##########################################
getParamsList <- function(dates, mode){
    d.wdays  <- weekdays_considering_nholiday(dates)
    #d.wdays  <- weekdays(dates)
    d.weeks  <- monthweeks(dates)
    d.months <- months(dates)
    d.monthdays <- format(dates, '%m-%d')
    d.holidays <- holidays(dates)
    plist <- data.frame(d.wdays, d.weeks, d.months, d.monthdays, d.holidays)
    colnames(plist) = c('wday', 'week', 'month', 'monthday', 'holiday')

    if(     mode == 'useall'  ) plist <- plist
    else if(mode == 'weekly'  ) plist <- plist[ ,c('wday', 'week', 'month')]
    else if(mode == 'monthly' ) plist <- plist[ ,c('wday', 'week', 'month', 'holiday')]
    else if(mode == 'yearly'  ) plist <- plist[ ,c('wday', 'week', 'month', 'monthday', 'holiday')]
    else if(mode == 'wdayonly') plist <- data.frame(wday=plist[ ,c('wday')]) # data.frameから1列だけとると型が変わってしまう

    return(plist)
}

# Get weight by Regression Analysis
getW <- function(ts, LM){
    x <- data.frame(cbind(ts, LM))
    res <- lm(ts~., x) # 線形回帰，'.'は説明変数に非説明変数以外の全てを指定する

    # res <- glm(ts~., x, family=binomial(link='logit')) # ロジスティック回帰
    # res <- nls(.. # 非線形回帰は可能？

    ## print(summary(res))
    coef <- res$coefficients
    coef[is.na(coef)==TRUE] <- 0
    ## print(coef)

    return(coef)
}


getF <- function(candidates.plist, LM, W, mode, annuLM, candidates.date){
    cn.LM <- colnames(LM)
    m <- matrix(0, nrow=nrow(candidates.plist), ncol=length(cn.LM))
    colnames(m) <- cn.LM
    cols <- colnames(candidates.plist)
    for(col in cols){
        for(i in 1:nrow(m)){
            index <- which(candidates.plist[i, col] == cn.LM)
            m[i, index] = 1
        }
    }

    cols <- colnames(annuLM)
    for(i in 1:length(cols)){
        col <- cols[i]
        for(i in 1:nrow(m)){
            index <- which(format(candidates.date,'%m-%d') == col)
            m[index, col] = 1
        }
    }

    # F = X * W
    f <- m %*% W[2:length(W)] + W[1] # W[1]は切片
    F <- apply(f,1,sum)

    return(F)
}

# 本体
forecast <- function(mode, range.recurrence, range.candidates, events){

    # Recurrence: 繰返作業履歴
    first <- range.recurrence[1]
    last  <- range.recurrence[2]
    recurrence <- as.Date(events[ ,2])
    recurrence <- recurrence[first <= recurrence & recurrence <= last]
    recurrence.plist <- getParamsList(recurrence, mode)

    # Candidates: 次の作業の候補日
    ## period <- 365
    period <- getBigWaveCycle(recurrence, range.recurrence, limit.upper=400, limit.lower=50)
    if(period == 0) period <- 365
    
    candidates <- getCandidates(recurrence, range.candidates, period)
    candidates.plist <- getParamsList(candidates, mode)

    # ts = LM * W からWを求めた後
    #  F =  X * W からFを求める
    LM <- getLMAll(recurrence.plist, first, last)

    ## FIXME 今回はここにannualを無理矢理いれるが，あとで構造を見直すこと．business-tripも同じ問題にあたる
    annuLM <- annualLM(recurrence, first, last)
    if(length(annuLM) != 0) LM <- cbind(LM, annuLM)

    ## if(length(annuLM) != 0) LM <- annuLM
    ## else return(Sys.Date())

    ts <- getTS(recurrence, first, last)
    #ts <- smoothingTS(ts) # 実際の発生日に近いほど発生し得たとする
    W <- getW(ts, LM)

    ## f <- getF(candidates.plist, LM, W, mode)
    f <- getF(candidates.plist, LM, W, mode, annuLM, candidates)
    names(f) = format(candidates, '\'%y/%m/%d(%a)')

    index <- which.max(f)
    forecasted <- candidates[index]

    return (forecasted)
}
