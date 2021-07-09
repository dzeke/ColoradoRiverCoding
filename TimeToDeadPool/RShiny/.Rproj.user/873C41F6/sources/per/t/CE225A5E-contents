# Try #2 at Table Input
# https://stackoverflow.com/questions/22272571/data-input-via-shinytable-in-r-shiny-application

install.packages("rhandsontable")

library(rhandsontable)
library(shiny)

editTable <- function(DF, outdir=getwd(), outfilename="table"){
  ui <- shinyUI(fluidPage(
    
    titlePanel("Time To Reservoir Dead Pool"),
    sidebarLayout(
      sidebarPanel(
        helpText("Specify initial reservoir storage and table of water delivery cutbacks. R Shiny will show plot of cutbacks and reservoir storage over time with different steady inflows (stress test)."),
        
       # wellPanel(
       #   h3("Table options"),
       #   radioButtons("useType", "Use Data Types", c("TRUE", "FALSE"))
       # ),
        
        sliderInput("ResInitStorageSlider", h4("Initial Reservoir Storage (MAF)"),
                    min = 0, max = 26.1, value = 10),
        br(),
        
 #       wellPanel(
          h4("Delivery Cutback Schedule"),
          helpText("Right-click on the table to delete/insert rows.", 
                   "Double-click on a cell to edit. Click Save table to show changes."),
          br(),
          rHandsontableOutput("hot"),
          br(),
          actionButton("save", "Save table")
 #       )        
        
      ),
      
      mainPanel(
        textOutput("InitStorageEcho"),
        br(),
        textOutput("CutbackValue"),
        br(),
        plotOutput("CutbackPlot")
        
        
      )
    )
  ))
  
  server <- shinyServer(function(input, output) {
    
    values <- reactiveValues()
    
    output$InitStorageEcho <- renderText({ 
        paste0("Initial storage is ", input$ResInitStorageSlider, " MAF")
        })
    
   
    ## Handsontable
    observe({
      if (!is.null(input$hot)) {
        DF = hot_to_r(input$hot)
      } else {
        if (is.null(values[["DF"]]))
          DF <- DF
        else
          DF <- values[["DF"]]
      }
      values[["DF"]] <- DF
      
      output$CutbackValue <- renderText({ 
        paste0("Cutback entry [3,2] is ", DF[3,2], " MAF/year")
      }) 
      
      output$CutbackPlot <- renderPlot({
          plot(DF$Elevation,DF$Cutback)
      })
      
    })
    
    output$hot <- renderRHandsontable({
      DF <- values[["DF"]]
      if (!is.null(DF)) {
        # rhandsontable(DF, useTypes = as.logical(input$useType), stretchH = "all")   # read from input
        rhandsontable(DF, useTypes = TRUE, stretchH = "all")   #static
        
      }
    })
    
    
    ## Save 
    observeEvent(input$save, {
      finalDF <- isolate(values[["DF"]])
      saveRDS(finalDF, file=file.path(outdir, sprintf("%s.rds", outfilename)))

    })
    
  })
  
  ## run app 
  runApp(list(ui=ui, server=server))
  return(invisible())
}

DF <- data.frame(Elevation = seq(from=900, by=50, to=1200), Cutback = seq(from=1.2, by=-0.2, to=0))

editTable(DF)