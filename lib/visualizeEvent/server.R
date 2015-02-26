library(shiny)

shinyServer(function(input, output) {
    
    datasetInput <- reactive({
        data <- shiny.events.list[[input$dataset]]
        colnames(data) <- c('Name', 'Date')
        range <- input$daterange
        data[ , 'Date'] <- as.Date(data[ , 'Date'])
        data <- data[data[ ,'Date'] > range[1], ]
        data <- data[data[ ,'Date'] < range[2], ]
        data
    })

    renderPlotRecurrencePerYear <- function(){
        range <- input$daterange
        recurrence.name <- '' #input$dataset
        plotRecurrencePerYear(datasetInput()[, 'Date'], range, recurrence.name,
                              holidayView=input$holidayView)
    }

    dateFreq <- function(formatfunc){
        dates <- datasetInput()[, 'Date']
        freq <- table(formatfunc(dates)) / length(dates) * 100
        df <- data.frame(sort(freq, decreasing=TRUE))
        names(df) <- 'Frequency(%)'
        df
    }

    renderPlotInterval <- function(){
        plotInterval(datasetInput()[, 'Date'])
    }

    output$caption <- renderText({
        input$dataset
    })

    output$freq.wday <- renderTable({
        dateFreq(function(dates){format(dates, '%A')})
    })

    output$freq.monthweek <- renderTable({
        dateFreq(monthweeks)
    })

    output$view <- renderTable({
        d <- datasetInput()
        d[ ,'Date'] <- as.factor(d[ ,'Date'])
        d
    })

    output$acf <- renderTable({
        cycle <- getBigWaveCycle(datasetInput()[, 'Date'], input$daterange,
                                 limit.lower=input$acf.limit[1],
                                 limit.upper=input$acf.limit[2])
        data.frame(cycle)
    })

    output$cpd <- renderTable({
        series <- datesToOccurrences(datasetInput()[, 'Date'],
				     input$daterange[1], input$daterange[2])
	res <- CorrespondingPointDiff(series, 365)
	data.frame(res)
    })

    output$plotRecurrencePerYear <- renderPlot({
        renderPlotRecurrencePerYear()
    })

    output$downloadPlot <- downloadHandler(
        filename = function(){
            paste0(input$dataset, Sys.Date(), '.pdf')
        },
        content = function(file){
            pdf(file, height=5, width=10)
            renderPlotRecurrencePerYear()
            dev.off()
        }
    )

    output$plotInterval <- renderPlot({
        renderPlotInterval()
    })

})
