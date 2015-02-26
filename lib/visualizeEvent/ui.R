library(shiny)

shinyUI(fluidPage(
    includeCSS('./www/my-bootstrap.css'),

    titlePanel("Visualize Event"),

    sidebarLayout(
        sidebarPanel(
            h4('Basic Setting'),
            selectInput(inputId = "dataset",
                        label = "Recurrence:",
                        choices = names(shiny.events.list)
                        ),            
            dateRangeInput("daterange", "Date Range:",
                           start = "2011-04-01",
                           end   = "2015-03-31",
                           startview = "decade"
                           ),
            hr(),
            h4('Autocorrelation'),
            sliderInput("acf.limit", "Upper and Lower Limit:",
                        min=0, max=700, value=c(50, 400)
                        ),
            hr(),
            h4('PerYearPlot'),
            checkboxInput("holidayView", label = "Holiday View", value = TRUE),
            downloadButton('downloadPlot', 'PDF Download', class='btn btn-primary')
            ),
        
        mainPanel(
            h4(textOutput('caption')),

            tabsetPanel(
                tabPanel("History", tableOutput("view")), 
                tabPanel("Analysis",
                         h4('Frequency of wday'),
                         tableOutput("freq.wday"),
                         h4('Frequency of monthweek'),
                         tableOutput("freq.monthweek")
                         ), 
                tabPanel("Autocorrelation", tableOutput("acf")),
                #tabPanel("CorrespondingPointDiff", tableOutput("cpd")),
                tabPanel("PerYearPlot", plotOutput("plotRecurrencePerYear")),
                tabPanel("IntervalPlot", plotOutput("plotInterval"))
                )
            )
        )
    ))
