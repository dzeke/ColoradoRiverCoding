###  Build Interative Parallel Coordinate Plot for Runge Et Al (2015) Glend Canyon Dam Adaptive Management Alternatives
###  Also show a matrix correlation plot for all objectives
#
#  Read in Table 7 (Full Consequence table) and plot in interactive parallel coordinates.
#
# David Rosenberg
# Utah State University
# david.rosenberg@usu.edu
# November 13, 2018
# Updated March 4, 2019

# Load the relevant packages
if (!require(plotly)) { 
  install.packages("plotly", repos="http://cran.r-project.org/")
  #install.packages("plotly", repos="https://cran.r-project.org/src/contrib/Archive/plotly/")
  library(plotly) 
}

if (!require(crosstalk)) { 
  install.packages("crosstalk", repos="http://cran.r-project.org") 
  library(crosstalk) 
}

if (!require(gclus)) { 
  install.packages("gclus", repos="http://cran.r-project.org") 
  library(gclus) 
}

# Read CSV into R
RungeAlternatives <- read.csv(file="RungeTable7.csv", 
                               header=TRUE, 
                                
                               stringsAsFactors=FALSE,
                               sep=",")

# Drop the first column
RungeVars <- names(RungeAlternatives)
myvars <- names(RungeAlternatives) %in% c(RungeVars[1])
RungeNumeric <- RungeAlternatives[!myvars]

#Add a variable for the alternative number
#RungeNumeric$AltLetter <- substr(RungeAlternatives$Strategy,1,1)
#Hard coding. How to convert from letter to number for a variable?
RungeNumeric$AltNum <- c(1,2,2,3,3,3,3,4,4,4,4,5,5,5,5,5,5,6,7)

#Again hard code. Axis labels.
RungeVarsAbrev <- c('HB Chub','HBC Suit.', "RBT Catch", "RBT Emig.", 
                    "RBT Qual.",   
                    "Wind Tr.", "GC Flow", "Time Off Riv.",         
                    "Power Gen.", "Power Cap.", "Camp Area",           
                    "Flow Fluct.", "GC Raft",  "Rip. Veg.",          
                    "Sand Load",  "Marsh" , "Mech. Rem.",           
                    "Trout Flow", "Alter.")

RungeAlts <- c('A-No action', 'B-Increase hydropower', 'C-Condition dependent adaptive', 'D-Combined (C+E)','E-Resource targeted condition dependent','F-More natural flow', 'G-Steady flows')

# Flip the 4, 7, 13, 17, and 18th variables where desired is a low value
cColsToFlip <- c(4,7,13,17,18)
RungeNumericFlip <- RungeNumeric
RungeNumericFlip[,cColsToFlip] <- -RungeNumeric[,cColsToFlip]
RungeVarsAbrevFlip <- RungeVarsAbrev
RungeVarsAbrevFlip[cColsToFlip] <- paste0("-",RungeVarsAbrev[cColsToFlip],"")

### Load Using Plotly
# https://plot.ly/r/getting-started/

# Provide Plotly credentials
Sys.setenv("plotly_username"="dzeke")
Sys.setenv("plotly_api_key"="k3599slnERhsfjhKjQnR")

# Follow these instructions
# https://plot.ly/r/parallel-coordinates-plot/

packageVersion('plotly')

# Create a shareable link to your chart
# Set up API credentials: https://plot.ly/r/getting-started
chart_link = api_create(p, filename="parcoords-dimensions")
chart_link

#df <- read.csv("https://raw.githubusercontent.com/bcdunbar/datasets/master/iris.csv")

#Calculate mins and maxes
mins <- apply(RungeNumericFlip,2,min)
maxes <- apply(RungeNumericFlip,2,max)

p1 <- RungeNumericFlip %>%
  plot_ly(type = 'parcoords',
          #line = list(color='blue'),
          line = list(color =  ~AltNum,
                      colorscale = 'Viridis', #Jet',
                      showscale = FALSE,
                      reversescale = TRUE,
                      cmin = 1,
                      cmax = 7),
                    #  cmin = 1, cmax = 7,
                   # Colorscale is not working. Would like a scale that shows the color and scenario letter.   
                   #   showscale = TRUE,
                  #    colorscale = list(c(1,'black'),c(2,'red'),c(3,'blue'),c(4,'blue4'),c(5,'chartreuse'),c(6,'green'),c(7,'orange') )),
                #      colorscale = list(c(1,'black'),c(2,'red'),c(3,'black'),c(4,'black'),c(5,'black'),c(6,'black'),c(7,'black') )),

          dimensions = list(
            list(range = c(mins[1],maxes[1]),
                 label = RungeVarsAbrevFlip[1], values =  ~Humpback.Chub,
                 tickvals= c(mins[1],maxes[1])),
            list(range = c(mins[2],maxes[2]),
                 label = RungeVarsAbrevFlip[2], values = ~Temp.Suit,
                 tickvals= c(mins[2],maxes[2])),
            list(range = c(mins[3],maxes[3]),
                 label = RungeVarsAbrevFlip[3], values =  ~Rainbow.Trout.Catch,
                 tickvals= c(mins[3],maxes[3])),
            list(range = c(mins[4],maxes[4]),
                 label = RungeVarsAbrevFlip[4], values = ~Rainbow.Trout.Emigrate,
                 tickvals= c(mins[4],maxes[4])),
            list(range = c(mins[5],maxes[5]),
                 tickvals = c(mins[5],maxes[5]),
                 label = RungeVarsAbrevFlip[5], values = ~Rainbow.Trout.Quality),
            list(range = c(mins[6],maxes[6]),
                 tickvals = c(mins[6],maxes[6]),
                 label = RungeVarsAbrevFlip[6], values = ~Wind.Transport.Sediment.Index),
            list(range = c(mins[7],maxes[7]),
                 tickvals = c(mins[7],maxes[7]),
                 label = RungeVarsAbrevFlip[7], values = ~Grand.Canyon.Flow.Index),
            list(range = c(mins[8],maxes[8]),
                 tickvals= c(mins[8],maxes[8]),
                 label = RungeVarsAbrevFlip[8], values = ~Time.off.River.Index),
            list(range = c(mins[9],maxes[9]),
                 tickvals = c(mins[9],maxes[9]),
                 label = RungeVarsAbrevFlip[9], values = ~Power.Generation),
            list(range = c(mins[10],maxes[10]),
                 tickvals = c(mins[10],maxes[10]),
                 label = RungeVarsAbrevFlip[10], values = ~Power.Cap.),
            list(range = c(mins[11],maxes[11]),
                 tickvals = c(mins[11],maxes[11]),
                 label = RungeVarsAbrevFlip[11], values = ~Camp.Area.Index),
            list(range = c(mins[12],maxes[12]),
                 tickvals = c(mins[12],maxes[12]),
                 label = RungeVarsAbrevFlip[12], values = ~Fluctuation.Index),
            list(range = c(mins[13],maxes[13]),
                 tickvals = c(mins[13],maxes[13]),
                 label = RungeVarsAbrevFlip[13], values = ~GC.Raft),
            list(range = c(mins[14],maxes[14]),
                 tickvals = c(mins[14],maxes[14]),
                 label = RungeVarsAbrevFlip[14], values = ~Riparian.Veg..Index),
            list(range = c(mins[15],maxes[15]),
                 tickvals = c(mins[15],maxes[15]),
                 label = RungeVarsAbrevFlip[15], values = ~Sand.Load.Index),
            list(range = c(mins[16],maxes[16]),
                 tickvals = c(mins[16],maxes[16]),
                 label = RungeVarsAbrevFlip[16], values = ~Marsh),
            list(range = c(mins[17],maxes[17]),
                 tickvals = c(mins[17],maxes[17]),
                 label = RungeVarsAbrevFlip[17], values = ~Mechanical.Removal),
            list(range = c(mins[18],maxes[18]),
                 tickvals = c(mins[18],maxes[18]),
                 label = RungeVarsAbrevFlip[18], values = ~Trout.Manage.Flow),
            #Add the alternative number at the end for help interpreting
            list(range = c(mins[19],maxes[19]),
                 tickvals = c(mins[19],maxes[19]),
                 label = RungeVarsAbrev[19], values = ~AltNum)
            )
         )


print (p1)

# Create a shareable link to your chart
# Set up API credentials: https://plot.ly/r/getting-started
chart_link = api_create(p1, filename="parcoords-basic")
chart_link

# Show another matrix correlation plot (18 x 18)
# Calculate correlation matrix for variables
# Approach #1 from https://www.r-bloggers.com/scatter-plot-matrices-in-r/

#Set the column names 
names(RungeNumeric) <- RungeVarsAbrev

corMatrix <- cor(RungeNumeric[,1:18])

# Approach #2 from https://www.r-bloggers.com/scatter-plot-matrices-in-r/
pairs(RungeNumeric[,1:18], upper.panel = NULL)


# Approach #4 https://www.statmethods.net/graphs/scatterplot.html. Scatter matrix color coding panels that are highly correlated
# Scatterplot Matrices from the glus Package

corMatrixAbs <- abs(corMatrix) # get correlations
dta.col <- dmat.color(corMatrixAbs) # get colors
#Keep column order as is
dta.o <- c(1:18) #order.single(corMatrixAbs)
cpairs(RungeNumeric, dta.o, panel.colors=dta.col, gap=.5,
       main="Correlation Matrix of Glen Canyon Dam Adaptive Management Objectives") 


# Remove alternative #6 (F-Steady flow) and keep 14 columns (prune)
# 1, 2, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18  
RungeNumericPrune <- RungeNumeric[, c(1, 2, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)] %>% filter(RungeNumeric$Alter. != 6)

# Replot the scatter plot
corMatrixPrune <- abs(cor(RungeNumericPrune))
dta.col <- dmat.color(corMatrixPrune) # get colors
#Keep column order as is
dta.o <- c(1:(ncol(RungeNumericPrune))) #order.single(corMatrixAbs)
cpairs(RungeNumericPrune, dta.o, panel.colors=dta.col, gap=.5,
       main="Correlation Matrix of Glen Canyon Dam Adaptive Management Objectives", upper.panel = NULL) 

