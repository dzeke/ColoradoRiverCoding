#Editable table R Shiny
#
# https://stackoverflow.com/questions/22272571/data-input-via-shinytable-in-r-shiny-application
install.packages("rhandsontable")

library(rhandsontable)
library(shiny)

editTable <- function(DF, outdir=getwd(), outfilename="table"){
  ui <- shinyUI(fluidPage(
    
    titlePanel("Edit and save a table"),
    sidebarLayout(
      sidebarPanel(
        helpText("Shiny app based on an example given in the rhandsontable package.", 
                 "Right-click on the table to delete/insert rows.", 
                 "Double-click on a cell to edit"),
        
        wellPanel(
          h3("Table options"),
          radioButtons("useType", "Use Data Types", c("TRUE", "FALSE"))
        ),
        br(), 
       
       sliderInput("ResInitStorageSlider", h3("Initial Reservoir Storage (MAF)"),
                   min = 0, max = 26.1, value = 10),
        br(),
        
        wellPanel(
          h3("Save"), 
          actionButton("save", "Save table"),
          rHandsontableOutput("hot")
        )        
        
      ),
      
      mainPanel(
        textOutput("InitStorageEcho")
        
        #rHandsontableOutput("hot")
        
      )
    )
  ))
  
  server <- shinyServer(function(input, output) {
    
    values <- reactiveValues()
    
    output$InitStorageEcho <- renderText({ 
      paste("You entered", input$ResInitStorageSlider)
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
    })
    
    
    output$hot <- renderRHandsontable({
      
      DF <- values[["DF"]]
      
      if (!is.null(DF)) {
        rhandsontable(DF, useTypes = as.logical(input$useType), stretchH = "all")
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

#( DF <- data.frame(Value = 1:10, Status = TRUE, Name = LETTERS[1:10],
#                   Date = seq(from = Sys.Date(), by = "days", length.out = 10),
#                   stringsAsFactors = FALSE) )

DF <- data.frame(Elevation = seq(from=900, by=50, to=1200), Cutback = seq(from=1.2, by=-0.2, to=0))

editTable(DF)

#Read the table with
#readRDS("table.rds")
