# ParticipantPlots.r
#
# Make stacked graph comparing participant actions during a session to Law of the River operations. The plots include (from top to bottom):
#
# A) Combined storage versus time (Participants and Law of River)
# B) Consumptive use (Upper Basin and Lower Basin, Participants and Law of River)
# C) Storage in Powell as a % of combined storage
# D) Powell release temperature and fish outcome
#
# All data drawn from PilotFlexAccounting-CombinedPowellMead-ParticipantsExample.xlsx workbook
#
# David E. Rosenberg
# January 24, 2022 
# Utah State University
# david.rosenberg@usu.edu
#


rm(list = ls())  #Clear history

# Load required libraies

if (!require(tidyverse)) { 
  install.packages("tidyverse", repos="https://cran.cnr.berkeley.edu/", verbose = TRUE) 
  library(tidyverse) 
}

if (!require(readxl)) { 
  install.packages("readxl", repos="http://cran.r-project.org") 
  library(readxl) 
}

  
if (!require(RColorBrewer)) { 
  install.packages("RColorBrewer",repos="http://cran.r-project.org") 
  library(RColorBrewer) # 
}

if (!require(dplyr)) { 
  install.packages("dplyr",repos="http://cran.r-project.org") 
  library(dplyr) # 
}

if (!require(expss)) { 
  install.packages("expss",repos="http://cran.r-project.org") 
  library(expss) # 
}

if (!require(reshape2)) { 
  install.packages("reshape2", repos="http://cran.r-project.org") 
  library(reshape2) 
}

if (!require(pracma)) { 
  install.packages("pracma", repos="http://cran.r-project.org") 
  library(pracma) 
}

if (!require(lubridate)) { 
  install.packages("lubridate", repos="http://cran.r-project.org") 
  library(lubridate) 
}

if (!require(directlabels)) { 
  install.packages("directlabels", repo="http://cran.r-project.org")
  library(directlabels) 
}

if (!require(plyr)) { 
  install.packages("plyr", repo="http://cran.r-project.org")
  library(plyr) 
}

if (!require(ggplot)) { 
  install.packages("ggPlot", repo="http://cran.r-project.org", dependencies = T)
  library(ggplot) 
}

if (!require(stringr)) { 
  install.packages("stringr", repo="http://cran.r-project.org")
  library(stringr) 
}


# Load Data
# Set up a dataframe to describe locations in the Excel workbook where the data is

sStartCol <- 3
nCols <- 3

#Create column headers for year
cColHeads <- paste(rep("Year",nCols),seq(1:nCols),"")

dfDataToLoad <- data.frame(Description = c("Combined Storage", "Combined Storage", "Consumptive Use-Lower Basin", "Consumptive Use-Lower Basin", "Consumptive Use-Upper Basin", "Consumptive Use-Upper Basin", "Storage in Powell", "Storage in Powell", "Powell Release Temperature", "Powell Release Temperature", "Fish Outcome", "Fish Outcome"),
                           Sheet = rep(c("Participants", "LawOfRiver"),6),
                           Row = c(131, 127, 119, 115, 118, 114, 132, 128, 139, 135, 140, 136))

# Calculate the cell range from the provided information
dfDataToLoad$Range <- paste0(LETTERS[sStartCol],dfDataToLoad$Row,":",LETTERS[sStartCol+nCols-1],dfDataToLoad$Row, sep="")

# Define the Excel file with all the data
sExcelFile <- 'PilotFlexAccounting-CombinedPowellMead-ParticipantExample.xlsx'

# Read in the Combined Storage values
# Read first row
dfAllData <- read_excel(sExcelFile, col_names = FALSE, sheet = dfDataToLoad$Sheet[1],  dfDataToLoad$Range[1])
#Loop over remaining rows
for(i in 2:nrow(dfDataToLoad)){
  dfAllData <- rbind(dfAllData,read_excel(sExcelFile, col_names = FALSE, sheet = dfDataToLoad$Sheet[i],  dfDataToLoad$Range[i]))
}
                           
# Rename the column headers
colnames(dfAllData) <- cColHeads
# Add in the remaining meta data for Data type and trace type
dfAllData$DataType <- dfDataToLoad$Description
dfAllData$Trace <- dfDataToLoad$Sheet

# Melt the data so get columns
dfAllDataMelt <- melt(dfAllData, id.vars = c("DataType", "Trace"), measure.vars = cColHeads)


### First Plot: Combined Storage

ggplot(data = dfAllDataMelt %>% filter(DataType == "Combined Storage"), aes(x= variable, y =as.numeric(value), color = Trace, group = Trace, linetype = Trace)) +
  geom_line(size = 2) +
  theme_bw() +
  
  #Scales
  scale_y_continuous(limits = c(10,20), breaks = seq(10,20, by = 2)) +
  #scale_x_continuous(limits = c(0.5, nCols)) +
  scale_color_discrete(breaks = c("Participants","LawOfRiver"), labels=c("Participants", "Law of River")) +
  scale_linetype_manual(values = c("solid", "longdash"), breaks = c("Participants","LawOfRiver"), labels=c("Participants", "Law of River")) +
  
  labs(x="", y="Combined Storage (MAF)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), 
        legend.text=element_text(size=18),
        legend.position= c(0.7,0.80))


### Second Plot: Consumptive use
ggplot(data = dfAllDataMelt %>% filter((DataType == "Consumptive Use-Lower Basin") | (DataType == "Consumptive Use-Upper Basin")) , 
        aes(x= variable, y =as.numeric(value), color = Trace, group = interaction(Trace, DataType), linetype = Trace)) +
  geom_line(size = 2) +
  theme_bw() +
  
  #Scales
  scale_y_continuous(limits = c(0,10), breaks = seq(0,10, by = 2)) +
  #scale_x_continuous(limits = c(0.5, nCols)) +
  scale_color_discrete(breaks = c("Participants","LawOfRiver"), labels=c("Participants", "Law of River")) +
  scale_linetype_manual(values = c("solid", "longdash"), breaks = c("Participants","LawOfRiver"), labels=c("Participants", "Law of River")) +
  
  labs(x="", y="Combined Storage (MAF)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), 
        legend.text=element_text(size=18),
        legend.position= c(0.7,0.80))


