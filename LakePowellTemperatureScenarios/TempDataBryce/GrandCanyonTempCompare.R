# GrandCanyonTempCompare.r
#
# Compare Colorado River temperatures in the Grand Canyon at different River Miles.
# Data from Milhalevich et al (in review) - https://usu.box.com/s/ur2rme52rs36frcv94xtydiosmnp528v
# The basis data wrangling strategy is:
# 1. Load csv files
# 2. Clean the dates and calculate daily metrics
# 3. Plot in a variety of ways
#
# David E. Rosenberg
# Septemver 10, 2020
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

#Define the River locations to use
dfLocations <- data.frame(filename = c("LeesFerry_water_temp.csv", "Mile30_water_temp.csv","Mile61_water_temp.csv","Mile76_water_temp.csv","Mile149_water_temp.csv","Mile194_water_temp.csv"),
                          rivermile = c(0,30,61,76,149,194),
                          locname = c("Lees Ferry", "Marble", "Little Colorado", "LCR to Bright Angle","Kanab?","West Central"))

#Calculate the csv file name
dfLocations$filename <- ifelse(dfLocations$rivermile == 0,"LeesFerry_water_temp.csv",paste0("Mile",dfLocations$rivermile,"_water_temp.csv"))


### 1. Read IN the data files. Rbind so long list
dfTempAllLocs <- data.frame(DateTime = 0, water_temp = 0, rivermile = 0, location = 0)

for(i in 1:nrow(dfLocations)){
 # i <- 1
  
  # Read in the historical Powell data
  dfTempFile <- read.csv(file=dfLocations$filename[i], 
                         header=TRUE, 
                         
                         stringsAsFactors=FALSE,
                         sep=",")
  
  dfTempFile$rivermile <- factor(dfLocations$rivermile[i], levels = dfLocations$rivermile)
  dfTempFile$location <- factor(dfLocations$locname[i], levels = dfLocations$rivermile)
  
  
  #bind the latest record to the existing records
  dfTempAllLocs <- rbind(dfTempAllLocs,dfTempFile)
  }

#Remove the first dummy row
dfTempAllLocs <- dfTempAllLocs[2:nrow(dfTempAllLocs),]

library(chron)
#Convert just the date
dfTempAllLocs$DateClean <- as.Date(dfTempAllLocs$DateTime, "%m/%d/%Y")
#Convert the time
dfTempAllLocs$DateTimeClean <- mdy_hms(dfTempAllLocs$DateTime)


## Calculate daily min, max, average, range
dfTempAllLocsAgg <- dfTempAllLocs %>% group_by(DateClean, rivermile, location) %>% summarize(minDay = min(water_temp),
                                                                        maxDay = max(water_temp),
                                                                        avgDay = mean(water_temp),
                                                                        rangeDay = max(water_temp) - min(water_temp))


#Pull out Year, Month, Month as abbr, Day for plotting
dfTempAllLocsAgg$Year <- year(dfTempAllLocsAgg$DateClean)
dfTempAllLocsAgg$Month <- month(dfTempAllLocsAgg$DateClean)
dfTempAllLocsAgg$MonthTxt <- format(dfTempAllLocsAgg$DateClean, "%b")
dfTempAllLocsAgg$Day <- day(dfTempAllLocsAgg$DateClean)
dfTempAllLocsAgg$WaterYear <- ifelse(dfTempAllLocsAgg$Month >= 10,dfTempAllLocsAgg$Year, dfTempAllLocsAgg$Year - 1 )
dfTempAllLocsAgg$DayOfYear <- yday(dfTempAllLocsAgg$DateClean)

dfDaysPerYear <- dfTempAllLocsAgg %>% group_by(Year) %>% summarize(numDays = n())
dfDaysPerMonthYear <- dfTempAllLocsAgg %>% group_by(Year,Month) %>% summarize(numDays = n())



#Grab color palettes
palBlues <- brewer.pal(9, "Blues")
palReds <- brewer.pal(9, "Reds")
palBlueFunc <- colorRampPalette(c(palBlues[3],palBlues[9]))

###### 2. Plot Release temperature data vs time

## Plot Temperature as time series

#Plot hourly - too much data
ggplot(dfTempAllLocs, aes(x = DateTimeClean, y= water_temp, group=rivermile, color=rivermile)) +
  geom_line() +
  
  # scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Year") +
  
  scale_color_manual(values = palBlues[3:8], breaks = c(194,149,76,61,30,0)) + #c(0,30,61,76,149,194)) +
  labs(x="", y="Water Temperature (oC)", color = "Location") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())

ggsave("RiverTemperatureTimeSeries.png", width=9, height = 6.5, units="in")


#Temperature vs. river mile faceted by month
ggplot(dfTempAllLocsAgg, aes(x = as.numeric(rivermile), y = avgDay, color=Year, group=DateClean)) +
  geom_line() +
  #geom_errorbar(aes(ymin= minDay, ymax=maxDay, color=Year, group=DateClean)) +
  
  facet_wrap( ~ Month) +
  # scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Year") +
  ylim(8,20) + 
  #scale_color_manual(values = palBlues[3:8], breaks = c(194,149,76,61,30,0)) + #c(0,30,61,76,149,194)) +
  labs(x="River mile", y="Daily Average Water Temperature (oC)", color = "Year") +
  theme(text = element_text(size=20), legend.text=element_text(size=18),
        legend.key = element_blank())


ggsave("TempVsRiverMile.png", width=9, height = 6.5, units="in")


#Plot daily average
ggplot(dfTempAllLocsAgg, aes(x = DateClean, y = avgDay, group=rivermile, color=rivermile)) +
  geom_line() +
  
  # scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Year") +
  
  scale_color_manual(values = palBlues[3:8], breaks = c(194,149,76,61,30,0)) + #c(0,30,61,76,149,194)) +
  labs(x="", y="Water Temperature (oC)", color = "Location") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())


## Plot the range of temperature by day
ggplot() +
  
  geom_errorbar(data = dfTempAllLocsAgg, aes(x=DateClean,ymin= minDay, ymax=maxDay, color=rivermile, group=rivermile)) +
  scale_color_manual(values = palBlues[3:8], breaks = c(194,149,76,61,30,0)) + #c(0,30,61,76,149,194)) +
  
  
  labs(x="", y="Temperature (oC)", color="Location") +
  theme(text = element_text(size=12), legend.title=element_blank(), legend.text=element_text(size=10),
        legend.key = element_blank())

ggsave("TempRanges.png", width=9, height = 6.5, units="in")





## Plot cumulative distribution of the daily range for each month

pPlot <- ggplot(dfTempAllLocsAgg, aes(rangeDay, group=Month, color=MonthTxt)) +
  stat_ecdf(geom = "step") +
  
  #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
  #scale_y_continuous(breaks = seq(0,11,by=2)) +
  scale_color_manual(values = palBlueFunc(12)) +
  xlim(0,2) +
  
  facet_wrap( ~ rivermile ) +
  
  labs(x="Daily Range of River Temperature (oC)", y="Cumulative Frequency\n(number of days)", color = "Month") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())

direct.label(pPlot, "angled.boxes" )

ggsave("RiverTemperatureRangeCDFs.png", width=9, height = 6.5, units="in")


## Plot cumulative distribution of the daily range for each year

pPlot <- ggplot(dfTempAllLocsAgg, aes(rangeDay, group=WaterYear, color=WaterYear)) +
  stat_ecdf(geom = "step") +
  
  #scale_x_continuous(limits = c(2,22), breaks = seq(2,22,by=2)) +
  #scale_y_continuous(breaks = seq(0,11,by=2)) +
  scale_color_continuous(low=palBlues[3],high=palBlues[9], na.value="White", guide = "colorbar", aesthetics="color", name="Water Year") +
  
  xlim(0,2) +
  
  facet_wrap( ~ rivermile ) +
  
  labs(x="Daily Range of River Temperature (oC)", y="Cumulative Frequency\n(number of days)", color = "Water Year") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
        legend.key = element_blank())

direct.label(pPlot, "angled.boxes" )

ggsave("RiverTemperatureRangeByYearCDF.png", width=9, height = 6.5, units="in")

