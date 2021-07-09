# PlotLowerBasinAgUsers.r
#
# Use DIT (demand) data from CRSS to plot Water Demands by Lower Basin Users. Three plots:
# 1. Monthly variations
# 2. Annual variations
# 3. Seasonal (Summer/Winter) variations
#
# The main data file is DIT_CRSS_LBshortageEIS_2016UCRC_v1.8 which comes from the January 2021 version of
# the Colorado River Simulation System and is the 2016 Upper Colorado River schedule (for upper basin states)
#
# This is a beginning R-programming effort! There could be lurking bugs or basic coding errors that I am not even aware of.
# Please report bugs/feedback to me (contact info below)
#
# David E. Rosenberg
# April 1, 2021
# Utah State University
# david.rosenberg@usu.edu

rm(list = ls())  #Clear history

# Load required libraies

if (!require(tidyverse)) { 
  install.packages("tidyverse", repos="http://cran.r-project.org") 
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


if (!require(ggrepel)) { 
  devtools::install_github("slowkow/ggrepel")
  library(ggrepel) 
}


if (!require(stringr)) { 
  install.packages("stringr", repo="http://cran.r-project.org")
  library(stringr) 
}

### Define the Months of the Summer
nSummerStart <- 3
nSummerEnd <- 10

###  Read in the DIT File
sExcelFile <- 'DIT_CRSS_LBshortageEIS_2016UCRC_v1.8.xlsm'
dfDemandData <- read_excel(sExcelFile, sheet = "Baseline Monthly Data",  range = "A1:AFV745")

## Pick out the columns we want: CA and AZ irrigators Depletion Schedule
# First pick out the depletion schedule columns
# Get the column names
demandCols <- colnames(dfDemandData)
#Change the first column header to Date
demandCols[1] <- "Date"
colnames(dfDemandData) <- demandCols
#Filter on the depletion schedule columns
dfDepletionData <- dfDemandData[,str_detect(demandCols,".Depletion Schedule")]
#Add the date column
dfDepletionData$Date <- dfDemandData$Date
depleteCols <- colnames(dfDepletionData)

#define the Columns/Districts we want (hard coded)
cCADistricts <- c(233:235,255, 273,281,284,283,286,287,331,338) 
cAZDistricts <- c(258,304:329,338)

dfCAdepletion <- dfDepletionData[,cCADistricts]
dfAZdepletion <- dfDepletionData[,cAZDistricts]

#Melt the data into one data frame
dfCAdepletionMelt <- melt(dfCAdepletion,id = c("Date"))
dfCAdepletionMelt$State <- "CA"
dfAZdepletionMelt <- melt(dfAZdepletion, id = c("Date"))
dfAZdepletionMelt$State <- "AZ"
#Bind the two melted frames
dfAllDepletion <- rbind(dfCAdepletionMelt,dfAZdepletionMelt)

#Cut off the names after :
dfDistName <- str_split(dfAllDepletion$variable, ":", simplify=TRUE)
dfAllDepletion$District <- dfDistName[,1]

#Calculate the month for Summer/Winter calculations
dfAllDepletion$Month <- month(dfAllDepletion$Date)
#Assign a season
dfAllDepletion$Season <- ifelse(dfAllDepletion$Month >= nSummerStart & dfAllDepletion$Month <= nSummerEnd, "Summer","Winter")
dfAllDepletion$SeasonNum <- ifelse(dfAllDepletion$Season == "Summer",nSummerStart,nSummerEnd+1)
#Asign the calendar year
dfAllDepletion$Year <- year(dfAllDepletion$Date)

#Get the unique district names
cCADistrictsName <- unique(dfAllDepletion %>% filter(State == "CA") %>% select(District))
cAZDistrictsName <- unique(dfAllDepletion %>% filter(State == "AZ") %>% select(District))

#Pull in a blue color scheme for the pools
palBlues <- colorRampPalette(brewer.pal(9, "Blues")) #For plotting equalization tiers
palPurples <- brewer.pal(9,"RdPu") 
cPurple <- palPurples[8]
palReds <- brewer.pal(9,"Reds") 
palGreys <- brewer.pal(9,"Greys")
palBlueUse <- palBlues(9)

# Set the fill color based on the District name
#Create a data frame lookup table of colors
dfDistrictColor <- data.frame(District = c(cAZDistrictsName[1:6,],cCADistrictsName[1:9,]),
                              State = c(rep("AZ",6),rep("CA",9)))
#order the districts by name
dfDistrictColor <- dfDistrictColor[order(dfDistrictColor$State,dfDistrictColor$District),]
dfDistrictColor$FillColor <- c(palReds[4:9],palBlueUse[1:9])

#Left join
dfAllDepletion <-left_join(dfAllDepletion,dfDistrictColor, by=c("District" = "District","State" = "State"))


#Calculate an annualized version
dfAllDepletionAnn <- dfAllDepletion %>% group_by(District,State,Year,FillColor) %>% summarise(AnnTotal = sum(value))

#Calculate the Seasonal version
dfAllDepletionSeas <- dfAllDepletion %>% group_by(District,State,Year,Season,SeasonNum,FillColor) %>% summarise(SeasTotal = sum(value))


### Figure 1. Stacked Bar Chart of District CRSS requested depletions Monthly by Year
## One panel for each state. States have seperate color ramps

ggplot() +
  
  geom_bar(data=dfAllDepletion, aes(fill=District,y=value,x=Date),position="stack", stat="identity") +
  #geom_line(data=dfMaxBalance, aes(color="Max Balance", y=MaxBal/1e6,x=Year), size=2) +
  
  #scale_fill_manual(name="Guide1",values = c(palReds[4:9], palBlues(9)), breaks = c(cAZDistrictsName, cCADistrictsName)) +
  scale_fill_manual(values = dfDistrictColor$FillColor, breaks = dfDistrictColor$District, labels = dfDistrictColor$District) +
  
  
   # scale_fill_manual(name="Guide1",values = c(palReds)) +
  #scale_color_manual(name="Guide2", values=c("Black")) +
  
  scale_x_datetime(limits = as.POSIXct(c("2020-1-1","2025-1-1"))) +
  #scale_y_continuous(breaks=seq(0,3,by=1),labels=seq(0,3,by=1), sec.axis = sec_axis(~. +0, name = "", breaks = c(nMaxBalance$Total[2])/1e6, labels = c("Max Balance"))) +
  
  #guides(fill = guide_legend(keywidth = 1, keyheight = 1), color=FALSE) +
  facet_wrap(~State) +
  
  theme_bw() +
  
  labs(x="", y="CRSS Requested Depletion (TAF)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), 
        legend.text=element_text(size=18)) #,
        #legend.position= c(1.075,0.5))


### Figure 2. Stacked Bar Chart of District CRSS requested depletion anual amount by Year
# Same as monthly layout
# Seperate facets and color ramps for each state
#Order the frame by State, District

dfAllDepletionAnn <- dfAllDepletionAnn[order(dfAllDepletionAnn$State,dfAllDepletionAnn$District,dfAllDepletionAnn$Year),]

ggplot() +
  
  geom_bar(data=dfAllDepletionAnn, aes(fill=District,y=AnnTotal,x=Year),position="stack", stat="identity") +
  #geom_line(data=dfMaxBalance, aes(color="Max Balance", y=MaxBal/1e6,x=Year), size=2) +
  
  #scale_fill_manual(name="Guide1",values = c(palBlues(15)), breaks = c(cAZDistricts, cCADistricts), labels = c(cAZDistricts, cCADistricts)) +
  scale_fill_manual(values = dfDistrictColor$FillColor, breaks = dfDistrictColor$District, labels = dfDistrictColor$District) +
  #scale_fill_manual(values = c(palReds[4:9],palBlues(9))) +
  
   #scale_fill_manual(name="Guide1",values = c(palBlues(15))) +
  #scale_color_manual(name="Guide2", values=c("Black")) +
  
  scale_x_continuous(limits = c(2020,2030), breaks = seq(2020,2030, by=2)) +
  #scale_y_continuous(breaks=seq(0,3,by=1),labels=seq(0,3,by=1), sec.axis = sec_axis(~. +0, name = "", breaks = c(nMaxBalance$Total[2])/1e6, labels = c("Max Balance"))) +
  
  #guides(fill = guide_legend(keywidth = 1, keyheight = 1), color=FALSE) +
  facet_wrap(~State) +
  
  theme_bw() +
  
  labs(x="", y="CRSS Requested Depletion (TAF)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), 
        legend.text=element_text(size=18)) #,
#legend.position= c(1.075,0.5))

### Figure 3. Stacked Bar Chart of Districts by season (summer/winter)
# Same as monthly layout
# Seperate color ramps and facets by state

#Order the frame by State, District
dfAllDepletionSeas <- dfAllDepletionSeas[order(dfAllDepletionSeas$State,dfAllDepletionSeas$District,dfAllDepletionSeas$Year),]
#Calculate a seasonal offset for ploting
dfAllDepletionSeas$Offset <- ifelse(dfAllDepletionSeas$Season ==  "Summer", (nSummerEnd - nSummerStart)/2/12, (12-nSummerEnd - 0.5)/12)

ggplot() +
  
  geom_bar(data=dfAllDepletionSeas, aes(fill=District,y=SeasTotal,x=Year+ SeasonNum/12 + Offset , width = 0.4*(nSummerEnd - SeasonNum)/(nSummerEnd-nSummerStart) + 0.3),position="stack", stat="identity") +
  #geom_line(data=dfMaxBalance, aes(color="Max Balance", y=MaxBal/1e6,x=Year), size=2) +
  
  #scale_fill_manual(name="Guide1",values = c(palBlues(15)), breaks = c(cAZDistricts, cCADistricts), labels = c(cAZDistricts, cCADistricts)) +
  scale_fill_manual(values = dfDistrictColor$FillColor, breaks = dfDistrictColor$District, labels = dfDistrictColor$District) +
  #scale_fill_manual(values = c(palReds[4:9],palBlues(9))) +
  
  #scale_fill_manual(name="Guide1",values = c(palBlues(15))) +
  #scale_color_manual(name="Guide2", values=c("Black")) +
  
  scale_x_continuous(limits = c(2020,2030), breaks = seq(2020,2030, by=2)) +
  #scale_y_continuous(breaks=seq(0,3,by=1),labels=seq(0,3,by=1), sec.axis = sec_axis(~. +0, name = "", breaks = c(nMaxBalance$Total[2])/1e6, labels = c("Max Balance"))) +
  
  #guides(fill = guide_legend(keywidth = 1, keyheight = 1), color=FALSE) +
  facet_wrap(~State) +
  
  #Add a text label to define summer
  #annotate("text", label=paste("Summer from Months\n",nSummerStart," to ",nSummerEnd),x=2026,y= 2000, size=7) +
  
  theme_bw() +
  
  labs(x="", y="CRSS Requested Depletion (TAF)", subtitle=paste("Summer from Months ",nSummerStart," to ",nSummerEnd)) +
  theme(text = element_text(size=20),  legend.title = element_blank(), 
        legend.text=element_text(size=18)) #,


