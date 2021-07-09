# LakePowellTempScenarios.r
#
# Creates scenarios of Lake Powell Water Temperature-Depth.
#  - Use the scenarios to see the variation in water temperatures at a specified depth (such as the Turbine intake) for different water surface levels
#  - Also the reverse: scenarios of water levels for different temperatures at depth.
# Also
#  - explore Powell temperature release data and compare to profile temperatures at Wahweap at 3,490 feet (minimum power pool) 
#
# Uses the following data:
# 1. qryProfiles at Primary Stations.csv - USGS sond data of water temperature profiles going back to 1960s (Vernieu 2015, https://pubs.usgs.gov/ds/471/pdf/ds471.pdf)
#
#         Vernieu, W. S. (2015). "Historical Physical and Chemical Data for Water in Lake Powell and from Glen Canyon Dam Releases, Utah-Arizona, 1964 –2013." Data Series 471, Version 3.0. https://pubs.usgs.gov/ds/471/pdf/ds471.pdf.
#
# 2. LAKEPOWELL06-16-2020T16.32.29.csv - USBR daily data of reservoir level/storage/release (https://www.usbr.gov/rsvrWater/HistoricalApp.html)
# 3. PowellLevels.xlsx - Definitions of reservoir zones and storage levels (from CRSS/Rosenberg)
# 4. GCD_release_water_temp.csv - Hourly values of Powell release temperature. Provided by Bryce M.
#
# The basis data wrangling strategy is:
# 1. Load csv files
# 2. Join Primary Station and Lake Powell Daily data so we have the water level for each day a reading was taken
# 3. Substract depth from water level to get a level (elevation) for each reading.
#
# David E. Rosenberg
# June 19, 2020
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

# Temperature profile data

sPowellTempProfileFile <- 'qryProfiles at Primary Stations.csv'

# Read in the historical Powell data
dfPowellTempProfiles <- read.csv(file=sPowellTempProfileFile, 
                               header=TRUE, 
                               
                               stringsAsFactors=FALSE,
                               sep=",")


# This historical reservoir level data comes from USBR website.

# File name to read in historical Powell Volume from CSV (download from USBR)
#    Water Operations: Historic Data, Upper Colorado River Division, U.S. Buruea of Reclamation
#    https://www.usbr.gov/rsvrWater/HistoricalApp.html

sPowellHistoricalFile <- 'LAKEPOWELL06-16-2020T16.32.29.csv'

# Read in the historical Powell data
dfPowellHistorical <- read.csv(file=sPowellHistoricalFile, 
                               header=TRUE, 
                               
                               stringsAsFactors=FALSE,
                               sep=",")

# Read in Lake Powell Release Temperature Data (provided by Bryce M.)
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

# Read in the historical Mead data
dfPowellZones <- read_excel(sExcelFile)


# Load in the fish temperature suitability data from Excel/Valdez et al (2013)

sTempSuitFile <- 'FishTemperatureRequirements.xlsx'

dfFishTempSuit <- read_excel(sTempSuitFile, sheet = 2, col_names=TRUE)
dfMinDegreeDays <- read_excel(sTempSuitFile, sheet = 3, col_names=TRUE)

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

## Plot histograms of the daily range for each month

ggplot(dfPowellReleaseTempSum, aes(x=rangeDay)) +
  geom_histogram(color="darkmagenta", fill="magenta", binwidth = 0.2) +
  
  #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
  #scale_y_continuous(breaks = seq(0,11,by=2)) +
  
  facet_wrap(~ MonthTxt) +
  
  labs(x="Daily Range of Powell Release Temperature (oC)", y="Frequency\n(number of days)") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())

ggsave("PowellReleaseTempRangeByMonth.png", width=9, height = 6.5, units="in")


## Plot cumulative distribution of the daily range for each month

pPlot <- ggplot(dfPowellReleaseTempSum, aes(rangeDay, group=Month, color=MonthTxt)) +
  stat_ecdf(geom = "step") +
  
  #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
  #scale_y_continuous(breaks = seq(0,11,by=2)) +
  scale_color_manual(values = palBlueFunc(12)) +
  xlim(0,2) +
  
  #facet_wrap( ~ Year ) +
  
  labs(x="Daily Range of Powell Release Temperature (oC)", y="Cumulative Frequency\n(number of days)", color = "Month") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())

direct.label(pPlot, "angled.boxes" )

ggsave("PowellReleaseTempRangeByMonthCDF.png", width=9, height = 6.5, units="in")


## Plot cumulative distribution of the daily range for each year

pPlot <- ggplot(dfPowellReleaseTempSum %>% filter(WaterYear < 2018), aes(rangeDay, group=WaterYear, color=WaterYear)) +
  stat_ecdf(geom = "step") +
  
  #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
  #scale_y_continuous(breaks = seq(0,11,by=2)) +
  scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Water Year") +
  
  xlim(0,2) +
  
  #facet_wrap( ~ Month ) +
  
  labs(x="Daily Range of Powell Release Temperature (oC)", y="Cumulative Frequency\n(number of days)", color = "Water Year") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())

direct.label(pPlot, "angled.boxes" )

ggsave("PowellReleaseTempRangeByYearCDF.png", width=9, height = 6.5, units="in")


## Plot cumulative distribution of the daily range for each month and year

ggplot(dfPowellReleaseTempSum %>% filter(Year > 1988), aes(rangeDay, group=WaterYear, color=WaterYear)) +
  stat_ecdf(geom = "step") +
  
  xlim(0,2) +
  
  facet_wrap( ~ Month ) +
  
  scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Year") +
  
  
  labs(x="Daily Range of Powell Release Temperature (oC)", y="Cumulative Frequency\n(number of days)", color = "Year") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())


ggsave("PowellReleaseTempRangeByMonthYearCDF.png", width=9, height = 6.5, units="in")

## Load and plot CO river at Cisco as an example of natural temperature hydrograph
# Read in Lake Powell Release Temperature Data (provided by Bryce M.)
sCOCiscoFile <- 'ColoradoRiverCisco.xlsx'

# Read in the historical Cisco data
dfCisco <- read_excel(sCOCiscoFile, col_names=FALSE, range = "A33969:H39061")
#Rename the columns
colnames(dfCisco) <- c("Org", "Gage", "Date", "Flow(cfs)", "Accuracy", "Mean Temperature (oC)", "Max Temperature (oC)",	"Min Temperature (oC)")

#Convert to date
dfCisco$Date <- as.Date(dfCisco$Date)
dfCisco$Year <- year(dfCisco$Date)
dfCisco$DayOfYear <- yday(dfCisco$Date)
dfCisco$TempRange <- dfCisco$`Max Temperature (oC)` - dfCisco$`Min Temperature (oC)`

#Plot
ggplot(dfCisco %>% filter(`Mean Temperature (oC)` < 100, Year==2018), aes(x = DayOfYear, y= `Mean Temperature (oC)`, group=Year, color=Year)) +
  geom_line() +
  
  # scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Year") +
  
  
  labs(x="Julian Day", y="Avg. Daily Temperature at Cisco (oC)", color = "Year") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())






## Plot average daily temperature by day of year. Color different years

ggplot(dfPowellReleaseTempSum, aes(x = DayOfYear, y= avgDay, group=Year), color="Red") +
  geom_line() +
  
  #Overplot temperature at Cisco in thick black
  geom_line(data = dfCisco %>% filter(`Mean Temperature (oC)`< 100), aes(x = DayOfYear, y= `Mean Temperature (oC)`, group="Year"), color="Blue")) +
  
  #Add fish temperature threshold
  geom_hline(yintercept=14, color="black", size=2, linestyle="longdash") + 
  scale_color_manual(values = c("Red","Black","Blue", breaks=c("Cisco","Powell Release","Fish Threshold"))) +
 # scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Year") +
  
  
  labs(x="Julian Day", y="Water Temperature (oC)", color = "Location") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())


ggsave("CiscoReleaseFishThreshold.png", width=9, height = 6.5, units="in")





## Plot histograms of the daily range for each year

# ggplot(dfPowellReleaseTempSum, aes(x=rangeDay)) +
#   geom_histogram(color="darkmagenta", fill="magenta", binwidth = 0.2) +
#   
#   #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
#   #scale_y_continuous(breaks = seq(0,11,by=2)) +
#   
#   facet_wrap(~ Year) +
#   
#   labs(x="Daily Range of Powell Release Temperature (oC)", y="Frequency\n(number of days)") +
#   theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
#         legend.key = element_blank())
# 
# ggsave("PowellReleaseTempRangeByYear.png", width=9, height = 6.5, units="in")
# 
# # Try facets of months (rows) and years (columns)
# 
# ggplot(dfPowellReleaseTempSum, aes(x=rangeDay)) +
#   geom_histogram(color="darkmagenta", fill="magenta", binwidth = 0.2) +
#   
#   #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
#   #scale_y_continuous(breaks = seq(0,11,by=2)) +
#   
#   facet_grid(Month ~ Year) +
#   
#   labs(x="Daily Range of Powell Release Temperature (oC)", y="Frequency\n(number of days)") +
#   theme(text = element_text(size=16), legend.title=element_blank(), legend.text=element_text(size=14),
#         legend.key = element_blank())
# 
# ggsave("PowellReleaseTempRangeByMonthYear.png", width=9, height = 6.5, units="in")

## Plot the range of temperature by day
# ggplot(dfPowellReleaseTempSum %>% filter(Year > 2006)) +
#   geom_line(aes(x=Day,y=avgDay), color="black") +
#   #Error bar
#   geom_errorbar(aes(x=Day,ymin= minDay, ymax=maxDay), color="black") +
#   
#   
#   scale_x_continuous(breaks = c(1,31)) +
#   scale_y_continuous(breaks = c(8,16)) +
#   
#   facet_grid(Year ~ Month) +
#   
#   labs(x="Day", y="Release Temperature (oC)") +
#   theme(text = element_text(size=12), legend.title=element_blank(), legend.text=element_text(size=10),
#         legend.key = element_blank())

#ggsave("PowellReleaseTempErrorByMonthYear.png", width=9, height = 6.5, units="in")



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

### Filter on station and month
dfPowellTempLevelsPlot <- dfPowellTempLevels %>% filter(Station.ID == sStation, Month == sMonth)

paste0("Station: ", sStation, ", Month: ", sMonth)
paste0("Number of observations = ", dfMonthSums[dfPowellTempLevelsPlot$MonNum[1]])

# Assign each starting lake elevation for a profile to a class to plot as the same color
cLakeElevationClasses <- c(3710,3655,3570,3525) 

dfPowellTempLevelsPlot$ElevationClass <- cLakeElevationClasses[1]
for (lev in cLakeElevationClasses) {
  dfPowellTempLevelsPlot$ElevationClass <- ifelse(dfPowellTempLevelsPlot$Elevation..feet. <= lev,lev,dfPowellTempLevelsPlot$ElevationClass)
  
}

dfPowellTempLevelsPlot$fElevationClass <- as.factor(dfPowellTempLevelsPlot$ElevationClass)

#Prepare the zone data to add as horizontal lines on the plot
#Grab the min/max temperatures

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




#Plot up the depth readings

#dfPlot <- dfPowellTempLevelsPlot %>% filter(dDate==as.Date("1995-06-06"))



## Determine the Min/Max watertemperature at each specified Elevation


dfTempAtDepth <- data.frame(MonNum=0,ElevationClass = 0, elevation=0,minTemp=0,maxTemp=0,rangeTemp=0)

#Loop over the elevations in the zone dataframe
for (elev in dfPowellZonesShort$level_feet) {
  
  #elev <- dfPowellZonesShort$level_feet[1]
  print(elev)
  
  #Interpolate for each date group
  dfCurrLevel <- dfPlot %>% group_by(MonNum, ElevationClass, dDate) %>% summarize(IntTemp = interpNA(xi=elev, x=MeasLevel, y=T,method="linear"))
  
  #Add to the dataframe
  dfCurrLevelGroup <- dfCurrLevel %>% group_by(ElevationClass, MonNum) %>% summarize(minTemp=min(IntTemp),maxTemp=max(IntTemp))
  #nminTemp <- min(na.omit(dfTempAtDepth$IntTemp))
  # <- max(na.omit(dfTempAtDepth$IntTemp))
  dfCurrLevelGroup$rangeTemp <- dfCurrLevelGroup$maxTemp - dfCurrLevelGroup$minTemp
  dfCurrLevelGroup$elevation <- elev
  #dfCurrLevelGroup$ElevationClass <- as.factor(dfCurrLevelGroup$ElevationClass)
  
  dfTempAtDepth <- rbind(dfTempAtDepth,as.data.frame(dfCurrLevelGroup))
}

#Remove first record
dfTempAtDepth <- dfTempAtDepth[2:nrow(dfTempAtDepth),]
#Remove records with NAs
dfTempAtDepth <- na.omit(dfTempAtDepth)




# Plot water temperature vs elevation. Color as continuous
ggplot() +
  #Temperature profiles
  geom_line(data=dfPlot, aes(x = T,y = MeasLevel, color = Elevation..feet., group = dDate), size=1.5) +
  #Powell zones
  geom_line(data=dfPowellZonesShortMelt, aes(x = value, y = level_feet, group = Zone), size=1, color="purple", linetype = "longdash") +
  
  scale_x_continuous(trans= "reverse") + 
  scale_y_continuous(limits = c(3300,3715), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesShort$level_feet, labels = dfPowellZonesShort$rightlabel)) +
  
  #Continuous color scale by elevation
  scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  #Color breaked by zone
  #scale_color_manual(breaks = c(3710,3650,3670,3525),values=c(palBlues[9],palBlues[7],palBlues[5],palBlues[3])) +
  
 
  theme_bw() +
  #coord_fixed() +
  labs(x="Temperature (oC)", y="Elevation (feet)", color="Start Elevation\n(feet)") +
  theme(text = element_text(size=18), legend.text=element_text(size=16))
  
  
ggsave("PowellTempProfileCont.png", width=9, height = 6.5, units="in")



# Plot water temperature vs elevation. Color as class
ggplot() +
  #Temperature profiles
  geom_line(data=dfPlot, aes(x = T,y = MeasLevel, color = fElevationClass, group = dDate), size=1.5) +
  #Powell zones
  geom_line(data=dfPowellZonesShortMelt, aes(x = value, y = level_feet, group = Zone), size=1, color="purple", linetype = "longdash") +
  
  #Interpolated values
  #geom_point(data=dfPowellTempLevelsPerDay, aes(x=Level3525Temp,y=Zone)) + 
  
  scale_x_continuous(trans= "reverse") + 
  scale_y_continuous(limits = c(3300,3715), breaks = seq(3250,3711, by=50),labels=seq(3250,3711, by=50),  sec.axis = sec_axis(~. +0, name = "Active Storage\n(million acre-feet)", breaks = dfPowellZonesShort$level_feet, labels = dfPowellZonesShort$rightlabel)) +
  
  #Continuous color scale by elevation
  #scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  #Color breaked by zone
  scale_color_manual(breaks = cLakeElevationClasses,values=c(palBlues[9],palBlues[7],palBlues[5],palBlues[3])) +
  
  
  theme_bw() +
  #coord_fixed() +
  labs(x="Temperature (oC)", y="Elevation (feet)", color="Start Elevation\n(feet)") +
  theme(text = element_text(size=18), legend.text=element_text(size=14))

ggsave("PowellTempProfile.png", width=9, height = 6.5, units="in")



### 4. Compare the Release Temperature to Profile Temperature on all days when they overlap

# First interpolate temperatures at the specified elevations such as the turbine intake
# This is a guess as to what elevations are good

cIntakeElevRange <- c(dfPowellZonesShort$level_feet[6], 3550) # feet

dfTempAtDepth <- data.frame(dDate=as.Date("1900-01-01"), WaterSurface = 0, elevation=0,IntTemp = 0)

#Loop over the elevations in the zone dataframe
for (elev in cIntakeElevRange ) {
  
  #elev = cIntakeElevRange[1]
  
  #elev <- dfPowellZonesShort$level_feet[1]
  print(elev)
  
  #Interpolate for each date group
  dfCurrLevel <- dfPowellTempLevels %>% filter(Station.ID == sStation) %>% group_by(dDate) %>% summarize(IntTemp = interpNA(xi=elev, x=MeasLevel, y=T, method="linear"), WaterSurface = max(Elevation..feet.))
  
  #Add to the dataframe
  #nminTemp <- min(na.omit(dfTempAtDepth$IntTemp))
  # <- max(na.omit(dfTempAtDepth$IntTemp))
  dfCurrLevel$elevation <- elev
  #dfCurrLevelGroup$ElevationClass <- as.factor(dfCurrLevelGroup$ElevationClass)
  
  dfTempAtDepth <- rbind(dfTempAtDepth,as.data.frame(dfCurrLevel))
}

#Remove first record
dfTempAtDepth <- dfTempAtDepth[2:nrow(dfTempAtDepth),]
#Remove records with NAs
dfTempAtDepth <- na.omit(dfTempAtDepth)

#Add day and numeric Month
#dfTempAtDepth$dDate <- as.Date(dfTempAtDepth$dDate)
dfTempAtDepth$Month <- month(dfTempAtDepth$dDate)
dfTempAtDepth$Day <- day(dfTempAtDepth$dDate)



## Plot the range of temperature by day
# ggplot() +
#   #geom_line(aes(x=Day,y=avgDay), color="black") +
#   #Error bar on release data
#   geom_errorbar(data = dfPowellReleaseTempSum, aes(x=Day,ymin= minDay, ymax=maxDay), color="black") +
#   #Error bar on profile data
#   geom_errorbar(data = dfTempAtDepth %>% filter(elevation == cIntakeElevRange[1]), aes(x=Day, ymin = IntTemp, ymax = IntTemp), color="red") +
#   
#   
#   scale_x_continuous(breaks = c(1,31)) +
#   scale_y_continuous(breaks = c(8,16)) +
#   
#   facet_grid(Month ~ Year) +
#   
#   labs(x="Day", y="Temperature (oC)") +
#   theme(text = element_text(size=12), legend.title=element_blank(), legend.text=element_text(size=10),
#         legend.key = element_blank())

# ggsave("CompareReleaseWaweapRange.png", width=9, height = 6.5, units="in")

## More explicitly compare on a bi-plot
## x-Axis = Temperature at WahWeap @ 3,490 ft (oC)", y-Axis = "Release Temperature (oC)"

# Join the Water profile and release temperature data

library(ggrepel)

dfTempCompare <- inner_join(dfPowellReleaseTempSum, dfTempAtDepth,by = c("DateClean" = "dDate"))

ggplot(data=dfTempCompare %>% filter(elevation == cIntakeElevRange[1]) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  geom_errorbar(aes(x=IntTemp, ymin= minDay, ymax=maxDay, color=WaterSurface), size=1.5) +
  #Error bar on release data - color by Year
  #geom_errorbar(aes(x=IntTemp, ymin= minDay, ymax=maxDay, color=Year), size=1) +
  #A line to connect the centroids
  #geom_path(aes(x=IntTemp, y= (minDay + maxDay)/2), color="grey50") +
  #Label the 1:1 line
  geom_text(aes(x=12,y=12.5,label="1:1 line"), angle=45, color="red") +
  
  #Label the error bar outliers > 14.3oC
  #Above 13.5oC label goes above bar
  geom_text_repel(data=dfTempCompare %>% filter(IntTemp > 14.3, maxDay > 13.5, elevation == cIntakeElevRange[1]) %>% distinct(),
                  aes(x=IntTemp, y=maxDay, label=as.character(DateClean)), nudge_y=0.1, vjust=0, direction="x",angle = 90 , segment.color = "grey50" ) +
  #Below 13.5oC label goes below bar
  geom_text_repel(data=dfTempCompare %>% filter(IntTemp > 14.3, maxDay <= 13.5, elevation == cIntakeElevRange[1]) %>% distinct(),
                  aes(x=IntTemp, y=minDay, label=as.character(DateClean)), nudge_y=-0.1, vjust=1, direction="x",angle = 90 , segment.color = "grey50" ) +
  
  
  
  
  #1:1 line
  geom_abline(intercept = 0, slope = 1, color="red", linetype = "longdash", size = 1.5) + 
  coord_fixed(ratio=1) + 
  
  scale_x_continuous(breaks = seq(8,26, by=2)) +
  #scale_y_continuous(breaks = c(8,16)) +
  
  #facet_grid(Month ~ Year) +
  
  scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", limits=c(3550,3700)) +
  
  
  labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="Water Surface (feet)") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseWaweap.png", width=9, height = 6.5, units="in")

### Plot Release temperature vs. lake surface elevation for dates where lake depth was sampled

ggplot(data=dfTempCompare %>% filter(elevation == cIntakeElevRange[1]) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  geom_errorbar(aes(x=WaterSurface, ymin= minDay, ymax=maxDay, color = Month.x), size=1.5) +
  #Error bar on release data - color by Year
  #geom_errorbar(aes(x=IntTemp, ymin= minDay, ymax=maxDay, color=Year), size=1) +
  #A line to connect the centroids
  #geom_path(aes(x=IntTemp, y= (minDay + maxDay)/2), color="grey50") +
  #Label the 1:1 line
  #geom_text(aes(x=12,y=12.5,label="1:1 line"), angle=45, color="red") +
  
  #Label the error bar outliers > 14.3oC
  #Above 13.5oC label goes above bar
  #geom_text_repel(data=dfTempCompare %>% filter(IntTemp > 14.3, maxDay > 13.5, elevation == cIntakeElevRange[1]) %>% distinct(),
   #               aes(x=IntTemp, y=maxDay, label=as.character(DateClean)), nudge_y=0.1, vjust=0, direction="x",angle = 90 , segment.color = "grey50" ) +
  #Below 13.5oC label goes below bar
  #geom_text_repel(data=dfTempCompare %>% filter(IntTemp > 14.3, maxDay <= 13.5, elevation == cIntakeElevRange[1]) %>% distinct(),
   #               aes(x=IntTemp, y=minDay, label=as.character(DateClean)), nudge_y=-0.1, vjust=1, direction="x",angle = 90 , segment.color = "grey50" ) +
  

  #1:1 line
  #geom_abline(intercept = 0, slope = 1, color="red", linetype = "longdash", size = 1.5) + 
  #coord_fixed(ratio=1) + 
  
  #scale_x_continuous(breaks = seq(8,26, by=2)) +
  #scale_y_continuous(breaks = c(8,16)) +
  
  #facet_grid(Month ~ Year) +
  
  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  
  labs(x="Water Surface Elevation (feet)", y="Release Temperature (oC)", color="Month") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseTempWaterSurfaceWahweap.png", width=9, height = 6.5, units="in")



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

#Find the indices of the dates with min and max temperature and water surface
dfMinMax <- dfPowellReleaseElev %>% group_by(Year.x) %>% 
                summarize(DateMinTemp = which.min(avgDay), DateMaxTemp = which.max(avgDay),
                          DateMinLevel = which.min(WaterSurface), DateMaxLevel = which.max(WaterSurface))




### Plot Release temperature vs. lake surface elevation for all dates (Very messy)

ggplot(data=dfPowellReleaseElev %>% filter(Month.x %in% seq(4,10, by=1),Day %in% seq(1,31, by=1)) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  geom_errorbar(aes(x=WaterSurface, ymin= minDay, ymax=maxDay, color = Month.x), size=1) +

  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  labs(x="Water Surface Elevation (feet)", y="Release Temperature (oC)", color="Month") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseElevation.png", width=9, height = 6.5, units="in")


#Water Surface Elevation vs Release Temperature by Month

ggplot(data=dfPowellReleaseElev %>% filter(Day %in% seq(1,31, by=1)) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  geom_errorbar(aes(y=WaterSurface, xmin= minDay, xmax=maxDay, color = Year.x), size=1) +
  
  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  labs(y="Water Surface Elevation (feet)", x="Release Temperature (oC)", color="Year") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  facet_wrap(~Month.x) +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseElevationMonth.png", width=9, height = 6.5, units="in")



#Water Surface Elevation vs Release Temeprature by years for July to Dec

ggplot(data=dfPowellReleaseElev %>% filter(Month.x %in% seq(6,12, by=1),Day %in% seq(1,31, by=2)) %>% arrange(DateClean)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  geom_errorbar(aes(x=WaterSurface, ymin= minDay, ymax=maxDay, color = as.factor(Year.x)), size=1) +
  geom_text_repel(data = dfPowellReleaseElev %>% filter(Month.x == 6, Day == 1), aes(x=WaterSurface,y=minDay, label=Year.x)) +
  
  #scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  labs(x="Water Surface Elevation (feet)", y="Release Temperature (oC)", color="Month") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())




# Pull out min and max temps and water surface elevations for each year

dfPowellReleaseElevMaxes <- dfPowellReleaseElev %>% group_by(Year.x) %>% 
          summarize(minElev = min(WaterSurface), maxElev = max(WaterSurface), minTemp = min(avgDay), maxTemp =max(avgDay),
                    minElevInd = which.min(WaterSurface),
                    maxElevInd = which.max(WaterSurface))

#Join in the yearly changes
dfPowellReleaseElevMaxes <- inner_join(dfPowellReleaseElevMaxes,dfPowellLevelChange, by = c("Year.x" = "Year.y"))

### Plot Year-Max Release temperature vs. Year-max water surface elevation. Color by water level change for the year

ggplot(data=dfPowellReleaseElevMaxes) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  #geom_errorbar(aes(x=(minElev), ymin= minTemp, ymax=maxTemp), size=1) +
  geom_point(aes(x=(maxElev), y=maxTemp, color=maxElev-minElev), size=5) +
  #(aes(y=maxTemp, xmin= minElev, xmax=maxElev), size=1, color="black") +
  
  geom_text(x=3662,y=15.75,label=lm_eqn(dfPowellReleaseElevMaxes %>% filter(maxElev < 3650), 'maxTemp','maxElev'),color='red',parse=T, size=6) +
  geom_smooth(data=dfPowellReleaseElevMaxes %>% filter(maxElev < 3650), aes(x=maxElev,y=maxTemp), method='lm') +
  
  geom_text_repel(aes(y=(maxTemp), x=maxElev, label = Year.x), size=5) +
  
  scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  labs(x="Max Water Surface Elevation for Year (feet)", y="Max Release Temperature (oC)", color="Water Level Range\nfor Year (feet)") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseElevation.png", width=9, height = 6.5, units="in")

#Helper function to plot equation, r2, and significance on plot 
# See @Ramnath at https://stackoverflow.com/questions/7549694/add-regression-line-equation-and-r2-on-graph

lm_eqn <- function(df, y, x){
  formula = as.formula(sprintf('%s ~ %s', y, x))
  m <- lm(formula, data=df);
  # formating the values into a summary string to print out
  # ~ give some space, but equal size and comma need to be quoted
  eq <- substitute(italic(target) == a + b %.% italic(input)*","~~italic(r)^2~"="~r2*","~~p~"="~italic(pvalue), 
                   list(target = y,
                        input = x,
                        a = format(as.vector(coef(m)[1]), digits = 2), 
                        b = format(as.vector(coef(m)[2]), digits = 2), 
                        r2 = format(summary(m)$r.squared, digits = 3),
                        # getting the pvalue is painful
                        pvalue = format(summary(m)$coefficients[2,'Pr(>|t|)'], digits=1)
                   )
  )
  as.character(as.expression(eq));                 
}


#Plot temperature versus change in elevation

ggplot(data=dfPowellReleaseElevMaxes, aes(x=maxElev-minElev, y=maxTemp)) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  
  geom_point() +
  ggrepel::geom_text_repel(aes(label=Year.x), size=6) +
  geom_text(x=20,y=16,label=lm_eqn(dfPowellReleaseElevMaxes, 'maxElev-minElev','maxTemp'),color='red',parse=T, size=6) +
  geom_smooth(method='lm') +
 
  #scale_color_continuous(low=palBlues[2],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  labs(x="Annual Change in Water Surface Elevation (feet)", y="Max Release Temperature (oC)") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("CompareReleaseElevation.png", width=9, height = 6.5, units="in")



#Separate by Water Level and Temperature year types

ggplot(data=dfPowellReleaseElev %>% filter(Day %in% seq(1,31, by=2), !is.na(LevelYearType), !is.na(TempYearType)) %>% arrange(DateClean) , aes(x=WaterSurface,y=avgDay),color=LevelYearType) +
  #geom_line(aes(x=Day,y=avgDay), color="black") +
  #Error bar on release data - color by water surface
  #geom_errorbar(aes(ymin= minDay, ymax=maxDay, color=WaterYear), size=1) +
  geom_errorbar(aes(ymin= minDay, ymax=maxDay, color=as.factor(Month.x)), size=0.5) +
  #geom_path(aes(color=as.factor(Month.x)), size=1, na.rm = TRUE) +

  # Label Oct 1 of each year
  #geom_text(data=dfPowellReleaseElev %>% filter(Month.x==10,Day==1, !is.na(LevelYearType), !is.na(TempYearType)), aes(x=WaterSurface,y=avgDay,label=WaterYear),color="Purple", size=4) +
  geom_text_repel(data=dfPowellReleaseElev %>% filter(Month.x==1,Day==1, !is.na(LevelYearType), !is.na(TempYearType)), aes(x=WaterSurface,y=avgDay,label=WaterYear),color="Purple", size=4) +
  
  geom_point(data=dfPowellReleaseElev %>% filter(Month.x==1,Day==1, !is.na(LevelYearType), !is.na(TempYearType)), aes(x=WaterSurface,y=avgDay),color="purple") +
  
  #1:1 line
  #geom_abline(intercept = 0, slope = 1, color="red", linetype = "longdash", size = 1.5) + 
  #coord_fixed(ratio=1) + 

  #scale_x_discrete(breaks = c(3370, seq(3400,3720, by=50))) +
  scale_y_continuous(sec.axis = sec_axis(~. +0 ,name="Temperature Change", breaks=c(0), labels = c(""))) +
  scale_x_continuous(sec.axis = sec_axis(~. +0 ,name="Water Level Change", breaks=c(0), labels = c(""))) +

  #facet_grid(Month ~ Year) +
  
  #Color scale - "summer" months in red
  scale_color_manual(values=c(rep(palBlues[9],3), rep("Red",8), rep(palBlues[9],1))) +

  #scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  #scale_color_manual(values = c("Red","Blue","grey75", "grey50")) +
  
  labs(x="Water Surface Elevation (feet)", y="Release Temperature (oC)", color="Month") +
  #labs(x="Temperature at Wahweap @ 3,490 ft (oC)", y="Release Temperature (oC)", color="") +
  facet_grid( TempYearType ~ LevelYearType) +
   
  theme(text = element_text(size=18), legend.text=element_text(size=16),
        legend.key = element_blank())

ggsave("TempWaterLevelChange.png", width=9, height = 6.5, units="in")


## Plot the range of temperature by day for different years. Kind of a mess. avgDay is better.
# ggplot() +
#   #geom_line(aes(x=Day,y=avgDay), color="black") +
#   #Error bar on release data
#   geom_errorbar(data = dfPowellReleaseTempSum, aes(x=DayOfYear,ymin= minDay, ymax=maxDay, color=Year)) +
#   #Error bar on profile data
#   #geom_errorbar(data = dfTempAtDepth %>% filter(elevation == cIntakeElevRange[1]), aes(x=Day, ymin = IntTemp, ymax = IntTemp), color="red") +
#   
#   #scale_x_continuous(breaks = c(1,31)) +
#   #scale_y_continuous(breaks = c(8,16)) +
#   
#   #facet_grid(Month ~ Year) +
#   
#   labs(x="Julian Day", y="Release Temperature (oC)", color="Year") +
#   theme(text = element_text(size=12), legend.title=element_blank(), legend.text=element_text(size=10),
#         legend.key = element_blank())
# 
# ggsave("RangeTemperatureByYear.png", width=9, height = 6.5, units="in")





### Interative version of the release temperature timeseries compared to Wahweap
#test of dygraphs interactive time series
#https://www.r-graph-gallery.com/318-custom-dygraphs-time-series-example.html

#install.packages(c("dygraphs","xts"))

# Library


# Since my time is currently a factor, I have to convert it to a date-time format!
#data$datetime <- ymd_hms(data$datetime)

# Then you can create the xts necessary to use dygraph

#Create the dataframe
dfPowellTemp <- dfPowellReleaseTemp[,c("DateTimeClean","DateClean","WaterTemp_C")]
#Join in the Wahweap observations
dfPowellTemp <- left_join(dfPowellTemp,dfTempCompare %>% filter(elevation == cIntakeElevRange[1]) %>% select(DateClean,IntTemp), by=c("DateClean" = "DateClean"))
dfPowellTemp$Wahweap <- dfPowellTemp$IntTemp

# Plot timeseries compare release temperature and profile temperature

ggplot(data=dfPowellTemp) +
  #Release Temperature
  geom_line(aes(x = DateTimeClean,y = WaterTemp_C, color = "Release"), size=1) +
  geom_point(aes(x = DateTimeClean, y = Wahweap, color = "Wahweap @ 3,490 feet"), size=1.5) +
  
  scale_color_manual(values=c("Black","Red")) +
  #scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  scale_x_datetime() +
  
  theme_bw() +
  #coord_fixed() +
  labs(y="Water Temperature (oC)", x="", color="") +
  theme(text = element_text(size=18), legend.text=element_text(size=16), legend.position = c(0.2, 0.9))



ggsave("CompareReleaseWaweapVsTime.png", width=9, height = 6.5, units="in")


# Plot timeseries of release temperature with water surface as second dual plot.

ggplot(data=dfPowellReleaseElev) +
  #Release Temperature
  #Error bar on release data - color by water surface
  geom_errorbar(aes(x = as.POSIXct(DateClean), ymin= minDay, ymax=maxDay, color="Release Temperature"), size=1) +
  geom_line(aes(x = as.POSIXct(DateClean),y = 8 + 8*(WaterSurface - 3500)/(3700-3500), color = "Water Surface"), size=1) +
  #geom_point(aes(x = DateTimeClean, y = Wahweap), size=1.5) +
  
  scale_color_manual(values=c("Black","Red")) +
  #scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  
  scale_x_datetime() +
  scale_y_continuous(sec.axis = sec_axis(~ (. - 8)/8*(3700-3500) + 3500, name = "Water Surface (feet)")) +
  
  theme_bw() +
  #coord_fixed() +
  labs(y="Water Temperature (oC)", x="", color="") +
  theme(text = element_text(size=18), legend.text=element_text(size=16), legend.position = c(0.2, 0.9))

ggsave("CompareReleaseWaterLevelTime.png", width=9, height = 6.5, units="in")


# Plot timeseries of release temperature vs time and color by month. Red = Jun to Oct.

ggplot(data=dfPowellReleaseElev) +
  #Release Temperature
  #Error bar on release data - color by water surface
  geom_errorbar(aes(x = as.POSIXct(DateClean), ymin= minDay, ymax=maxDay, color=as.factor(Month.x)), size=1) +
  #geom_line(aes(x = as.POSIXct(DateClean),y = 8 + 8*(WaterSurface - 3500)/(3700-3500), color = "Water Surface"), size=1) +
  #geom_point(aes(x = DateTimeClean, y = Wahweap), size=1.5) +
  
  #Color scale - "summer" months in red
  scale_color_manual(values=c(rep(palBlues[9],3), rep("Red",8), rep(palBlues[9],1))) +
  #scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color") +
  
  
  scale_x_datetime() +
  #scale_y_continuous(sec.axis = sec_axis(~ (. - 8)/8*(3700-3500) + 3500, name = "Water Surface (feet)")) +
  
  theme_bw() +
  #coord_fixed() +
  labs(y="Water Temperature (oC)", x="", color="Month") +
  theme(text = element_text(size=18), legend.text=element_text(size=16), legend.position = c(0.2, 0.9))

ggsave("ReleaseTempWaterLevelTime.png", width=9, height = 6.5, units="in")

don <- xts(x = dfPowellTemp, order.by = dfPowellTemp$DateTimeClean)

# Finally the plot
p <- dygraph(don) %>%
  dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="#D8AE5A") %>%
  dyRangeSelector() %>%
  dyCrosshair(direction = "vertical") %>%
  dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
  dyRoller(rollPeriod = 1)

p

# save the widget
# library(htmlwidgets)
# saveWidget(p, file=paste0( getwd(), "/HtmlWidget/dygraphs318.html"))
