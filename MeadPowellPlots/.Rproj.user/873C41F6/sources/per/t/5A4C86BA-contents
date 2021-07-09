# MeadPowellPlots.r
#
# Use data exported from CRSS to draw up several descriptive plots for Lakes Powell and Mead
# 1. Current Equalization Rule (as a Mead Storage vs Powell Storage)
# 2. Historical storage of Mead vs. Powell superimposed on #1
# 3. Mead Pool Levels (zones) by month of the year
# 4. Powell pool levels (zones) by month of the year
#
# This is a beginning R-programming effort! There could be lurking bugs or basic coding errors that I am not even aware of.
# Please report bugs/feedback to me (contact info below)
#
# David E. Rosenberg
# January 31, 2019
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


if (!require(plyr)) { 
  install.packages("plyr", repo="http://cran.r-project.org")
  library(plyr) 
}

if (!require(ggrepel)) { 
  devtools::install_github("slowkow/ggrepel")
  library(ggrepel) 
}



# New function interpNA to return NAs for values outside interpolation range (from https://stackoverflow.com/questions/47295879/using-interp1-in-r)
interpNA <- function(x, y, xi = x, ...) {
  yi <- rep(NA, length(xi));
  sel <- which(xi >= range(x)[1] & xi <= range(x)[2]);
  yi[sel] <- interp1(x = x, y = y, xi = xi[sel], ...);
  return(yi);
}



###This reservoir data comes from CRSS. It was exported to Excel.

# Read elevation-storage data in from Excel
sExcelFile <- 'MeadDroughtContingencyPlan.xlsx'
dfMeadElevStor <- read_excel(sExcelFile, sheet = "Mead-Elevation-Area",  range = "A4:D676")
dfPowellElevStor <- read_excel(sExcelFile, sheet = 'Powell-Elevation-Area',  range = "A4:D689")

# Read in Reservoir Pools Volumes / Zones from Excel
dfPoolVols <- read_excel(sExcelFile, sheet = "Pools",  range = "D31:O43")
# Read in Reserved Flood Storage
dfReservedFlood <- read_excel(sExcelFile, sheet = "Pools",  range = "C46:E58")
#Convert dates to months
dfReservedFlood$month_num <- month(as.POSIXlt(dfReservedFlood$Month, format="%Y-%m-%Y"))

### This historical reservoir level data comes from USBR websites.

# File name to read in historical Powell Volume from CSV (download from USBR)
#    Water Operations: Historic Data, Upper Colorado River Division, U.S. Buruea of Reclamation
#    https://www.usbr.gov/rsvrWater/HistoricalApp.html

sPowellHistoricalFile <- 'PowellDataUSBRJan2019.csv'
sPowellHistoricalFile <- 'PowellDataUSBRMay2021.csv'

# File name to read in Mead end of month reservoir level in feet - cross tabulated by year (1st column) and month (subsequent columns)
#    LAKE MEAD AT HOOVER DAM, END OF MONTH ELEVATION (FEET), Lower COlorado River Operations, U.S. Buruea of Reclamation
#    https://www.usbr.gov/lc/region/g4000/hourly/mead-elv.html

sMeadHistoricalFile <- 'MeadLevel.xlsx'

# Read in the historical Powell data
dfPowellHistorical <- read.csv(file=sPowellHistoricalFile, 
                               header=TRUE, 
                               
                               stringsAsFactors=FALSE,
                               sep=",")

# Read in the historical Mead data
dfMeadHistorical <- read_excel(sMeadHistoricalFile)

#Convert cross-tabulated Mead months into timeseries
dfMeadHist <- melt(dfMeadHistorical, id.vars = c("Year"))
dfMeadHist$BeginOfMonStr <- paste(dfMeadHist$Year,dfMeadHist$variable,"1",sep="-")
dfMeadHist$BeginOfMon <- as.Date(dfMeadHist$BeginOfMonStr, "%Y-%b-%d")
dfMeadHist$BeginNextMon <- dfMeadHist$BeginOfMon %m+% months(1)
#Filter out NAs
dfMeadHist <- dfMeadHist %>% filter(!is.na(dfMeadHist$value))
#Filter out low storages below min
dfMeadHist <- dfMeadHist %>% filter(dfMeadHist$value > min(dfMeadElevStor$`Elevation (ft)`))
dfMeadHist$Stor <- interp1(xi = dfMeadHist$value,y=dfMeadElevStor$`Live Storage (ac-ft)`,x=dfMeadElevStor$`Elevation (ft)`, method="linear")

#Interpolate Powell storage from level to check
dtStart <- as.Date("1963-12-22")
dfPowellHist <- dfPowellHistorical[15:705,] #%>% filter(dfPowellHistorical$Date >= dtStart) # I don't like this hard coding but don't know a way around
#Convert date text to date value
dfPowellHist$DateAsValueError <- as.Date(dfPowellHist$Date,"%d-%b-%y")
#Apparently R breaks the century at an odd place
#Coerce the years after 2030 (really 1930) to be in prior century (as.Date conversion error)
dfPowellHist$Year <- as.numeric(format(dfPowellHist$DateAsValueError,"%Y"))
dfPowellHist$DateAsValue <- dfPowellHist$DateAsValueError
dfPowellHist$DateAsValue[dfPowellHist$Year > 2030] <- dfPowellHist$DateAsValue[dfPowellHist$Year > 2030] %m-% months(12*100)
dfPowellHist$StorCheck <- interp1(xi = dfPowellHist$Elevation..feet.,y=dfPowellElevStor$`Live Storage (ac-ft)`,x=dfPowellElevStor$`Elevation (ft)`, method="linear")
dfPowellHist$StorDiff <- dfPowellHist$Storage..af. - dfPowellHist$StorCheck

#Merge the Mead and Powell Storage Time series
dfJointStorage <- merge(dfPowellHist[,c("DateAsValue","Storage..af.","Total.Release..cfs.")],dfMeadHist[,c("BeginNextMon","Stor")],by.x = "DateAsValue", by.y="BeginNextMon", all.x = TRUE, sort=TRUE)
#Rename columns so they are easier to distinquish
dfJointStorage$PowellStorage <- dfJointStorage$Storage..af./1000000
dfJointStorage$PowellRelease <- dfJointStorage$Total.Release..cfs.
dfJointStorage$MeadStorage <- dfJointStorage$Stor/1000000
#dfJointStorage$DateAsValue <- as.Date(dfJointStorage$Date,"%d-%b-%y")
#Remove the old columns
dfJointStorage <- dfJointStorage[, !names(dfJointStorage) %in% c("Storage..af.","Total.Release..cfs.","Stor")]
#Add a column for decade
dfJointStorage$decade <- round_any(as.numeric(format(dfJointStorage$DateAsValue,"%Y")),10,f=floor)
#dfJointStorage$DecadeAsClass <- dfJointStorage %>% mutate(category=cut(decade, breaks=seq(1960,2020,by=10), labels=seq(1960,2020,by=10)))

#Calculate Levels from volumes (interpolate from storage-elevation curve)
#Mead
dfMeadVals <- melt(subset(dfPoolVols,Reservoir == "Mead"),id.vars = c("Reservoir"))
dfMeadVals$level <- interp1(xi = dfMeadVals$value,x=dfMeadElevStor$`Live Storage (ac-ft)`,y=dfMeadElevStor$`Elevation (ft)`, method="linear")

#Powell
dfPowellVals <- melt(subset(dfPoolVols,Reservoir == "Powell"),id.vars = c("Reservoir"))
dfPowellVals$level <- interp1(xi = dfPowellVals$value,x=dfPowellElevStor$`Live Storage (ac-ft)`,y=dfPowellElevStor$`Elevation (ft)`, method="linear")


# Add months for later use in by month plots
dfPowellVals$month <- 1
dfPowellVals$EndMonth <- 12
dfMeadVals$month <- 1
dfMeadVals$EndMonth <- 12

dfPowellVals <- melt(dfPowellVals,id.vars = c("Reservoir","variable","value","level"))
# Remove replicated 5 and 6th columns
dfPowellVals$month <- dfPowellVals[,6]
dfPowellVals <- dfPowellVals[,-c(5,6)]
dfMeadVals <- melt(dfMeadVals,id.vars = c("Reservoir","variable","value","level"))
# Remove replicated 5 and 6th columns
dfMeadVals$month <- dfMeadVals[,6]
dfMeadVals <- dfMeadVals[,-c(5,6)]

# Convert to MAF storage
dfMeadVals$stor_maf <- dfMeadVals$value / 1000000
dfPowellVals$stor_maf <- dfPowellVals$value / 1000000

#Calculate the volume of flood storage space reserved
dfReservedFlood$Mead_flood_stor <- dfMeadVals[2,c("stor_maf")] - dfReservedFlood$Mead
dfReservedFlood$Powell_flood_stor <- dfPowellVals[2,c("stor_maf")] - dfReservedFlood$Powell
#Calculate levels for the reserved flood volumes
dfReservedFlood$Mead_level <- interp1(xi = dfReservedFlood$Mead_flood_stor*1000000,x=dfMeadElevStor$`Live Storage (ac-ft)`,y=dfMeadElevStor$`Elevation (ft)`, method="linear")
dfReservedFlood$Powell_level <- interp1(xi = dfReservedFlood$Powell_flood_stor*1000000,x=dfPowellElevStor$`Live Storage (ac-ft)`,y=dfPowellElevStor$`Elevation (ft)`, method="linear")

# Define maximum storages
dfMaxStor <- data.frame(Reservoir = c("Powell","Mead"),Volume = c(24.32,25.9))

# Include additional levels not in the CRSS data
dfMeadValsAdd <- data.frame(Reservoir = "Mead",
                            variable = c("Flood Pool (Jan 1\nFull upstream storage)","Eq. Protect Level","DCP trigger","ISG trigger","SNWA Intake #1","Eq. Mid Tier","SNWA Intake #2","SNWA Intake #3"),
                            level = c(min(dfReservedFlood$Mead_level),1105,1090,1075,1050,1025,1000,860),
                            month = 1)

#dfMeadValsAdd <- data.frame(Reservoir = "Mead",
#                            variable = c("Flood Pool (Jan 1\nFull upstream storage)","DCP trigger","ISG trigger","SNWA Intake #1","Eq. Mid Tier","SNWA Intake #2","SNWA Intake #3"),
#                            level = c(min(dfReservedFlood$Mead_level),1090,1075,1050,1025,1000,860),
#                            month = 1)


nRowMead <- nrow(dfMeadValsAdd)
dfMeadValsAdd$value <- 0
#Interpolate live storage volume
dfMeadValsAdd$value[1:(nRowMead-1)] <- interp1(xi = dfMeadValsAdd$level[1:(nRowMead-1)],x=dfMeadElevStor$`Elevation (ft)`,y=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear")
#Add SNWA third straw which is below dead pool
dfMeadValsAdd$value[nRowMead] <- -dfMeadVals[10,3]
dfMeadValsAdd$stor_maf <- dfMeadValsAdd$value / 1000000

#Define the powell equalization tiers
dfPowellTiers <- data.frame(Tier = c("Lower Tier","Mid Tier","Upper Tier","Eq. Elev.\n(year)","Equalization Tier","Capacity"),
                                        PowellLowerVol = c(0,5.93,9.52,15.54,19.29,dfMaxStor[1,2]))
dfPowellTiers <- mutate(dfPowellTiers, PowellMidVol = (lead(PowellLowerVol) + PowellLowerVol)/2)
# Mead volume to make plot labels come out nice
dfPowellTiers$MeadMid <- 0.67 #dfMaxStor[2,2]/2
dfPowellTiers$FontColor <- "black"
dfPowellTiers$MeadMid[4] <- 1.1 #Need to adjust plot position of this label
#Remove the fourth tier (equalization level)
dfPowellTiers <- dfPowellTiers[c(1:3,5),]
#Reset the mid point volume for the last tier
dfPowellTiers$PowellMidVol[4] <- mean(c(15.54,dfMaxStor[1,2]))


#Combine the original mead levels from CRSS with the levels added above
dfMeadAllPools <- rbind(dfMeadVals,dfMeadValsAdd) %>% filter(month == 1)
#dfMeadAllPools <- dfMeadAllPools[order(dfMeadAllPools$month, dfMeadAllPools$level),]

#Pull out the desired rows
#dfMeadPoolsPlot <- dfMeadAllPools[c(3,6,7,9:13,16),]
cMeadVarNames <- c("Inactive Capacity", "SNWA Intake #2", "Eq. Mid Tier", "SNWA Intake #1", "ISG trigger", "Minimum Power (from Object)",
                  "DCP trigger", "Eq. Protect Level", "Flood Pool (Jan 1\nFull upstream storage)","Bottom of Flood Pool (Feb- Sept)", "Live Capacity")
dfMeadPoolsPlot <- dfMeadAllPools %>% filter(variable %in% cMeadVarNames) %>% arrange(level)
dfMeadPoolsPlot$name <- as.character(dfMeadPoolsPlot$variable)
#Rename a few of the variable labels
dfMeadPoolsPlot[1,c("name")] <- "Dead Pool"
dfMeadPoolsPlot[6,c("name")] <- "Minimum Power (CRSS)"
dfMeadPoolsPlot[10,c("name")] <- "Flood Pool (Aug 1)"
#Create the y-axis tick label from the level and variable
dfMeadPoolsPlot$label <- paste(round(dfMeadPoolsPlot$level,0),'-',dfMeadPoolsPlot$name)


dfMeadTiers <- data.frame(elev = c(895,1025,1075,1105,1218.5))
#Interpolate off elevation area curve
dfMeadTiers$Volume <- vlookup(dfMeadTiers$elev,dfMeadElevStor,result_column=2,lookup_column = 1)

#Specify Powell Equalization levels by Year (data values from Interim Guidelines)
dfPowellEqLevels <- data.frame(Year = c(2008:2026), Elevation = c(3636,3639,3642,3643,3645,3646,3648,3649,3651,3652,3654,3655,3657,3659,3660,3663,3663,3664,3666))
dfPowellEqLevels$Volume <- vlookup(dfPowellEqLevels$Elevation,dfPowellElevStor,result_column=2,lookup_column = 1)/1000000
dfPowellEqLevels$MeadBeg <- 0
dfPowellEqLevels$MeadEnd <- dfMaxStor[2,2]
#dfPowellEqLevels$YearAsLabel <- paste0(dfPowellEqLevels$Year," Eq. Level","")
dfPowellEqLevels$YearAsLabel <- paste0("Upper Eq. Tier (",dfPowellEqLevels$Year,")")
#Filter by years of interest
cYears <- c(2008, 2019, 2026)
dfPowellEqLevelsFilt <- dfPowellEqLevels[,c("Year","YearAsLabel","Volume","MeadBeg", "MeadEnd")] %>% filter(Year %in% cYears) %>% arrange(Year)
dfPowellEqPlot <- melt(dfPowellEqLevelsFilt[,c("Year","Volume","MeadBeg", "MeadEnd")],id.vars = c("Year","Volume"))


# Define the polygons showing each tier to add to the plot. A polygon is defined by four points on the Mead-Powell storage plot. Lower-left (low Powell, low Mead), Lower-right (high Powell, low Mead), upper-right, upper-left (low Powell, high Mead)
# Polygon name
ids <- factor(c("Lower Tier", "Mid-Elevation Tier: Low Mead", "Mid-Elevation Tier: Higher Mead",
                    "Upper-Elevation Tier: Lower Mead", "Upper-Elevation Tier: Higher Mead", "Eq. Elev. (year)", "Equalization"))
# Polygon corners (see above for defs)
dfPositions <- data.frame(id = rep(ids, each = 4),
   PowellVol = c(0,5.93,5.93,0,5.93,9.52,9.52,5.93,5.93,9.52,9.52,5.93,9.52,15.54,15.54,9.52,9.52,15.54,15.54,9.52,15.54,19.29,19.29,15.54,19.29,dfMaxStor[1,2],dfMaxStor[1,2],19.29),
   MeadVol = c(0,0,dfMaxStor[2,2],dfMaxStor[2,2],0,0,5.98,5.98,5.98,5.98,25.9,dfMaxStor[2,2],0,0,9.6,9.6,9.6,9.6,dfMaxStor[2,2],dfMaxStor[2,2],0,0,dfMaxStor[2,2],dfMaxStor[2,2],0,0,dfMaxStor[2,2],dfMaxStor[2,2]))
#Allowable release(s) within each polygon
dfReleases <- data.frame(id = ids,
     Release = c("Balance:\nRelease\n7.0 to 9.5\nMAF per year", "Release\n8.23\nMAF\nper year", "Release\n7.48\nMAF\nper year", "Balance:\nRelease\n7 to 9\nMAF per year", "Release\n8.23\nMAF per year", "","Release\n8.23 or above\nMAF per year"),
     DumVal = c(1:7))


#Calculate midpoints for each polygon. This is the average of the cooridinates for
# the polygon
nPts <- nrow(dfPositions)/4
dfReleases$MidPowell <- 0
dfReleases$MidMead <- 0

for (point in 1:nPts) {
  dfReleases[point,c("MidPowell")] = mean(dfPositions[(4*(point-1)+1):(4*point),c("PowellVol")])
  dfReleases[point,c("MidMead")] = mean(dfPositions[(4*(point-1)+1):(4*point),c("MeadVol")])
  
}


#Reset midpoint positions for the 1st, 3rd, and 5th polygons  to high Mead Levels to position labels out of the way of other stuff on the figure (history)
dfReleases$MidMead[c(1,3,5)] <- 23.5


# Currently we need to manually merge the two together
dfPolyAll <- merge(dfReleases, dfPositions, by = c("id"))

dfOneToOneByFraction <- data.frame(PowellStor = c(0,dfMaxStor[1,2]),MeadStor = c(0,dfMaxStor[2,2]))
dfOneToOneByVolume <- data.frame(PowellStor = c(0,dfMaxStor[1,2]),MeadStor = c(0,dfMaxStor[1,2]))

#Pull in a blue color scheme for the pools
palBlues <- brewer.pal(9, "Blues") #For plotting equalization tiers
palPurples <- brewer.pal(9,"RdPu") #For overplotting one equalization tier
cPurple <- palPurples[8]
palReds <- brewer.pal(9,"Reds") #For plotting historical decade by color
palGreys <- brewer.pal(9,"Greys")

dfPowellTiers$FontColor[4] <- cPurple

#Construct the polygon fills from the blues. The last two tiers get the same blue color
#cTierColors <- c(palBlues[2:6],palPurples[3],palBlues[8])
cTierColors <- c(palBlues[2:6],palBlues[7],palBlues[7])

#Filter joint storages
dStart = 2007

#Filter to Januaries before and after start date
dfJointStorageFilt <- dfJointStorage %>% arrange(dfJointStorage$DateAsValue) %>% filter(month(dfJointStorage$DateAsValue) == 1) 
dfJointStorageFiltBefore <- dfJointStorageFilt %>% arrange(dfJointStorageFilt$DateAsValue) %>% filter(as.numeric(format(dfJointStorageFilt$DateAsValue,"%Y")) <= dStart) 
dfJointStorageFiltAfter <- dfJointStorageFilt %>% arrange(dfJointStorageFilt$DateAsValue) %>% filter(as.numeric(format(dfJointStorageFilt$DateAsValue,"%Y")) >= dStart) 

#Filter to all months before and after start date
dfJointStorageBefore <- dfJointStorage %>% arrange(dfJointStorage$DateAsValue) %>% filter(as.numeric(format(dfJointStorage$DateAsValue,"%Y")) <= dStart) 
dfJointStorageAfter <- dfJointStorage %>% arrange(dfJointStorage$DateAsValue) %>% filter(as.numeric(format(dfJointStorage$DateAsValue,"%Y")) >= dStart) 

#### #1 - Show Current Equalization Rules
# Run 3 versions of the plot.
#   One with just the rules/tiers/zones
#   One with January monthly storage balance overlayed. Red is years before 2007 and Equilization Rules went into effect.
#       Purple is years after 2007 when Equalization Rules were in effect
#   One with Year storage balance (January) overlayed in Red (before guidelines) and Purple (after guidelines)

cS <- c(1:3)
cFileNames <- c("PowellMeadEq-Blank","PowellMeadEq-Annual","PowellMeadEq-Monthly")
cFileType <- ".tiff"

for (i in cS){

  p <- ggplot(dfPolyAll, aes(x = PowellVol, y = MeadVol)) +
    #Background tiers of different blues
    geom_polygon(aes(fill = as.factor(DumVal), group = id)) +
    #Plot equalization lines for years
    geom_line(data = dfPowellEqPlot, aes(x = Volume, y = value,group=Year, color="Equalization levels (Year)"),size=1.25, linetype=2, show.legend = FALSE) + 
    #Label the boundary between the Upper Equalization Tier and the Equalization Tier (year dependent)
    geom_text(data=dfPowellEqLevelsFilt, aes( x = Volume + 0.4, y = MeadEnd/5, label = YearAsLabel), color="black", angle = 90, size = 5) +
    # Plot a 1:1 line to total storage
    geom_line(data=dfOneToOneByVolume,aes(x=PowellStor,y=MeadStor, group=1, color="1:1 line (by volume)"), size=2, linetype="longdash", show.legend = FALSE) +
    #Label the 1:1 line
    geom_text(aes(x=3.5,y=4.2,label="1:1 line"), color="black", angle = 45, size =6, show.legend = FALSE) 
  
    if (i==2){
      #Overplot Mead-Powell historical storage -- January of each year
      #Before guidelines in place in Red
      p<- p + geom_path(data = dfJointStorageFiltBefore, aes(x = PowellStorage, y = MeadStorage, color="Before Guidelines"), size=1.5, linetype=1, show.legend = TRUE)
      #After guidelines in place in purple
      p<- p + geom_path(data = dfJointStorageFiltAfter, aes(x = PowellStorage, y = MeadStorage, color="After Guidelines"), size=1.5, linetype=1, show.legend = TRUE)
      }
    
    if (i==3){
      #Overplot Mead-Powell historical storage -- all months  
      #Before guidelines in place in Red
      p <- p+ geom_path(data = dfJointStorageBefore, aes(x = PowellStorage, y = MeadStorage, color="Before Guidelines"), size=1, linetype=1, show.legend = TRUE)
      #After guidelines in place in Purple
      p <- p+ geom_path(data = dfJointStorageAfter, aes(x = PowellStorage, y = MeadStorage, color="After Guidelines"), size=1, linetype=1, show.legend = TRUE)
      
            }
    
    if (i==2 || i==3) {
      #Label the each January with it's year
      p <- p + geom_text_repel(data=dfJointStorageFilt[-seq(0,nrow(dfJointStorageFilt),2),], point.padding = NA, aes( x = PowellStorage, y = MeadStorage, label = year(DateAsValue), color="YearsText", angle = 0, size = 4, check_overlap = TRUE))
      #p <- p + geom_text(data=dfJointStorageFiltAfter, aes( x = PowellStorage, y = MeadStorage, label = year(DateAsValue), color="AfterGuidesText", angle = 0, size = 4, check_overlap = TRUE))
      #p <- p + geom_text_repel(data=dfJointStorageFiltAfter[-seq(0,nrow(dfJointStorageFiltBefore),2),], aes( x = PowellStorage, y = MeadStorage, label = year(DateAsValue), color="AfterGuidesText", angle = 0, size = 4, check_overlap = TRUE))
      
            }
    
    #set colors for lines
 
        p <- p + scale_color_manual(breaks = c("Before Guidelines", "After Guidelines"),
                                    values= c("black",palPurples[8], palPurples[5], "black","black"),
                                    labels = c("Before Guidelines", "With Guidelines")) +
        
    #Label the equalization tiers with white callouts
    geom_label(data=dfPowellTiers, aes(x = PowellMidVol, y = MeadMid, label = Tier, fontface="bold"), size=5, angle = 0) + 
    #Label the annual release amount within each equalization tier
    geom_text(data=dfReleases, aes( x = MidPowell, y = MidMead, label = Release), angle = 0, size = 5) + 
  
    #Create secondary y axes for Mead Lake Level
    scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
    #Create secodary x axes for Powell Lake Level
    scale_x_continuous(sec.axis = sec_axis(~. +0, name = "Powell Level (feet)", breaks = c(0,5.93,9.52,15.54,19.29,24.32) , labels = c(3370,3525,3575,3636,3666,3700))) +
  
    #Specify fill colors for equalization tier quadrants    
    scale_fill_manual(breaks=c(1:7),values = cTierColors,labels = dfReleases$Release) + 
    theme_bw() +
    coord_fixed() +
   
    guides(size = "none", colour = guide_legend("Historical volumes (year)"), fill="none") +
    labs(x="Powell Active Storage (MAF)", y="Mead Active Storage (MAF)", fill = "Powell Release (MAF/year)") +
    theme(text = element_text(size=20), legend.text=element_text(size=16),
            panel.border = element_rect(colour = "black", fill="NA"),
            legend.background = element_blank(),
            legend.box.background = element_rect(colour = "black", fill=palGreys[2]),
            legend.position = c(1.13,0.620))
    
    
  print(p)
  #Low Resolution version
  ggsave(paste0(cFileNames[i],cFileType), width=9, height = 6.5, units="in", dpi=96)
  #High Resolution version
  ggsave(paste0(cFileNames[i],"-HRES",cFileType), width=9, height = 6.5, units="in", dpi=300)
}





#Add the label for the 1:1 line
#direct.label(p,"angled.boxes")



##### #3. Plot MEAD Pool Levels/Volumes including Flood storage as a function of upstream storage
# Select the pools
cMeadVarNames <- c("Dead Pool", "SNWA Intake #1", "ISG trigger", "DCP trigger", "Live Capacity")
dfMeadPoolsMonthly <- dfMeadPoolsPlot %>% filter(name %in% cMeadVarNames) %>% arrange(-level)
dfMeadPoolsMonthly$EndMonth <- 12
dfMeadPoolsMonthlyMelt <- melt(dfMeadPoolsMonthly[,c("Reservoir","name","level","stor_maf","month","EndMonth")],id.vars = c("Reservoir","name","level","stor_maf"))
dfMeadPoolsMonthlyMelt$Month <- dfMeadPoolsMonthlyMelt$value
dfMeadPoolsMonthlyMelt <- dfMeadPoolsMonthlyMelt[,-c(5,6)]
dfPlotData <- dfMeadPoolsMonthlyMelt %>% arrange(-level,Month)

# Calculate new flood pools as a function of empty upstream storage
MaxMeadFloodPool <- max(dfReservedFlood$Mead_flood_stor)

cFillContours <- c(1,2,3)
cFillNames <- c("one","two","three","four")

nRowsPools <- nrow(dfReservedFlood)

dfFloodPools <- as.data.frame(dfReservedFlood[,c("month_num")])
dfFloodPools$'0' <- dfReservedFlood$Mead_flood_stor
dfFloodPools$'1' <- 0
dfFloodPools$'2' <- 0
dfFloodPools$'3' <- 0

for (contour in cFillContours) {
 #Credit the empty upstream storage
 dfFloodPools[,contour+2] <- dfReservedFlood$Mead_flood_stor + cFillContours[contour]
 #Maintain a minimum flood pool
  for (iRow in  (1:nrow(dfFloodPools))) {
      dfFloodPools[iRow,contour+2] <- min(dfFloodPools[iRow,contour+2], MaxMeadFloodPool)
  }
}

#Melt the contour data
dfFloodPoolsMelt <- melt(dfFloodPools,id.vars = c("month_num"))

#Adjust the right level ticks
dfMeadPoolsPlot2 <- dfMeadPoolsPlot
dfMeadPoolsPlot2[9,8] <- "1192 - Max. Req. Flood Pool"
dfMeadPoolsPlot2[10,8] <- "1218 - Min. Req. Flood Pool"

#Create the month ticks
cMonths <- 1:12
cMonthsLabels <- month.abb[cMonths]


ggplot() +
  geom_line(data=dfPlotData,aes(x=Month,y=stor_maf, color = name), size=2) +
  scale_color_manual(values = palBlues[10:-1:2]) +
  #geom_area(data=dfPlotData,aes(x=month,y=stor_maf, fill = variable), position='stack') +
  #scale_fill_manual(values = palBlues[7:-1:2]) +
  geom_line(data=dfFloodPoolsMelt,aes(x=month_num, y=value, group = variable), size=1) +
  #Label the flood pool contours of empty upstream storage
  geom_label(data=dfFloodPoolsMelt %>% filter(month_num %in% c(3,11)), aes( x = month_num, y = value, label = variable, fontface="bold"), size=5, angle = 0) + 
  geom_label(aes( x = 7, y = 23, label = "[MAF of empty upstream storage]", fontface="bold"), label.size = 0, size=5, angle = 0) + 
  
  #Label the levels within the equalization tiers
  #geom_text(data=dfReleases, aes( x = MidPowell, y = MidMead, label = Release), angle = 0, size = 6) + 
  
  #Create secondary axes for Lake Levels
  # Can't figure out why dfMeadTiers$Volume does not work!!!! Hard coding ...
  #ylim(0,dfPlotData[1,c("stor_maf")]+1) + 
  #scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = LevelsAsTicks$stor_maf, labels = round(LevelsAsTicks$level,1))) +
  scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Elevation (feet)", breaks = dfMeadPoolsPlot2$stor_maf, labels = dfMeadPoolsPlot2$label)) +
  
  #    scale_y_continuous(breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]),labels=c(0,5.98,9.6,12.2,dfMaxStor[2,2]),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]), labels = c(895,1025,1075,1105,1218.8))) +
  #scale_x_discrete(breaks=cMonths, labels= cMonthsLabels) +
  scale_x_continuous(breaks=cMonths, labels= cMonthsLabels) +

  
  #scale_fill_manual(breaks=c(1:6),values = palBlues[2:7]) + #,labels = variable) + 
  theme_bw() +
  #coord_fixed() +
  labs(x="", y="Active Storage (MAF)", fill = "Pool") +
  theme(text = element_text(size=20), legend.title=element_blank(), 
        legend.text=element_text(size=18), legend.position = "none",
        axis.text.x = element_text(size=18))

ggsave("MeadPools.png", width=9, height = 6.5, units="in")


##### #4. Plot POWELL Pool Levels including Flood storage as a function of upstream storage
# Prepare data for Lower and Mid equalization tiers
dfPowellTiersAsPools <- dfPowellTiers[,c("Tier","PowellLowerVol")]
colnames(dfPowellTiersAsPools) <- c("variable","PowellLowerVol")
dfPowellTiersAsPools$stor_maf <- 0;
dfPowellTiersAsPools <- mutate(dfPowellTiersAsPools, stor_maf = lead(PowellLowerVol))
dfPowellTiersAsPools$Reservoir <- 'Powell'
dfPowellTiersAsPools$value <- dfPowellTiersAsPools$stor_maf*1000000
dfPowellTiersAsPools <- dfPowellTiersAsPools[1:2,]
dfPowellTiersAsPools$PowellLowerVol <- NULL

#Work on the equalization levels
dfPowellEqLevelsAsPools <- dfPowellEqLevelsFilt
colnames(dfPowellEqLevelsAsPools) <- c("Year","variable","stor_maf","MeadBeg","MeadEnd")
dfPowellEqLevelsAsPools$value <- 1000000*dfPowellEqLevelsAsPools$stor_maf
dfPowellEqLevelsAsPools$Reservoir <- "Powell"
#drop the three uneeded columns
dfPowellEqLevelsAsPools <- subset(dfPowellEqLevelsAsPools,select = -c(Year,MeadBeg,MeadEnd))

dfPowellTiersAsPools <- rbind(dfPowellTiersAsPools,dfPowellEqLevelsAsPools)

dfPowellTiersAsPools$level <- interp1(xi = dfPowellTiersAsPools$value,x=dfPowellElevStor$`Live Storage (ac-ft)`,y=dfPowellElevStor$`Elevation (ft)`, method="linear")
dfPowellTiersAsPools$month <- 1

dfPowellAllPools <- rbind(dfPowellVals,dfPowellTiersAsPools) %>% filter(month == 1)

cPowellRows <- c(2,4,7,9,12,13,14,15,16)
cPowellVarNames <- dfPowellAllPools$variable[cPowellRows]
dfPowellPoolsPlot <- dfPowellAllPools %>% filter(variable %in% cPowellVarNames) %>% arrange(level)
dfPowellPoolsPlot$name <- as.character(dfPowellPoolsPlot$variable)
#Save the data to csv
write.csv(dfPowellAllPools,"dfPowellAllPools.csv")

#Rename a few of the variable labels
dfPowellPoolsPlot[1,c("name")] <- "Dead Pool"
dfPowellPoolsPlot[2,c("name")] <- "Minimum Power (CRSS)"
dfPowellPoolsPlot[8,c("name")] <- "Flood Pool (Nov 1 to Jan 31)"
cPowellVarNames <- dfPowellPoolsPlot$name
#Create the y-axis tick label from the level and variable
dfPowellPoolsPlot$label <- paste(round(dfPowellPoolsPlot$level,0),'-',dfPowellPoolsPlot$name)


dfPowellPoolsMonthly <- dfPowellPoolsPlot %>% filter(name %in% cPowellVarNames) %>% arrange(-level)
dfPowellPoolsMonthly$EndMonth <- 12
dfPowellPoolsMonthlyMelt <- melt(dfPowellPoolsMonthly[,c("Reservoir","name","level","stor_maf","month","EndMonth")],id.vars = c("Reservoir","name","level","stor_maf"))
dfPowellPoolsMonthlyMelt$Month <- dfPowellPoolsMonthlyMelt$value
dfPowellPoolsMonthlyMelt <- dfPowellPoolsMonthlyMelt[,-c(5,6)]
dfPlotData <- dfPowellPoolsMonthlyMelt %>% arrange(-level,Month)
#Remove the Flood pool entry
dfPlotData2 <- dfPlotData %>% filter(name != dfPowellPoolsPlot[8,c("name")]) %>% arrange(-level)


ggplot() +
  geom_line(data=dfPlotData2,aes(x=Month,y=stor_maf, color = name), size=2) +
  scale_color_manual(values = palBlues[9:-1:2], breaks=cPowellVarNames) +
  #geom_area(data=dfPlotData,aes(x=month,y=stor_maf, fill = variable), position='stack') +
  #scale_fill_manual(values = palBlues[7:-1:2]) +
  geom_line(data=dfReservedFlood,aes(x=month_num, y=Powell_flood_stor, group = 1), size=2) +
 
  #Label the levels within the equalization tiers
  #geom_text(data=dfReleases, aes( x = MidPowell, y = MidMead, label = Release), angle = 0, size = 6) + 
  
  #Create secondary axes for Lake Levels
  # Can't figure out why dfMeadTiers$Volume does not work!!!! Hard coding ...
  #ylim(0,dfPlotData[1,c("stor_maf")]+1) + 
  #scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = LevelsAsTicks$stor_maf, labels = round(LevelsAsTicks$level,1))) +
  scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Elevation (feet)", breaks = dfPowellPoolsPlot$stor_maf, labels = dfPowellPoolsPlot$label)) +
  
  #    scale_y_continuous(breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]),labels=c(0,5.98,9.6,12.2,dfMaxStor[2,2]),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]), labels = c(895,1025,1075,1105,1218.8))) +
  #scale_x_discrete(breaks=cMonths, labels= cMonthsLabels) +
  scale_x_continuous(breaks=cMonths, labels= cMonthsLabels) +
  
  
  #scale_fill_manual(breaks=c(1:6),values = palBlues[2:7]) + #,labels = variable) + 
  theme_bw() +
  #coord_fixed() +
  labs(x="", y="Active Storage (MAF)", fill = "Pool") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18), legend.position = "none")

ggsave("PowellPools.png", width=9, height = 6.5, units="in")


### DER January 31, 2020 - Plot Reservoir Storage over time
### Mead, Powell, All onn same plot including total system storage

##### #5. Plot historical MEAD Pool Levels/Volumes over time
# Select the pools

dStartDate <- min(dfMeadHist$BeginOfMon)
dEndDate <- max(dfMeadHist$BeginOfMon)

cMeadVarNames <- c("Dead Pool", "SNWA Intake #1", "ISG trigger", "DCP trigger", "Live Capacity")
dfMeadPoolsMonthly <- dfMeadPoolsPlot %>% filter(name %in% cMeadVarNames) %>% arrange(-level)
dfMeadPoolsMonthly$month <- dStartDate
dfMeadPoolsMonthly$EndMonth <- dEndDate
dfMeadPoolsMonthlyMelt <- melt(dfMeadPoolsMonthly[,c("Reservoir","name","level","stor_maf","month","EndMonth")],id.vars = c("Reservoir","name","level","stor_maf"))
dfMeadPoolsMonthlyMelt$Month <- dfMeadPoolsMonthlyMelt$value
dfMeadPoolsMonthlyMelt <- dfMeadPoolsMonthlyMelt[,-c(5,6)]
dfPlotData <- dfMeadPoolsMonthlyMelt %>% arrange(-level,Month)

# Calculate new flood pools as a function of empty upstream storage
MaxMeadFloodPool <- max(dfReservedFlood$Mead_flood_stor)

cFillContours <- c(1,2,3)
cFillNames <- c("one","two","three","four")

nRowsPools <- nrow(dfReservedFlood)

dfFloodPools <- as.data.frame(dfReservedFlood[,c("month_num")])
dfFloodPools$'0' <- dfReservedFlood$Mead_flood_stor
dfFloodPools$'1' <- 0
dfFloodPools$'2' <- 0
dfFloodPools$'3' <- 0

for (contour in cFillContours) {
  #Credit the empty upstream storage
  dfFloodPools[,contour+2] <- dfReservedFlood$Mead_flood_stor + cFillContours[contour]
  #Maintain a minimum flood pool
  for (iRow in  (1:nrow(dfFloodPools))) {
    dfFloodPools[iRow,contour+2] <- min(dfFloodPools[iRow,contour+2], MaxMeadFloodPool)
  }
}

#Melt the contour data
dfFloodPoolsMelt <- melt(dfFloodPools,id.vars = c("month_num"))

#Adjust the right level ticks
dfMeadPoolsPlot2 <- dfMeadPoolsPlot
dfMeadPoolsPlot2[9,8] <- "1192 - Max. Req. Flood Pool"
dfMeadPoolsPlot2[10,8] <- "1218 - Min. Req. Flood Pool"
#Remove 1083 minimum power pool
dfMeadPoolsPlot2 <- dfMeadPoolsPlot2[c(seq(1,5),seq(7,11)),]

#Create the month ticks
cMonths <- 1:12
cMonthsLabels <- month.abb[cMonths]


ggplot() +
  
  #Zone levels
  geom_line(data=dfPlotData,aes(x=Month,y=stor_maf, group = as.factor(level), color = as.factor(level)), size=1.25) +
  #Mead storage
  geom_line(data=dfMeadHist,aes(x=BeginOfMon,y=Stor/1e6), size=2) +
  
  scale_color_manual(values = palBlues[seq(5,10)]) +
  #geom_area(data=dfPlotData,aes(x=month,y=stor_maf, fill = variable), position='stack') +
  #scale_fill_manual(values = palBlues[7:-1:2]) +
  #Flood pools as a function of upstream storage
  #geom_line(data=dfFloodPoolsMelt,aes(x=month_num, y=value, group = variable), size=1) +
  #Label the flood pool contours of empty upstream storage
  #geom_label(data=dfFloodPoolsMelt %>% filter(month_num %in% c(3,11)), aes( x = month_num, y = value, label = variable, fontface="bold"), size=5, angle = 0) + 
  #geom_label(aes( x = 7, y = 23, label = "[MAF of empty upstream storage]", fontface="bold"), label.size = 0, size=5, angle = 0) + 
  
  scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Elevation (feet)", breaks = dfMeadPoolsPlot2$stor_maf, labels = dfMeadPoolsPlot2$label)) +
  
  #    scale_y_continuous(breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]),labels=c(0,5.98,9.6,12.2,dfMaxStor[2,2]),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]), labels = c(895,1025,1075,1105,1218.8))) +
  #scale_x_discrete(breaks=cMonths, labels= cMonthsLabels) +
  #scale_x_continuous(breaks=seq(1960,2020,by=10)) +
  
  
  #scale_fill_manual(breaks=c(1:6),values = palBlues[2:7]) + #,labels = variable) + 
  theme_bw() +
  #coord_fixed() +
  labs(x="", y="Mead Active Storage (MAF)", fill = "Pool") +
  theme(text = element_text(size=20), legend.title=element_blank(), 
        legend.text=element_text(size=18), legend.position = "none",
        axis.text.x = element_text(size=18))

ggsave("MeadTimeSeries.png", width=9, height = 6.5, units="in")


##### #6. Plot POWELL storage over time
# Prepare data for Lower and Mid equalization tiers


dfPowellTiersAsPools <- dfPowellTiers[,c("Tier","PowellLowerVol")]
colnames(dfPowellTiersAsPools) <- c("variable","PowellLowerVol")
dfPowellTiersAsPools$stor_maf <- 0;
dfPowellTiersAsPools <- mutate(dfPowellTiersAsPools, stor_maf = lead(PowellLowerVol))
dfPowellTiersAsPools$Reservoir <- 'Powell'
dfPowellTiersAsPools$value <- dfPowellTiersAsPools$stor_maf*1000000
dfPowellTiersAsPools <- dfPowellTiersAsPools[1:2,]
dfPowellTiersAsPools$PowellLowerVol <- NULL

#Work on the equalization levels
dfPowellEqLevelsAsPools <- dfPowellEqLevelsFilt
colnames(dfPowellEqLevelsAsPools) <- c("Year","variable","stor_maf","MeadBeg","MeadEnd")
dfPowellEqLevelsAsPools$value <- 1000000*dfPowellEqLevelsAsPools$stor_maf
dfPowellEqLevelsAsPools$Reservoir <- "Powell"
#drop the three uneeded columns
dfPowellEqLevelsAsPools <- subset(dfPowellEqLevelsAsPools,select = -c(Year,MeadBeg,MeadEnd))

dfPowellTiersAsPools <- rbind(dfPowellTiersAsPools,dfPowellEqLevelsAsPools)

dfPowellTiersAsPools$level <- interp1(xi = dfPowellTiersAsPools$value,x=dfPowellElevStor$`Live Storage (ac-ft)`,y=dfPowellElevStor$`Elevation (ft)`, method="linear")
dfPowellTiersAsPools$month <- 1

dfPowellAllPools <- rbind(dfPowellVals,dfPowellTiersAsPools) %>% filter(month == 1)

cPowellRows <- c(2,4,7,9,12,13,14,15,16)
cPowellVarNames <- dfPowellAllPools$variable[cPowellRows]
dfPowellPoolsPlot <- dfPowellAllPools %>% filter(variable %in% cPowellVarNames) %>% arrange(level)
dfPowellPoolsPlot$name <- as.character(dfPowellPoolsPlot$variable)
#Rename a few of the variable labels
dfPowellPoolsPlot[1,c("name")] <- "Dead Pool"
dfPowellPoolsPlot[2,c("name")] <- "Minimum Power (CRSS)"
dfPowellPoolsPlot[8,c("name")] <- "Flood Pool (Nov 1 to Jan 31)"
cPowellVarNames <- dfPowellPoolsPlot$name
#Create the y-axis tick label from the level and variable
dfPowellPoolsPlot$label <- paste(round(dfPowellPoolsPlot$level,0),'-',dfPowellPoolsPlot$name)


dfPowellPoolsMonthly <- dfPowellPoolsPlot %>% filter(name %in% cPowellVarNames) %>% arrange(-level)
dfPowellPoolsMonthly$EndMonth <- 12
dfPowellPoolsMonthlyMelt <- melt(dfPowellPoolsMonthly[,c("Reservoir","name","level","stor_maf","month","EndMonth")],id.vars = c("Reservoir","name","level","stor_maf"))
dfPowellPoolsMonthlyMelt$Month <- dfPowellPoolsMonthlyMelt$value
dfPowellPoolsMonthlyMelt <- dfPowellPoolsMonthlyMelt[,-c(5,6)]
dfPlotData2 <- dfPowellPoolsMonthlyMelt %>% arrange(-level,Month)
#Remove the Flood pool entry
dfPlotData2 <- dfPlotData2 %>% filter(name != dfPowellPoolsPlot[8,c("name")]) %>% arrange(-level)
#Add Full Dates
dStartDate <- min(dfJointStorage$DateAsValue)
dfPlotData2$Dates <- rep(c(dStartDate,dEndDate),times=nrow(dfPlotData2)/2)

ggplot() +
  #Powell Zones
  geom_line(data=dfPlotData2,aes(x=Dates,y=stor_maf, color = name), size=1.25) +
  #Powell storage
  geom_line(data=dfJointStorage,aes(x=DateAsValue,y=PowellStorage), size=2) +
  scale_color_manual(values = palBlues[9:-1:2], breaks=cPowellVarNames) +
  #geom_area(data=dfPlotData,aes(x=month,y=stor_maf, fill = variable), position='stack') +
  scale_y_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25),  sec.axis = sec_axis(~. +0, name = "Elevation (feet)", breaks = dfPowellPoolsPlot$stor_maf, labels = dfPowellPoolsPlot$label)) +
  
  #    scale_y_continuous(breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]),labels=c(0,5.98,9.6,12.2,dfMaxStor[2,2]),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]), labels = c(895,1025,1075,1105,1218.8))) +
  #scale_x_discrete(breaks=cMonths, labels= cMonthsLabels) +
  #scale_x_continuous(breaks=seq(1960,2020,by=10), labels= seq(1960,2020,by=10)) +
  
  
  #scale_fill_manual(breaks=c(1:6),values = palBlues[2:7]) + #,labels = variable) + 
  theme_bw() +
  #coord_fixed() +
  labs(x="", y="Powell Active Storage (MAF)", fill = "Pool") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18), legend.position = "none")

ggsave("PowellStorageTime.png", width=9, height = 6.5, units="in")

#################################################
#### COMBINED POWELL AND MEAD STORAGE OVER TIME
#################################################

# Combined, Powell, and Mead on one plot

ggplot() +
  #Powell storage
  geom_line(data=dfJointStorage,aes(x=DateAsValue,y=PowellStorage, color="Powell"), size=2) +
  #Mead Storage
  geom_line(data=dfJointStorage,aes(x=DateAsValue,y=MeadStorage, color="Mead"), size=2) +
  #Combined Storage
  geom_line(data=dfJointStorage,aes(x=DateAsValue,y=MeadStorage+PowellStorage, color="Combined"), size=2) +
  scale_color_manual(values = c("purple","red","blue"), breaks=c("Combined", "Powell", "Mead")) +
  #geom_area(data=dfPlotData,aes(x=month,y=stor_maf, fill = variable), position='stack') +
  scale_y_continuous(breaks = seq(0,50,by=10),labels=seq(0,50,by=10)) +
  
  #    scale_y_continuous(breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]),labels=c(0,5.98,9.6,12.2,dfMaxStor[2,2]),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]), labels = c(895,1025,1075,1105,1218.8))) +
  #scale_x_discrete(breaks=cMonths, labels= cMonthsLabels) +
  #scale_x_continuous(breaks=seq(1960,2020,by=10), labels= seq(1960,2020,by=10)) +
  
  
  #scale_fill_manual(breaks=c(1:6),values = palBlues[2:7]) + #,labels = variable) + 
  theme_bw() +
  #coord_fixed() +
  labs(x="", y="Active Storage (MAF)", color = "Reservoir") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18))
  #theme(text = element_text(size=20), legend.text=element_text(size=16)


### Combined plot for proposal

## Read in ICS account balance data
sExcelFile <- 'IntentionallyCreatedSurplus-Summary.xlsx'
dfICSBalance <- read_excel(sExcelFile, sheet = "Sheet1",  range = "B6:G17")
nMaxYearICSData <- max(dfICSBalance$Year)
#Duplicate the largest year and set the year to largest value plus 1
dfICSBalance <- rbind(dfICSBalance, dfICSBalance %>% filter(Year == nMaxYearICSData) %>% mutate(Year = nMaxYearICSData+1))
#Order by decreasing year
dfICSBalance <- dfICSBalance[order(-dfICSBalance$Year),]
#Turn time into a index by month. Year 1 = 1, Year 2 = 13
dfICSBalance$MonthIndex <- 12*(dfICSBalance$Year - dfICSBalance$Year[nrow(dfICSBalance)]) + 12

#Turn the ICS year into monthly
dfICSmonths = expand.grid(Year = unique(dfICSBalance$Year), month = 1:12)
dfICSmonths$MonthIndex <- 12*(dfICSmonths$Year - dfICSmonths$Year[nrow(dfICSmonths)]) + dfICSmonths$month
#Filter off first year but keep last month
dfICSmonths <- dfICSmonths %>% filter(dfICSmonths$MonthIndex >= 12)
#Calculate a date
dfICSmonths$Date <- as.Date(sprintf("%d-%d-01",dfICSmonths$Year, dfICSmonths$month))


#Interpolate Lower Basin conservation account balances by Month
dfICSmonths$LowerBasinConserve <- interp1(xi = dfICSmonths$MonthIndex, x=dfICSBalance$MonthIndex, y = dfICSBalance$Total, method="linear" )
#Interpolate Mexico conservation account balance by Month
dfICSmonths$MexicoConserve <- interp1(xi = dfICSmonths$MonthIndex, x=dfICSBalance$MonthIndex, y = dfICSBalance$Mexico, method="linear" )

## Calculate the Protection elevation
dfProtectLevel <- data.frame(Reservoir = c("Powell", "Mead"), Elevation = c(3525, 1020))
#Interpolate storage from elevation
dfProtectLevel$Volume[1] <- interpNA(xi = dfProtectLevel$Elevation[1], x= dfPowellElevStor$`Elevation (ft)`, y=dfPowellElevStor$`Live Storage (ac-ft)`)
dfProtectLevel$Volume[2] <- interpNA(xi = dfProtectLevel$Elevation[2], x= dfMeadElevStor$`Elevation (ft)`, y=dfMeadElevStor$`Live Storage (ac-ft)`)

nProtectCombined <- sum(dfProtectLevel$Volume)/1e6
nCapacityCombined <- (dfMaxStor[1,2] + dfMaxStor[2,2])
nLastVolumeCombined <- dfJointStorage$PowellStorage[629] + dfJointStorage$MeadStorage[629]

#Data frame of key dates
dfKeyDates <- data.frame(Date = as.Date(c("2007-01-01", "2026-01-01")), Label = c("Interim\nGuidelines", "Guidelines\nExpire"))
#Data frame of key elevations
dfKeyVolumes <- data.frame(Volume = c(nProtectCombined, nCapacityCombined), Label = c("Protect","Combined\nCapacities"))
#Data frame of key traces
dfKeyTraceLabels <- data.frame(Label = c("Protect Mindset", "Available\nWater", "Lake Mead\nConservation\nAccounts", "Deficit Mindset"),
                                Volume = c(nProtectCombined/2, 18, 25, 40), xPosition = rep(2007 + (nMaxYearICSData - 2007)/2,4),
                                Size = c(6, 6, 5, 6))

#Adjust the x positions of the Available water and LB + MX conserved water
dfKeyTraceLabels$xPosition[2] <- 2009
dfKeyTraceLabels$xPosition[3] <- (2026 + nMaxYearICSData + 0.825 )/2
#Data frame of end arrows
nArrowOffset <- 4
dfEndArrows <- data.frame(Label = c("Recover?", "Stabilize?", "Draw down?"), Ystart = rep(nLastVolumeCombined,3), 
                            Xstart = as.Date(rep("2022-01-01",3)), Xend = as.Date(rep("2025-01-01",3)),
                            Yend = c(nLastVolumeCombined + nArrowOffset, nLastVolumeCombined, nLastVolumeCombined - nArrowOffset),
                            Angle = c(20,0,-20), Yoffset = c(0.1, 0, -0.1))
#Calculate the mid date
dfEndArrows$MidDate <- dfEndArrows$Xstart + floor((dfEndArrows$Xend - dfEndArrows$Xstart)/2)

#Left join the ICS data to the joint storage data to get the entire date range
dfJointStorage <- left_join(dfJointStorage, dfICSmonths, by=c("DateAsValue" = "Date"))
#Convert NAs to zeros
dfJointStorage$Year <- year(dfJointStorage$DateAsValue)
dfJointStorageClean <- dfJointStorage[,2:ncol(dfJointStorage)] %>% filter(Year <= nMaxYearICSData)
dfJointStorageClean[is.na(dfJointStorageClean)] <- 0
dfTemp <- dfJointStorage %>% filter(Year <= nMaxYearICSData) %>% select(DateAsValue)
dfJointStorageClean$DateAsValue <- dfTemp$DateAsValue

#Add rows for years 2022 to 2030 with all zeros
dfYearsAdd <- data.frame(Year = seq(nMaxYearICSData+1, nMaxYearICSData + 10, by = 1))
dfJointStorageZeros <- dfJointStorageClean[1,1:(ncol(dfJointStorageClean)-1)]
dfJointStorageZeros[1, ] <- 0
dfJointStorageZeros <- as.data.frame(lapply(dfJointStorageZeros,  rep, nrow(dfYearsAdd)))
dfJointStorageZeros$Year <- dfYearsAdd$Year
#Calculate a date
dfJointStorageZeros$DateAsValue <- as.Date(sprintf("%.0f-01-01", dfJointStorageZeros$Year))
#Bind to the Clean data frame
dfJointStorageClean <- rbind(dfJointStorageClean, dfJointStorageZeros)


#New data frame for area
dfJointStorageStack <- dfJointStorageClean

dfJointStorageStack$Protect <- nProtectCombined
dfJointStorageStack$LowerBasin <- ifelse(dfJointStorageStack$Year <= nMaxYearICSData, dfJointStorageStack$LowerBasinConserve/1e6, 0)
dfJointStorageStack$Mexico <- ifelse(dfJointStorageStack$Year <= nMaxYearICSData, dfJointStorageStack$MexicoConserve/1e6, 0)
dfJointStorageStack$AvailableWater <- ifelse(dfJointStorageStack$Year <= nMaxYearICSData, dfJointStorageStack$PowellStorage + dfJointStorageStack$MeadStorage - dfJointStorageStack$Protect - dfJointStorageStack$LowerBasin - dfJointStorageStack$Mexico, 0)
dfJointStorageStack$Capacity <- ifelse(dfJointStorageStack$Year <= nMaxYearICSData, nCapacityCombined - dfJointStorageStack$AvailableWater - dfJointStorageStack$Protect - dfJointStorageStack$LowerBasin - dfJointStorageStack$Mexico, 0)

#Melt the data
dfJointStorageStackMelt <- melt(dfJointStorageStack, id.vars = c("DateAsValue"), measure.vars = c("Protect","LowerBasin", "Mexico", "AvailableWater", "Capacity"))
#Specify the order of the variables
dfJointStorageStackMelt$variable <- factor(dfJointStorageStackMelt$variable, levels=c("Capacity","AvailableWater", "Mexico", "LowerBasin", "Protect"))

#Get the color palettes
#Get the blue color bar
pBlues <- brewer.pal(9,"Blues")
pReds <- brewer.pal(9,"Reds")

ggplot() +
  #Combined Storage
  #As area
  geom_area(data=dfJointStorageStackMelt, aes(x=DateAsValue, y=value, fill=variable, group=variable)) +
  #As line
  geom_line(data=dfJointStorageStack %>% filter(Year < nMaxYearICSData + 1),aes(x=DateAsValue,y=MeadStorage+PowellStorage, color="Combined"), size=2, color = "Black") +
  #geom_area(data=dfPlotData,aes(x=month,y=stor_maf, fill = variable), position='stack') +
  
  #lines for max capacity and protect elevation
  geom_hline(data=dfKeyVolumes, aes(yintercept = Volume), linetype="longdash", size=1) +
  #lines for Interim Guidelines and Expiry
  geom_vline(data=dfKeyDates, aes(xintercept = Date), linetype = "dashed", size=1, color = pReds[9]) +

  #Labels for the areas
  geom_text(data=dfKeyTraceLabels %>% filter(Label != dfKeyTraceLabels$Label[3]), aes(x=as.Date(sprintf("%.0f-01-01",xPosition)), y=Volume, label=as.character(Label)), size = 6, fontface="bold") +
  geom_text(data=dfKeyTraceLabels %>% filter(Label == dfKeyTraceLabels$Label[3]), aes(x=as.Date(sprintf("%.0f-01-01",xPosition)), y=Volume, label=as.character(Label)), size = 4.5, fontface="bold", color = pBlues[5]) +
 
  #Arrow Lake Mead conservation account label
  geom_curve(data = dfKeyTraceLabels %>% filter(Label == dfKeyTraceLabels$Label[3]), aes(x=as.Date(sprintf("%.0f-01-01",xPosition)), xend = as.Date(sprintf("%.0f-02-01",nMaxYearICSData+1)), y=20.5, yend = 13), curvature = -0.5, color = pBlues[5], size = 1.0, arrow = arrow(length = unit(0.03, "npc"))) +
  
  
  #Label what is next
  #geom_text(data = dfEndArrows %>% filter(Label == "Recover?"), aes(x= MidDate, y = Ystart, label = "Recover?\nStabilize?\nDraw down?"), size = 5, color = "Black") +
  #Label the arrows
  #geom_text(data = dfEndArrows, aes(x = Xstart, y = (Ystart+Yend)/2 + Yoffset, label = Label, angle = Angle), size = 5, color = "Black", hjust = 0) +
  
  #geom_segment(aes(x=as.Date("2022-01-01"), xend=as.Date("2025-01-01"), y=12, yend = 14, colour = palBlues[7], arrow = arrow())) +
  
  
    
  #Scales
  scale_x_date(limits= c(as.Date("1990-01-01"), as.Date("2026-01-01")), sec.axis = sec_axis(~. +0, name = "", breaks = dfKeyDates$Date, labels = as.character(dfKeyDates$Label))) +
  #scale_y_continuous(limits = c(0,NA)) +
  # secondary axis is not working
  # scale_y_continuous(limits = c(0,NA), sec_axis(~. +0, name = "", breaks = dfKeyVolumes$Volume, labels = dfKeyVolumes$Volume)) +
  #Secondary axis as percent
  scale_y_continuous(limits = c(0,NA), sec.axis = sec_axis(~ . /nCapacityCombined*100, name = "Percent of Combined Capacity", breaks = seq(0,100,by=25), labels = sprintf("%d%%", seq(0,100,by=25)))) +
  
  scale_fill_manual(values=c(pReds[3], pBlues[3], pBlues[5], pBlues[5], pBlues[7])) +
  
  #    scale_y_continuous(breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]),labels=c(0,5.98,9.6,12.2,dfMaxStor[2,2]),  sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = c(0,5.98,9.6,12.2,dfMaxStor[2,2]), labels = c(895,1025,1075,1105,1218.8))) +
  #scale_x_discrete(breaks=cMonths, labels= cMonthsLabels) +
  #scale_x_continuous(breaks=seq(1960,2020,by=10), labels= seq(1960,2020,by=10)) +
  
  
  #scale_fill_manual(breaks=c(1:6),values = palBlues[2:7]) + #,labels = variable) + 
  theme_bw() +
  #coord_fixed() +
  labs(x="", y="Combined Active Storage\n(MAF)", color = "") +
  theme(text = element_text(size=20), legend.title=element_blank(), legend.position ="none")
#theme(text = element_text(size=20), legend.text=element_text(size=16)





