datesToOcurreds <- function(dates, range){
    len <- diff(range) + 1
    occurreds <- rep(0, len)
    seq.dates <- seq(from=range[1], to=range[2], by=1)
    names(occurreds) <- seq.dates
    # FIX ME
    for(i in 1:length(dates)){
        for(j in 1:length(seq.dates)){
            if(dates[i] == seq.dates[j]){
                occurreds[j] <- 1
            }
        }
    }
    return(occurreds)
}

## Get AutoCorrelation in each lags
## f : elapsed-day-data
getAC <- function(f, range){
    start <- 0
    end <- diff(range)
    
    ac <- rep(0, end - start + 1)
    names(ac) <- start:end

    for(lag in start:end){
        p <- f[(lag+1):length(f)] * f[1:(length(f)-lag)]
        ac[lag] <- mean(p) # sum(p) / length(p)  定義上はR(τ)=E[f(t)*f(t-τ)]
    }

    return(ac)
}

## FIX ME!!!!!!!!
## cycle of big wave = cycle given max AC
getBigWaveCycle <- function(dates, range, limit.upper = 400, limit.lower = 50){
    series <- datesToOcurreds(dates, range)
    ac <- getAC(series, range)
    
    ac.order <- order(ac, decreasing=TRUE)
    x <- ac[ac.order]

    ac.order <- ac.order[x/max(x) > 0.1] # 閾値より大きな自己相関
    ac.order <- ac.order[ac.order < limit.upper]  # 長すぎる周期はカット
    ac.order <- ac.order[ac.order > limit.lower]   # 小さな波を除外（本来この処理はすべきではない）

    if(is.integer0(ac.order)){ # 周期が得られなかった場合
        cycle.bigwave <- 0
    }else{
        cycle.bigwave <- ac.order[1]
    }
    
    return(cycle.bigwave)
}

is.integer0 <- function(x){
  is.integer(x) && length(x) == 0L
}
