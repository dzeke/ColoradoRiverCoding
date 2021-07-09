# LakePowellElevationTempModelInterogate.r
#
# Identify ranges of Lake Powell water surface elevations associated with release temperature scenarios.
# Plot as a stacked bar graph by month.
# Determine elevations for:
#    - Release from turbines (3490 feet)
#    - Release from river outlets (3370 feet)
#
# The temperature scenarios are:
#     1) 15oC - native warmwater fish continue and possibly thrive -- historical conditions, the world we know
#     2) < 18oC - unknown future for native warmwater fish. Warm water fish may continue to hang on or
#                 they may fall prey to non-native warmwater fish.
#     3) > 18oC - bad for native warmwater fish, they will likely be expatriated from Grand Canyon.
# These scenarios are set with the vector cTempsBreaks
#
# Uses the following data
# A. qryProfiles at Primary Stations.csv - USGS sond data of water temperature profiles going back to 1960s (Vernieu 2015, https://pubs.usgs.gov/ds/471/pdf/ds471.pdf)
#
#         Vernieu, W. S. (2015). "Historical Physical and Chemical Data for Water in Lake Powell and from Glen Canyon Dam Releases, Utah-Arizona, 1964 –2013." Data Series 471, Version 3.0. https://pubs.usgs.gov/ds/471/pdf/ds471.pdf.
#
# B. LAKEPOWELL06-16-2020T16.32.29.csv - USBR daily data of reservoir level/storage/release (https://www.usbr.gov/rsvrWater/HistoricalApp.html)
# C. PowellLevels.xlsx - Definitions of reservoir zones and storage levels (from CRSS/Rosenberg)
# D. GCD_release_water_temp.csv - Hourly values of Powell release temperature. Provided by Bryce M.
# E. FishTemperatureRequirements.xlsx - Fish temperature suitability data from Excel/Valdez et al (2013)
#
# The data wrangling strategy is:
# 1. Load all csv files
# 2. Join Primary Station and Lake Powell Daily data so we have the water level for each day a reading was taken
# 3. Plot temperature suitability for all fish (Figure 1)
# 4. Show the spreadsheet model release temperature output by month (Figure 2)
# 5. Add the observed water surface elevation vs. turbine release temperature data as range of daily min and max (Figure 3)
# 6. Add the translated temperature profile data so go down to water surface elevations at the turbine elevation (below historical data)(Figure 4)
# 7. Calculate range and errors on release temperature for different water surface elevations
# 8. Claculate range and errors on water surface elevation for different release temperature scenarios
# 9. Plot the range of water surface elevations for different release temperature scenarios
#
# David E. Rosenberg
# November 1, 2020
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

if (!require(reshape)) { 
  install.packages("reshape", repos="http://cran.r-project.org") 
  library(reshape) 
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


#if (!require(plyr)) { 
#  install.packages("plyr", repo="http://cran.r-project.org")
#  library(plyr) 
#}

if (!require(ggrepel)) { 
  devtools::install_github("slowkow/ggrepel")
  library(ggrepel) 
}

library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)
library(lubridate)


### 0. Definitions

dMetersToFeet = 3.28
sStation = 'LPCR0024' #Wahweap
sMonth = 'Jun' #Month

# New function interpNA to return NAs for values outside interpolation range (from https://stackoverflow.com/questions/47295879/using-interp1-in-r)
interpNA <- function(x, y, xi = x, ...) {
  yi <- rep(NA, length(xi));
  sel <- which(xi >= range(x)[1] & xi <= range(x)[2]);
  yi[sel] <- interp1(x = x, y = y, xi = xi[sel], ...);
  return(yi);
}


### 1. Read IN the data files

# A. Temperature profile data

sPowellTempProfileFile <- 'qryProfiles at Primary Stations.csv'

# B. Read in the historical Powell data
dfPowellTempProfiles <- read.csv(file=sPowellTempProfileFile, 
                               header=TRUE, 
                               
                               stringsAsFactors=FALSE,
                               sep=",")


# This historical reservoir level data comes from USBR website.

# File name to read in historical Powell Volume from CSV (download from USBR)
#    Water Operations: Historic Data, Upper Colorado River Division, U.S. Buruea of Reclamation
#    https://www.usbr.gov/rsvrWater/HistoricalApp.html

sPowellHistoricalFile <- 'LAKEPOWELL06-16-2020T16.32.29.csv'

# Read in the historical Powell lake level, release, etc. data
dfPowellHistorical <- read.csv(file=sPowellHistoricalFile, 
                               header=TRUE, 
                               
                               stringsAsFactors=FALSE,
                               sep=",")

# C. Read in Lake Powell Release Temperature Data (provided by Bryce M.)
sPowellReleaseTempFile <- 'GCD_release_water_temp.csv'

# Read in the historical Powell data
dfPowellReleaseTemp <- read.csv(file=sPowellReleaseTempFile, 
                               header=TRUE, 
                               
                               stringsAsFactors=FALSE,
                               sep=",")
library(chron)
#Convert just the date
dfPowellReleaseTemp$DateClean <- as.Date(dfPowellReleaseTemp$DateTime, "%m/%d/%Y")
#Convert the time
#dfPowellReleaseTemp$DateTimeClean <- as.POSIXct(dfPowellReleaseTemp$DateTime, format="%m/%d/%Y %H:%M:%S")
dfPowellReleaseTemp$DateTimeClean <- mdy_hms(dfPowellReleaseTemp$DateTime)

###This reservoir data comes from CRSS. It was exported to Excel.

# Read pool level data in from Excel
sExcelFile <- 'PowellZones.xlsx'
sStation <- 'LPCR0024'   #Closest to Dam

# Read in the Powell reservoir zones
dfPowellZones <- read_excel(sExcelFile)


# D. Read in the Elevation-Temperature model
sExcelFileModel <- 'TemperatureModel_GrandCanyonStorage.xlsx'

dfTempElevationModel <- read_excel(sExcelFileModel)

#Define the elevation temperature model by month
TempModel <- function(Month,Elevation) {
  #Month = 1, 2, ..., 12 for January, February, ..., December
  #Elevation in feet
  
  Temperature <- switch(Month,
      5.36+(3.815525648*exp(-(-0.004664035)*((Elevation/3.28084)-1127.76))), #January
      5.667857143+(2.64291514*exp(-(-0.002277994)*((Elevation/3.28084)-1127.76))),  #Feb
      7.343478261+(0.866777569*exp(-(0.009667425)*((Elevation/3.28084)-1127.76))),  #March
      6.759259259+(1.734071491*exp(-(0.007769259)*((Elevation/3.28084)-1127.76))),  #April
      7.112903226+(1.473399599*exp(-(0.018251341)*((Elevation/3.28084)-1127.76))),  #May
      8.095238095+(1.097430498*exp(-(0.031219207)*((Elevation/3.28084)-1127.76))),  #June
      8.115384615+(1.106900875*exp(-(0.044112483)*((Elevation/3.28084)-1127.76))),  #July
      7.910714286+(1.252536876*exp(-(0.044297389)*((Elevation/3.28084)-1127.76))),  #August
      7.788461538+(1.509123384*exp(-(0.040706994)*((Elevation/3.28084)-1127.76))),  #Sept
      7.876923077+(1.5738892*exp(-(0.035494644)*((Elevation/3.28084)-1127.76))),    #Oct
      7.594444444+(1.880906664*exp(-(0.025102979)*((Elevation/3.28084)-1127.76))),  #Nov
      7.587096774+(1.978022304*exp(-(0.011288015)*((Elevation/3.28084)-1127.76))))  #Dec
      
  return(Temperature)
}
  

#Check on TempModel function
for (i in seq(1,12,by=1)){
  print(paste0("Month ", i, ", Calc Temp: ", TempModel(i,as.numeric(dfTempElevationModel[4,i+1])), ", Actual: ", dfTempElevationModel[5,i+1], ", Difference: ",TempModel(i,as.numeric(dfTempElevationModel[4,i+1])) - as.numeric(dfTempElevationModel[5,i+1])))
}

#Calculate Temperatures by model over reservoir elevation range for each month

cElevationsExt <- c(3300,3700)

dfTempElevationModelCalc <- data.frame(Month = 0, Elevation = 0, Temperature = 0)
for(Mon in seq(1,12, by=1)) {
  for(Elev in seq(cElevationsExt[1],cElevationsExt[2], by=5)) {
    dfTempElevationModelCalc <- rbind(dfTempElevationModelCalc,
                                      data.frame(Month = Mon,Elevation = Elev,
                                                 Temperature = TempModel(Mon,Elev)))
   }
}

#Remove the First row of zeros
dfTempElevationModelCalc <- dfTempElevationModelCalc[2:nrow(dfTempElevationModelCalc),]


### E. Load in the fish temperature suitability data from Excel/Valdez et al (2013)

sTempSuitFile <- 'FishTemperatureRequirements.xlsx'

dfFishTempSuit <- read_excel(sTempSuitFile, sheet = 2, col_names=TRUE)
dfMinDegreeDays <- read_excel(sTempSuitFile, sheet = 3, col_names=TRUE)
#Read updated fish-temperature suitability data by Dibble et al
dfFishTempSuitDibble <- read_excel(sTempSuitFile, sheet = 4, col_names=TRUE)

# Melt to move life stage into a new category
dfFishTempSuitMelt <- melt(dfFishTempSuit, id.vars= c("Common Name", "Group", "GroupDescript", "Code", "Keystone"))
#Split variable into species life stage and measurement
lTemp <- (as.data.frame(matrix(unlist(str_split(dfFishTempSuitMelt$variable, pattern="-")),ncol=2,byrow=TRUE)))
colnames(lTemp) <- c("LifeStage","Var")
lTemp$Row <- 1:nrow(lTemp)
dfFishTempSuitMelt$Row <- 1:nrow(dfFishTempSuitMelt)
# Join the split strings back in
dfFishTempSuitMelt <- inner_join(dfFishTempSuitMelt,lTemp,by = c("Row" = "Row"))
# Cast to separate out vars
dfFishTempSuitPlot <- dcast(dfFishTempSuitMelt, `Common Name` + GroupDescript + LifeStage + Keystone ~ Var)

dfFishTempSuitPlot$LifeStage <- as.character(dfFishTempSuitPlot$LifeStage)
#Reorder by the gouping in the plot => Temp group, Keystone, Common Name
dfFishTempSuitPlot <- dfFishTempSuitPlot[order(dfFishTempSuitPlot$GroupDescript,-dfFishTempSuitPlot$Keystone,dfFishTempSuitPlot$`Common Name`),]
dfFishTempSuitPlot$Xplot <- paste(dfFishTempSuitPlot$GroupDescript, 1 - dfFishTempSuitPlot$Keystone,dfFishTempSuitPlot$`Common Name`,sep="-")
cNames <- dfFishTempSuitPlot %>% filter(LifeStage == "Growth") %>% select(`Common Name`)
cgNames <- dfFishTempSuitPlot %>% filter(LifeStage == "Growth") %>% select(Xplot)

# plot the suitability data

ggplot(dfFishTempSuitPlot) +
  #Min-max range
  geom_errorbar(aes(x = Xplot, ymin = Min., ymax = Max., color=GroupDescript, size = Keystone)) +
  #Optimal as point
  #geom_point(aes(x=Xplot,y=Opt., color=GroupDescript),size=4) +
  
  facet_wrap( ~ LifeStage) +
  
  scale_color_manual(values = c("blue","red","pink")) +
  # scale_x_discrete(labels = dfFishTempSuitPlot %>% filter(LifeStage == "Growth") %>% select(`Common Name`)) +
  scale_size_continuous(range = c(1,2), breaks = c(0,1), labels = c("Study", "Keystone")) +
  
  scale_x_discrete(breaks = cgNames$Xplot, labels = cNames$`Common Name`) +
  
  labs(x="Fish Species (common name)", y="River Temperature (oC)") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank(), axis.text.x = element_text(angle = 90, size=10, hjust=0.95,vjust=0.2))

ggsave("SpeciesTempNeeds.png", width=9, height = 6.5, units="in")


# Plot all life stages on top of eahc other
ggplot(dfFishTempSuitPlot) +
  #Min-max range
  geom_errorbar(aes(x = Xplot, ymin = Min., ymax = Max., color=GroupDescript, size = Keystone)) +
  #Optimal as point
  #geom_point(aes(x=Xplot,y=Opt., color=GroupDescript),size=4) +
  
  #facet_wrap( ~ LifeStage) +
  
  scale_color_manual(values = c("blue","red","pink")) +
  # scale_x_discrete(labels = dfFishTempSuitPlot %>% filter(LifeStage == "Growth") %>% select(`Common Name`)) +
  scale_size_continuous(range = c(1,2), breaks = c(0,1), labels = c("Study", "Keystone")) +
  
  scale_x_discrete(breaks = cgNames$Xplot, labels = cNames$`Common Name`) +
  
  labs(x="Fish Species (common name)", y="River Temperature (oC)") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank(), axis.text.x = element_text(angle = 90, size=14, hjust=0.95,vjust=0.2))

ggsave("SpeciesTempNeedsCombined.png", width=9, height = 6.5, units="in")


### Plot Fish spicies temperature data with updated Dibble data

# Organzie the data to plot by group and fish species
dfFishTempSuitDibblePlot <- dfFishTempSuitDibble[order(dfFishTempSuitDibble$GroupDescript,dfFishTempSuitDibble$`Common Name`),]
dfFishTempSuitDibblePlot$Xplot <- paste(dfFishTempSuitDibblePlot$GroupDescript, dfFishTempSuitDibblePlot$`Common Name`,sep="-")
cNamesDibble <- dfFishTempSuitDibblePlot %>% select(`Common Name`)
cgNamesDibble <- dfFishTempSuitDibblePlot %>% select(Xplot)


ggplot(dfFishTempSuitDibblePlot) +
  #Min-max range
  geom_errorbar(aes(x = Xplot, ymin = Minimum, ymax = Maximum, color=GroupDescript), size=2) +
  geom_errorbar(aes(x = Xplot, ymin = `Minimum Optimal`, ymax = `Maximum Optimal`, color=GroupDescript), size=2) +
  #Optimal as point
  #geom_point(aes(x=Xplot,y=Opt., color=GroupDescript),size=4) +
  
  scale_color_manual(values = c("red","pink")) +
  # scale_x_discrete(labels = dfFishTempSuitPlot %>% filter(LifeStage == "Growth") %>% select(`Common Name`)) +
  scale_x_discrete(breaks = cgNamesDibble$Xplot, labels = cNamesDibble$`Common Name`) +
  scale_y_continuous(limits = c(10,40)) +
  
  labs(x="Fish Species (common name)", y="River Temperature (oC)") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank(), axis.text.x = element_text(angle = 90, size=14, hjust=0.95,vjust=0.2))

ggsave("SpeciesTempNeedsDibble.png", width=7, height = 6.5, units="in")




###### 2. Plot Release temperature data vs time

## Calculate daily min, max, average, range
dfPowellReleaseTempSum <- dfPowellReleaseTemp %>% group_by(DateClean) %>% summarize(minDay = min(WaterTemp_C),
                                                                                    maxDay = max(WaterTemp_C),
                                                                                    avgDay = mean(WaterTemp_C),
                                                                                    rangeDay = max(WaterTemp_C) - min(WaterTemp_C))


#Pull out Year, Month, Month as abbr, Day for plotting
dfPowellReleaseTempSum$Year <- year(dfPowellReleaseTempSum$DateClean)
dfPowellReleaseTempSum$Month <- month(dfPowellReleaseTempSum$DateClean)
dfPowellReleaseTempSum$MonthTxt <- format(dfPowellReleaseTempSum$DateClean, "%b")
dfPowellReleaseTempSum$Day <- day(dfPowellReleaseTempSum$DateClean)
dfPowellReleaseTempSum$WaterYear <- ifelse(dfPowellReleaseTempSum$Month >= 10,dfPowellReleaseTempSum$Year, dfPowellReleaseTempSum$Year - 1 )
dfPowellReleaseTempSum$DayOfYear <- yday(dfPowellReleaseTempSum$DateClean)

dfDaysPerYear <- dfPowellReleaseTempSum %>% group_by(Year) %>% summarize(numDays = n())
dfDaysPerMonthYear <- dfPowellReleaseTempSum %>% group_by(Year,Month) %>% summarize(numDays = n())

palBlues <- brewer.pal(9, "Blues")
palReds <- brewer.pal(9, "Reds")

palBlueFunc <- colorRampPalette(c(palBlues[3],palBlues[9]))


### 3. Join the Profile and Historical dataframes on the date

# Convert to date format
dfPowellHistorical$dDateTemp <- as.Date(dfPowellHistorical$Date, "%d-%b-%y")
dfPowellTempProfiles$dDate <- as.Date(dfPowellTempProfiles$Date, "%m/%d/%Y")

#Apparently R breaks the century at an odd place
#Coerce the years above 2050 (really 1950 to 1968) to be in prior century (substract 12*100 months)
dfPowellHistorical$Year <- as.numeric(format(dfPowellHistorical$dDateTemp,"%Y"))
dfPowellHistorical$dDate <- dfPowellHistorical$dDateTemp
dfPowellHistorical$dDate <- as.Date(ifelse((dfPowellHistorical$Year >= 2050),
                                           as.character(dfPowellHistorical$dDateTemp %m-% months(12*100)),as.character(dfPowellHistorical$dDateTemp)))
dfPowellHistorical$Year <- as.numeric(format(dfPowellHistorical$dDate,"%Y"))
dfPowellHistorical$Month <- (format(dfPowellHistorical$dDate,"%b"))

### 3. Left join the two dataframes so have an elevation/storage for each temperature profile value
dfPowellTempLevels <- left_join(dfPowellTempProfiles,dfPowellHistorical,by = c("dDate" = "dDate"))

### 4. Calculate an elevation for each measurement
dfPowellTempLevels$Elevation..feet. <- as.numeric(dfPowellTempLevels$Elevation..feet.)
dfPowellTempLevels$MeasLevel <- (dfPowellTempLevels$Elevation..feet.) - dMetersToFeet*dfPowellTempLevels$Depth
dfPowellTempLevels$MonNum <- as.numeric((format(dfPowellTempLevels$dDate,"%m")))

### 5. Filter on station and month

dfPowellTempLevelsPlot <- dfPowellTempLevels %>% filter(Station.ID == sStation)
# Tally Depths per day and Days per month
#dfPowellTempDays <- dcast(dfPowellTempLevelsPlot, Year ~ MonNum, value.var = "MonNum", na.rm = TRUE)

#dfPowellTempLevelsPerDay <- dfPowellTempLevelsPlot %>% group_by(Year,MonNum,dDate) %>% tally()
dfPowellTempLevelsPerDay <- dfPowellTempLevelsPlot %>% group_by(Year,MonNum,dDate) %>% dplyr::summarize(NumLevels = n(), MinTemp=min(T),MaxTemp=max(T))

dfPowellTempLevelsPerDay <- dfPowellTempLevelsPlot %>% group_by(Year,MonNum,dDate, Elevation..feet.) %>% dplyr::summarize(NumLevels = n(), MinTemp=min(T),MaxTemp=max(T), Level3525Temp = interp1(xi=3525, y=T, x=MeasLevel, method="linear" ))
dfPowellTempLevelsPerDay$Zone <- 3525


# Days per month
dfPowellTempDays <- dfPowellTempLevelsPerDay %>% group_by(Year,MonNum) %>% tally()

dfPowellTempDays <- dcast(dfPowellTempDays, Year ~ MonNum, value.var = "n", na.rm = FALSE)
dfPowellTempDays[is.na(dfPowellTempDays)] <- 0 
print("Number of measurements per month")
dfMonthSums <- colSums(dfPowellTempDays[,2:13],dim=1)

dfPlot <- dfPowellTempLevelsPlot

minTemp <- min(dfPlot$T)
maxTemp <- max(dfPlot$T)


#Subsett the columns
cZonesToShow <- c("Top of Dam", "Live Capacity", "Upper Eq. Tier (2019)", "Rated Power", "Upper Basin target", "Minimum Power (from Object)", "Can't release 7.5 maf/year", "Dead Pool (river outlets)")
dfPowellZones$level_feet <- dfPowellZones$`level (feet)`
dfPowellZones$Zone <- dfPowellZones$variable
dfPowellZonesShort <- as.data.frame(dfPowellZones %>% select(Zone, level_feet, stor_maf ) %>% filter (Zone %in% cZonesToShow) %>% arrange(-level_feet))

#Create the y-axis tick label from the level and variable
dfPowellZonesShort$rightlabel <- paste(round(dfPowellZonesShort$stor_maf,1),'-',dfPowellZonesShort$Zone)

dfPowellZonesShort$BeginTemp <- minTemp
dfPowellZonesShort$EndTemp <- maxTemp

dfPowellZonesShortMelt <- melt(dfPowellZonesShort[,c("Zone","level_feet", "BeginTemp","EndTemp")], id = c("Zone","level_feet"))

dfPowellZonesShortMelt <- dfPowellZonesShortMelt %>% arrange(-level_feet,Zone)


library(ggrepel)


### Plot Release temperature vs. lake surface elevation for full daily data set (very messy)

dfPowellReleaseElev <- left_join(dfPowellReleaseTempSum,dfPowellHistorical,by = c("DateClean" = "dDate"))
#Convert to numric
dfPowellReleaseElev$WaterSurface <- as.numeric(dfPowellReleaseElev$Elevation..feet.)
#Calculate Water Year
dfPowellReleaseElev$WaterYear <- ifelse(dfPowellReleaseElev$Month.x >= 10, dfPowellReleaseElev$Year.x,dfPowellReleaseElev$Year.x - 1)

#Classify each year as lake level increasing, decreasing, or steady within a given margin
nMargin <- 5 #feet
nTempMargin <- 1.5 # oC
#Pull the first and last weater level measurements for each year
dfPowellLevelChange <- rbind(dfPowellReleaseElev %>% filter(Month.x == 1,Day==1),
                             dfPowellReleaseElev %>% filter(Month.x == 12,Day==31))
dfPowellTempChange <- dcast(dfPowellLevelChange,Year.y~Month.y , mean, value.var = "avgDay")
dfPowellLevelChange <- dcast(dfPowellLevelChange,Year.y~Month.y , mean, value.var = c("WaterSurface"))#,"avgDay"))
#Classify water level changes for each year
dfPowellLevelChange$LevelYearType <- ifelse(dfPowellLevelChange$Dec - dfPowellLevelChange$Jan > nMargin,"Rise",ifelse(dfPowellLevelChange$Dec - dfPowellLevelChange$Jan < -nMargin,"Fall","Steady"))
dfPowellTempChange$TempYearType <- ifelse(dfPowellTempChange$Dec - dfPowellTempChange$Jan > nTempMargin,"Rise",ifelse(dfPowellTempChange$Dec - dfPowellTempChange$Jan < -nTempMargin,"Fall","Steady"))
#Join the two
dfPowellLevelChange <- left_join(dfPowellLevelChange,dfPowellTempChange,by=c("Year.y" = "Year.y"))
#Join the classification back to main data frame
dfPowellReleaseElev <- left_join(dfPowellReleaseElev,dfPowellLevelChange[,c(1,4,7)], by=c("Year.y" = "Year.y"))
#Reorder the factor levels
dfPowellReleaseElev <- transform(dfPowellReleaseElev, LevelYearType = factor(LevelYearType,c("Fall","Steady","Rise")))
dfPowellReleaseElev <- transform(dfPowellReleaseElev, TempYearType = factor(TempYearType,c("Fall","Steady","Rise")))

dfTempElevationModelCalc$Month.x <- dfTempElevationModelCalc$Month

#Remove highest elevation (top of dam)
dfPowellZonesMinusTop <- dfPowellZonesShort %>% filter(level_feet <= 3700)


# For the temperature profiles, reposition elevation so 0 foot measurement depth is at the penstock intakes
# 10 foot measurement depth is 10 feet above penstock intakes, etc.
# So assume the water surface is always depth feet above the penstock
dfPowellTempLevelsPlot$ElevAvbPenstock <- dfPowellZonesMinusTop[5,2] + dMetersToFeet*dfPowellTempLevelsPlot$Depth
# For temperature profiles, reposition elevation so 0 foot measurement depth is at the river outlets (dead pool)
dfPowellTempLevelsPlot$ElevAbvDeadPool <- dfPowellZonesMinusTop[7,2] + dMetersToFeet*dfPowellTempLevelsPlot$Depth
#Add a Month.x field to allow faceting
dfPowellTempLevelsPlot$Month.x <- dfPowellTempLevelsPlot$MonNum

#Adjust Wahweap release to turbine release. Below <11oC the same. But starting
#above 11oC Wahweap the Turbine release is 0.5 to 2 degrees lower
dfWahweapToTurbineAdjust <- data.frame(WahweapTemp = c(10,11,12,13,15), TurbineTemp = c(10,10.5,11.5,12,13))
dfWahweapToTurbineAdjust$TempDifference <- dfWahweapToTurbineAdjust$WahweapTemp - dfWahweapToTurbineAdjust$TurbineTemp

dfPowellTempLevelsPlot$TurbRelease <- dfPowellTempLevelsPlot$T - 
                                        ifelse(dfPowellTempLevelsPlot$T < 11,0,
                                          ifelse(dfPowellTempLevelsPlot$T < 13, 0.5, 
                                            ifelse(dfPowellTempLevelsPlot$T < 15, 1, 2)))



# Water Surface Elevation vs Release Temperature by Month
# Plot all monthly regression models on one plot

ggplot(data=dfTempElevationModelCalc %>% filter(Elevation > dfPowellZonesShort[6,2] - 10)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Points represent transformed temperature profile reading. For a specific depth below the water surface,
  #we calculate the elevation that would put the depth at the turbine elevation
  #geom_point(data = dfPowellTempLevelsPlot %>% filter(Depth*dMetersToFeet <= 3600 - dfPowellZonesShort[6,2]), aes(y = ElevAvbPenstock, x = T, shape ="Wahweap temperature\nat turbine elev."), color = "Red", size=0.75) +
  #Error bar on release data - color by water surface
  #geom_errorbar(aes(y=WaterSurface, xmin= minDay, xmax=maxDay, color = Year.x), size=1) +
  geom_line(aes(x=Temperature, y=Elevation, color = Month.x, group = Month.x), size=1.25) +
  
  scale_color_continuous(low=palBlues[4],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  #scale_linetype_manual(values = c("solid")) +
  #scale_shape_manual(values = c("circle")) +
  
  labs(y="Water Surface Elevation (feet)", x="Turbine Release Temperature (oC)", color="Month", linetype="") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Turbine Release Temperature (oC)", color="") +
  
  #facet_wrap(~Month.x) +
  scale_y_continuous(limits = cElevationsExt, breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  xlim(7,30) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16)) + #,

  #Label the bottom of each trace with the Month number
  #Most months plot directly under
  geom_text(data=dfTempElevationModelCalc %>% filter(Elevation == 3480, Month.x %in% c(2,3,4,5,6,11,10,7)), aes(x=Temperature, y = Elevation - 5, label = Month.x), color = "Black", size = 5) +
  #These months below
  geom_text(data=dfTempElevationModelCalc %>% filter(Elevation == 3480, Month.x %in% c(1,12)) , aes(x=Temperature, y = Elevation - 15, label = Month.x), color = "Black", size = 5) +
  #Months 8 and 9 at right
  geom_text(data=dfTempElevationModelCalc %>% filter(Elevation == 3490, Month.x %in% c(8,9)), aes(x=30 - 0.75*(9-Month.x), y = Elevation + 10*(9 - Month.x), label = Month.x), color = "Black", size = 5)


ggsave("ElevationReleaseTempModelMonth.png", width=9, height = 6.5, units="in")


#Water Surface Elevation vs Release Temperature by Month
#with Monthly regression model overlaid

#NEED to add legend for regression fits and points above surface

ggplot(data=dfPowellReleaseElev %>% filter(Day %in% seq(1,31, by=1)) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  geom_errorbar(aes(y=WaterSurface, xmin= minDay, xmax=maxDay, color = Year.x), size=1) +
  geom_line(data = dfTempElevationModelCalc, aes(x=Temperature, y=Elevation, linetype="Spreadsheet model"), color = "Black", size=1.25) +
  
  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  scale_linetype_manual(values = c("solid")) +
  
  labs(y="Water Surface Elevation (feet)", x="Turbine Release Temperature (oC)", color="Observed (Year)", linetype="") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  facet_wrap(~Month.x) +
  scale_y_continuous(limits = c(3370,3700), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  xlim(7,30) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseElevationMonth.png", width=9, height = 6.5, units="in")


#Water Surface Elevation vs Release Temperature by Month
# with Monthly regression model overlaid and release temperature inferred from depth profiles
# if water surface is at specified elevation and release is from penstocks

ggplot(data=dfPowellReleaseElev %>% filter(Day %in% seq(1,31, by=1)) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Points represent transformed temperature profile reading. For a specific depth below the water surface,
  #we calculate the elevation that would put the depth at the turbine elevation
  #geom_point(data = dfPowellTempLevelsPlot %>% filter(Depth*dMetersToFeet <= 3600 - dfPowellZonesShort[6,2]), aes(y = ElevAvbPenstock, x = T, shape ="Wahweap temperature profile:\nshifted so water surface is\ndepth feet above turbine elev."), color = "Red", size=0.75) +
  #Version with Wahweap-Turbine release temperature correction
  geom_point(data = dfPowellTempLevelsPlot %>% filter(Depth*dMetersToFeet <= 3600 - dfPowellZonesShort[6,2]), aes(y = ElevAvbPenstock, x = TurbRelease, shape ="Wahweap temperature profile:\nshifted so water surface is\ndepth feet above turbine elev."), color = "Red", size=0.75) +
  
   
    #Error bar on release data - color by water surface
  geom_errorbar(aes(y=WaterSurface, xmin= minDay, xmax=maxDay, color = Year.x), size=1) +
  geom_line(data = dfTempElevationModelCalc %>% filter(Elevation > dfPowellZonesShort[6,2] - 10), aes(x=Temperature, y=Elevation, linetype="Spreadsheet model"), color = "Black", size=1.25) +
  
  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  scale_linetype_manual(values = c("solid")) +
  scale_shape_manual(values = c("circle")) +
  
  labs(y="Water Surface Elevation (feet)", x="Turbine Release Temperature (oC)", color="Observed release (Year)", linetype="", shape="") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Turbine Release Temperature (oC)", color="") +
  
  facet_wrap(~Month.x) +
  scale_y_continuous(limits = c(3370,3700), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  xlim(7,30) +
  
  #Vertical line at temperature breaks
  #geom_vline(xintercept=c(15,18)) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16)) #,
        #legend.key = element_blank())

ggsave("CompareReleaseWahweapElevationMonth.png", width=9, height = 6.5, units="in")


#### Calculate range of temperature release for a specified Powell water surface elevation
#### Use the observed and water profile data sets
#### Clip the data to elevations above the specified water surface elevation. Then find the min and max temperature
#### Do for each month

FindTempRangeForElevation <- function(dfObserved, dfProfile, cElevations) {
  #Find the range of release temperature for between each specified elevation range in cElevations.
  #Use both observed and profile data sets
  #Searches the data in the Elevation range {cElevation[i], to cElevation[i-1]}
  #cElevations are ascending
  
  #Test values
  #cElevations <- seq(3560,3565,by=5)
  #dfObserved <- dfPowellReleaseElev
  #dfProfile <- dfPowellTempLevelsPlot
  #i <- 1

  cElevationDiff <- diff(cElevations)
  #Duplicate the last value
  cElevationDiff <- c(cElevationDiff,cElevationDiff[length(cElevationDiff)])
  
    
  #Find temperature range for each data set
  for (i in (1:length(cElevations))) {
    
    Elevation <- cElevations[i]
    ElevationTolerance <- cElevationDiff[i] 
    
    paste(i, Elevation, ElevationTolerance)
    
    dfRangeObs <- dfObserved %>% filter(WaterSurface >= Elevation, WaterSurface <= Elevation+ElevationTolerance) %>% group_by(Month.x) %>% summarize(SurfaceElevation = Elevation, minTemp = min(minDay), maxTemp = max(maxDay))  
    dfRangeProfile <- dfProfile %>%  filter(ElevAvbPenstock >= Elevation, ElevAvbPenstock <= Elevation + ElevationTolerance) %>% group_by(Month.x) %>% summarize(SurfaceElevation = Elevation, minTemp = min(TurbRelease), maxTemp = max(TurbRelease))
    
    #Combine (bind) the datasets
    dfRangeComb <- rbind(dfRangeObs,dfRangeProfile)
    #Find the range from the values
    dfRangeCurrElev <- dfRangeComb %>% group_by(Month.x,SurfaceElevation) %>% summarize(minTemp = min(minTemp), maxTemp = max(maxTemp))
    
    #Store results for elevation
    if (i==1) { # new dataframe
      dfRange <- dfRangeCurrElev
    } else { #Combine with results for prior elevations
      dfRange <- rbind(dfRange, dfRangeCurrElev)
    }
    
    }
  
  #Calculate the temperature range
  dfRange$Range <- dfRange$maxTemp - dfRange$minTemp
  
  return(dfRange)
}

## Function to find the elevation range for a specified temperature using the Observed and Profile data

FindElevationRangeForTemperature <- function(dfObserved, dfProfile, cTemps, TempTolerance) {
  #Find the range of reservoir water surface elevations for specified temperatures in cTemps within TempTolerance of the specified temperature.
  #Use both observed and profile data sets
  #Searches the data in the Temperature range {cTemps[i], to cTemps[i] + TempTolerance}
  #cTemps are ascending
  
  #Test values
  # cTemps <- 15
  # dfObserved <- dfPowellReleaseElev
  # dfProfile <- dfPowellTempLevelsPlot
  # TempTolerance <- 0.5
  # i <- 1
  
  #Find water surface elevation range for each temperature criteria
  for (i in (1:length(cTemps))) {
    
    Temperature <- cTemps[i]
    
    
    paste(i, Temperature, TempTolerance)
    
    dfRangeObs <- dfObserved %>% filter(minDay >= Temperature, minDay <= Temperature + TempTolerance) %>% group_by(Month.x) %>% summarize(Temperature = Temperature, minElevation = min(WaterSurface), maxElevation = max(WaterSurface))  
    dfRangeProfile <- dfProfile %>%  filter(TurbRelease >= Temperature, TurbRelease <= Temperature + TempTolerance) %>% group_by(Month.x) %>% summarize(Temperature = Temperature, minElevation = min(ElevAvbPenstock), maxElevation = max(ElevAvbPenstock))
    
    #Combine (bind) the datasets
    dfRangeComb <- rbind(dfRangeObs,dfRangeProfile)
    #Find the range from the values
    dfRangeCurrTemp <- dfRangeComb %>% group_by(Month.x,Temperature) %>% summarize(minElevation = min(minElevation), maxElevation = max(maxElevation))
    
    #Add values for missing months. At and above turbine elevation, temperature will be value
    cMonthsMiss <- which(!(seq(1,12,by=1) %in% dfRangeCurrTemp$Month.x))
    dfMissMonths <- data.frame(Month.x = cMonthsMiss, Temperature = Temperature, minElevation = 3490, maxElevation = 3490)

    #Bind to range datafram
    dfRangeCurrTemp <- rbind(as.data.frame(dfRangeCurrTemp), dfMissMonths)
    
    
    
    #Store results for elevation
    if (i==1) { # new dataframe
      dfRange <- dfRangeCurrTemp
    } else { #Combine with results for prior elevations
      dfRange <- rbind(dfRange, dfRangeCurrTemp)
    }
    
  }
  
  #Calculate the temperature range
  dfRange$Range <- dfRange$maxElevation - dfRange$minElevation
  
  #Order the data frame by months
  dfRange <- dfRange[order(dfRange$Month.x, dfRange$Temperature),]
  
  return(dfRange)
}

#cTempsBreak <- c(15,18)
#New category < 12oC
cTempsBreak <- c(12,15,18)

dfTest <- FindTempRangeForElevation(dfPowellReleaseElev,dfPowellTempLevelsPlot, seq(3490,3690,by=5))
dfTestElev <- FindElevationRangeForTemperature(dfPowellReleaseElev,dfPowellTempLevelsPlot, cTempsBreak, 1.0)


#Water Surface Elevation vs Release Temperature by Month
# with Monthly regression model overlaid and release temperature inferred from depth profiles
# if water surface is at specified elevation and release is from penstocks
# Show ranges of elevation at specified temperature in red

ggplot(data=dfPowellReleaseElev %>% filter(Day %in% seq(1,31, by=1)) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Points represent transformed temperature profile reading. For a specific depth below the water surface,
  #we calculate the elevation that would put the depth at the turbine elevation
  # Temp range for specified elevation
  geom_errorbar(data=dfTest, aes(y=SurfaceElevation, xmin= minTemp, xmax=maxTemp, color = Range), size=1) +
  
  #geom_point(data = dfPowellTempLevelsPlot %>% filter(Depth*dMetersToFeet <= 3600 - dfPowellZonesShort[6,2]), aes(y = ElevAvbPenstock, x = T, shape ="Wahweap temperature profile:\nshifted so water surface is\ndepth feet above turbine elev."), color = "Red", size=0.75) +
  
  #Error bar on release data - color by water surface
  geom_errorbar(aes(y=WaterSurface, xmin= minDay, xmax=maxDay), color = "Blue", size=1) +
  geom_point(data = dfPowellTempLevelsPlot %>% filter(Depth*dMetersToFeet <= 3600 - dfPowellZonesShort[6,2]), aes(y = ElevAvbPenstock, x = T, shape ="Wahweap temperature\nat turbine elev."), color = "Purple", size=0.75) +
  
  #Spreadsheet model
  geom_line(data = dfTempElevationModelCalc %>% filter(Elevation > dfPowellZonesShort[6,2] - 10), aes(x=Temperature, y=Elevation, linetype="Spreadsheet model"), color = "Black", size=1.25) +
  
  #Range of elevation for specified water temperature
  geom_errorbar(data=dfTestElev %>% filter(Range > 0, Range < 210), aes(x=Temperature, ymin= minElevation, ymax=maxElevation), color="red", size=1) +
  
  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  scale_linetype_manual(values = c("solid")) +
  scale_shape_manual(values = c("circle")) +
  
  labs(y="Water Surface Elevation (feet)", x="Turbine Release Temperature (oC)", color="Temperature Range (oC)", linetype="", shape="") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Turbine Release Temperature (oC)", color="") +
  
  facet_wrap(~Month.x) +
  scale_y_continuous(limits = c(3370,3700), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  xlim(7,30) +
  
  #Vertical line at temperature breaks
  #geom_vline(xintercept=c(15,18)) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16)) #,
#legend.key = element_blank())


#Plot elevation ranges at specified temperature by month

# ggplot(data=dfTestElev) +
#  
#   #Range of elevation for specified water temperature
#   geom_errorbar(aes(x=Month.x, ymin= minElevation, ymax=maxElevation, color=as.factor(Temperature)), size=2, width=0.5) +
#   #geom_ribbon(aes(x=Month.x, ymin= minElevation, ymax=maxElevation, fill=as.factor(Temperature))) +
#   
#   #scale_fill_manual(values = c("blue","red")) +
#   scale_color_manual(values = c("blue","red")) +
# 
#   labs(y="Water Surface Elevation (feet)", x="Month", color="Turbine Release\nTemperature (oC)", linetype="", shape="") +
#   #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Turbine Release Temperature (oC)", color="") +
#   
#   scale_y_continuous(limits = c(3370,3700), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
#   scale_x_continuous(limits = c(1,12), breaks = seq(1,12,by=1)) +
#   
#   #Vertical line at temperature breaks
#   #geom_vline(xintercept=c(15,18)) +
#   
#   theme(text = element_text(size=18), legend.text=element_text(size=16)) #,
# 
# ggsave("ElevationRangesForTempTargetsErrorBars.png", width=9, height = 6.5, units="in")


# Try in stacked bar
# Reformat the data for a stacked bar from bottom up. First entry is dummy to Turbine elevation

#cCategories <- c("< 15", "< 18","> 18","Base")
cCategories <- c("< 12", "< 15", "< 18","> 18","Base")

# Order the data frame so can get the minimum elevation at the next warmest temperature
dfTestElev <- dfTestElev[order(dfTestElev$Month.x, dfTestElev$Temperature),]
dfTestElev$maxElevNextT <- dplyr::lag(dfTestElev$maxElevation)

# Filter for elevation values for each temperature block

dfTestElevBar <- (data.frame(Month.x = seq(1,12,by=1), TempCategory = "Base" , ElevationAdd = 3490)) # Base entry
dfTestElevBar2 <- as.data.frame(dfTestElev %>% filter(Temperature == cTempsBreak[3]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[4], ElevationAdd = ifelse(minElevation > 3490, minElevation, 3490) - 3490) %>% select(Month.x, TempCategory, ElevationAdd))
dfTestElevBar3 <- as.data.frame(dfTestElev %>% filter(Temperature == cTempsBreak[3]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[3], ElevationAdd = maxElevNextT - minElevation) %>% select(Month.x, TempCategory, ElevationAdd))
dfTestElevBar4 <- as.data.frame(dfTestElev %>% filter(Temperature == cTempsBreak[2]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[2], ElevationAdd = maxElevNextT - maxElevation) %>% select(Month.x, TempCategory, ElevationAdd))
dfTestElevBar5 <- as.data.frame(dfTestElev %>% filter(Temperature == cTempsBreak[1]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[1], ElevationAdd = 3700 - maxElevation) %>% select(Month.x, TempCategory, ElevationAdd))


dfTestElevBar <- as.data.frame(rbind(dfTestElevBar, dfTestElevBar2, dfTestElevBar3, dfTestElevBar4, dfTestElevBar5))

#Set transparency field. Base is zero. Everything else is one.
dfTestElevBar$Alpha <- ifelse(dfTestElevBar$TempCategory == cCategories[5],0,1)


#Order the bars
#dfTestElevBar$Month.x <- factor(dfTestElevBar$Month.x, levels = seq(1,12,by=1))
dfTestElevBar$TempCategory <- factor(dfTestElevBar$TempCategory, levels = cCategories )
dfTestElevBar <- dfTestElevBar[order(dfTestElevBar$Month.x, dfTestElevBar$TempCategory),]

ggplot(data=dfTestElevBar) +  #[order(dfTestElevBar$TempCategory, decreasing = T),]
  
  #Range of elevation for specified water temperature
  geom_bar(aes(x=Month.x, y=ElevationAdd, fill=TempCategory, group = TempCategory, alpha = Alpha), stat = "identity") +
  #geom_ribbon(aes(x=Month.x, ymin= minElevation, ymax=maxElevation, fill=as.factor(Temperature))) +
  
  scale_fill_manual(values = c(palBlues[5], "blue", "pink","red","white"), breaks = cCategories[1:4], labels = cCategories[1:4]) +
  #scale_color_manual(values = c("blue","red")) +
  
  labs(y="Water Surface Elevation (feet)", x="Month", fill="Turbine Release\nTemperature (oC)", alpha = "", linetype="", shape="") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Turbine Release Temperature (oC)", color="") +
  coord_cartesian(ylim = c(3370,3700)) +
  scale_y_continuous(breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  scale_x_continuous(limits = c(0.5,12.5), breaks = seq(1,12,by=1)) +
  scale_alpha(guide = 'none') +
  
  #Vertical line at temperature breaks
  #geom_vline(xintercept=c(15,18)) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16)) #,

ggsave("ElevationRangesForTempTargets-Turbine.png", width=9, height = 6.5, units="in")

#Sum by group to check bar stacking
dfTestElevBar %>% group_by(Month.x) %>% summarize(TotElev = sum(ElevationAdd))

#Elevation threshold for temperatures near Dead pool elevation
nElevThresh <- 5

#### Calculations for range of water surface elevations if release from River Outlets (Dead pool)
####
####

# Plot water surface elevation vs. Wahweap temperature at Outlets.
# Use the observed profile data and transformed profile data.
# Transformed moves the water surface down so that we are depth feet above the river outlet
ggplot() +
  # Transformed temperature - move water surface to depth feet above river outlets 
  geom_point(data = dfPowellTempLevelsPlot %>% filter(ElevAbvDeadPool <= 3600), aes(y = ElevAbvDeadPool, x = T, shape ="Transformed", color = "Transformed"), size=0.75) +
  #Observed water surface and Wahweap river outlet temperature
  geom_point(data = dfPowellTempLevelsPlot %>% filter(MeasLevel >= dfPowellZonesShort[8,2], MeasLevel <= dfPowellZonesShort[8,2] + nElevThresh), aes(y = Elevation..feet., x = T, shape ="Observed", color = "Observed"), size=0.75) +

 # geom_point(data = dfPowellTempLevelsPlot %>% filter(Depth*dMetersToFeet <= 3600 - dfPowellZonesShort[6,2]), aes(y = ElevAvbPenstock, x = T, shape ="Wahweap temperature\nat turbine elev."), color = "Purple", size=0.75) +
  
  scale_color_manual(values = c("Blue","Red")) +
  scale_shape_manual(values = c("circle","square")) +
  
  labs(y="Water Surface Elevation (feet)", x="Wahweap Temperature at 3,370 feet (oC)", color="Data Source", shape="Data Source") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Turbine Release Temperature (oC)", color="") +
  
  facet_wrap(~Month.x) +
  scale_y_continuous(limits = c(3370,3700), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  xlim(7,30) +
  
  #Vertical line at temperature breaks
  #geom_vline(xintercept=c(15,18)) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16)) #,

ggsave("WaterSurfaceVsReleaseTempRiverOutlets.png", width=9, height = 6.5, units="in")

## Function to find the elevation range for a specified temperature using the Profile data

FindElevationRangeForTemperatureRiverOutlet <- function(dfProfile, cTemps, TempTolerance) {
  #Find the range of reservoir water surface elevations for specified temperatures in cTemps within TempTolerance of the specified temperature.
  #This is temperature at Wahweap at the River outlet elevation
  #Use the profile data sets
  #Searches the data in the Temperature range {cTemps[i], to cTemps[i] + TempTolerance}
  #cTemps are ascending
  
  #Test values
   # cTemps <- cTempsBreak
   # dfProfile <- dfPowellTempLevelsPlot
   # TempTolerance <- 1
   # i <- 1
  
  #Find water surface elevation range for each temperature criteria
  for (i in (1:length(cTemps))) {
    
    Temperature <- cTemps[i]
    
    
    paste(i, Temperature, TempTolerance)
    
    dfRangeProfile <- dfProfile %>%  filter(T >= Temperature, T <= Temperature + TempTolerance) %>% group_by(Month.x) %>% summarize(Temperature = Temperature, minElevation = min(ElevAbvDeadPool), maxElevation = max(ElevAbvDeadPool))
    
     #Add values for missing months. At and above turbine elevation, temperature will be value
    cMonthsMiss <- which(!(seq(1,12,by=1) %in% dfRangeProfile$Month.x))
    dfMissMonths <- data.frame(Month.x = cMonthsMiss, Temperature = Temperature, minElevation = 3370, maxElevation = 3370)
    
    #Bind to range datafram
    dfRangeProfile <- rbind(as.data.frame(dfRangeProfile), dfMissMonths)

    #Store results for elevation
    if (i==1) { # new dataframe
      dfRange <- dfRangeProfile
    } else { #Combine with results for prior elevations
      dfRange <- rbind(dfRange, dfRangeProfile)
    }
    
  }
  
  #Calculate the temperature range
  dfRange$Range <- dfRange$maxElevation - dfRange$minElevation
  
  #Order the data frame by months
  dfRange <- dfRange[order(dfRange$Month.x, dfRange$Temperature),]
  
  return(dfRange)
}


#Calculate the water surface elevation ranges for temperature when releasing water from the river outlets (Dead Pool)
dfTestDeadPoolElev <- FindElevationRangeForTemperatureRiverOutlet(dfPowellTempLevelsPlot, cTempsBreak, 1.0)

#Manipulate the Data frame so to plot as as stacked bar graph. We need a new variable that
#is the elevation difference between adjacent temperature scenarios. This is the elevation to stack
# Order the data frame so can get the minimum elevation at the next warmest temperature
dfTestDeadPoolElev <- dfTestDeadPoolElev[order(dfTestDeadPoolElev$Month.x, dfTestDeadPoolElev$Temperature),]
dfTestDeadPoolElev$maxElevNextT <- dplyr::lag(dfTestDeadPoolElev$maxElevation)

# Filter for elevation values for each temperature block
dfTestElevDeadPoolBar <- (data.frame(Month.x = seq(1,12,by=1), TempCategory = "Base" , ElevationAdd = 3370)) # Base entry
dfTestElevDeadPoolBar2 <- as.data.frame(dfTestDeadPoolElev %>% filter(Temperature == cTempsBreak[3]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[4], ElevationAdd = ifelse(minElevation > 3370, minElevation, 3370) - 3370) %>% select(Month.x, TempCategory, ElevationAdd))
dfTestElevDeadPoolBar3 <- as.data.frame(dfTestDeadPoolElev %>% filter(Temperature == cTempsBreak[3]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[3], ElevationAdd = maxElevNextT - minElevation) %>% select(Month.x, TempCategory, ElevationAdd))
dfTestElevDeadPoolBar4 <- as.data.frame(dfTestDeadPoolElev %>% filter(Temperature == cTempsBreak[2]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[2], ElevationAdd = maxElevNextT - maxElevation) %>% select(Month.x, TempCategory, ElevationAdd))
dfTestElevDeadPoolBar5 <- as.data.frame(dfTestDeadPoolElev %>% filter(Temperature == cTempsBreak[1]) %>% mutate(Month.x = Month.x, TempCategory = cCategories[1], ElevationAdd = 3700 - maxElevation) %>% select(Month.x, TempCategory, ElevationAdd))


dfTestElevDeadPoolBar <- as.data.frame(rbind(dfTestElevDeadPoolBar, dfTestElevDeadPoolBar2, dfTestElevDeadPoolBar3, dfTestElevDeadPoolBar4, dfTestElevDeadPoolBar5))

#Set transparency field. Base is zero. Everything else is one.
dfTestElevDeadPoolBar$Alpha <- ifelse(dfTestElevDeadPoolBar$TempCategory == cCategories[5],0,1)


#Order the bars
#dfTestElevBar$Month.x <- factor(dfTestElevBar$Month.x, levels = seq(1,12,by=1))
dfTestElevDeadPoolBar$TempCategory <- factor(dfTestElevDeadPoolBar$TempCategory, levels = cCategories )
dfTestElevDeadPoolBar <- dfTestElevDeadPoolBar[order(dfTestElevDeadPoolBar$Month.x, dfTestElevDeadPoolBar$TempCategory),]

ggplot(data=dfTestElevDeadPoolBar) +  #[order(dfTestElevBar$TempCategory, decreasing = T),]
  
  #Range of elevation for specified water temperature
  geom_bar(aes(x=Month.x, y=ElevationAdd, fill=TempCategory, group = TempCategory, alpha = Alpha), stat = "identity") +
  #geom_ribbon(aes(x=Month.x, ymin= minElevation, ymax=maxElevation, fill=as.factor(Temperature))) +
  
  scale_fill_manual(values = c(palBlues[5], "blue", "pink","red","white"), breaks = cCategories[1:4], labels = cCategories[1:4]) +
  #scale_color_manual(values = c("blue","red")) +
  
  labs(y="Water Surface Elevation (feet)", x="Month", fill="Wahweep Temperature (oC)\nat Dead Pool Elev.", alpha = "", linetype="", shape="") +
  coord_cartesian(ylim = c(3370,3700)) +
  scale_y_continuous(breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesMinusTop$level_feet, labels = dfPowellZonesMinusTop$rightlabel )) +
  scale_x_continuous(limits = c(0.5,12.5), breaks = seq(1,12,by=1)) +
  scale_alpha(guide = 'none') +

  theme(text = element_text(size=18), legend.text=element_text(size=16)) #,

ggsave("ElevationRangesForTempTargets-RiverOutlets.png", width=9, height = 6.5, units="in")

