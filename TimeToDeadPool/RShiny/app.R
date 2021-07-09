# app.R
# R Shiny application for Reservoir Time to Dead Pool
#
# Creates one user input: Initial Storage

library(shiny)
library(rhandsontable)

# Define UI ----
ui <- fluidPage(
  titlePanel("Time To Reservoir Dead Pool"),
  
  sidebarLayout(position = "left",
                sidebarPanel("Inputs",
                             
                sliderInput("ResInitStorageSlider", h3("Initial Reservoir Storage (MAF)"),
                                         min = 0, max = 26.1, value = 10)
                #numericInput("ResInitStorage", 
                #  h4("Initial Reservoir Storage (MAF)"), 
                #  value = 10)             
                ),
                
                
                
                mainPanel("Results",
                    textOutput("InitStorageEcho"))
  ) 
)

# Define server logic ----

server <- function(input, output) {
  output$InitStorageEcho <- renderText({ 
    paste("You entered", input$ResInitStorageSlider)
  })
  
}

# Run the app ----
shinyApp(ui = ui, server = server)