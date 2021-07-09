# TimeToDeadPool.r
#
# Calculate the time to reach the reservoir dead pool based (or some other criteria) from an initial storage and steady inflow every year. Plot
# as Time To Dead Pool (y axis) vs Reservoir storage (x-axis). Show for different release policies 
# (release as a function of storage and inflow) and reservoirs.

# Examples for a simple test case, Lake Mead, and Lake Powell.
#
# The overall governing equation is:
#   Storage_t+1 = Storage_t + Inflow - Release - Evaporation loss_t.
# We simply count the numer of iterations until Storage_ t+1 goes to zero or becomes really large.
#
# This is a scenario-based version of analysis by Barnett, T. P., and Pierce, D. W. (2008). "When will Lake Mead go dry?" Water Resources Research, 44(3). https://agupubs.onlinelibrary.wiley.com/doi/abs/10.1029/2007WR006704.
# The scenario-based analysis makes it easier to identify new release policies that are functions of storage AND inflow
# to balance supply and demand over the long term.
#
# Data is drawn from CRSS, analysis of DCP, and other sources as docummented in source Excel files (see below)
# Please report bugs/feedback to:
#
# David E. Rosenberg
# April 15, 2019
# Updated August 2, 2019
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

if (!require(ggplot2)) { 
  install.packages("ggplot2", repo="http://cran.r-project.org")
  library(ggplot2) 
}


# New function MeadInflowToPowellRelease that takes an annual Mead Inflow value and estimates the Annual Powell Release
# Simplistic relationship: just add Grand Canyon tributary inflow

#  [Lee Ferry Natural Flow]  =  [Mead Inflow]  - [0.3 to 0.8 MAF Grand Canyon Tributary inflow](numbers all very rough).

MeadInflowToPowellRelease <- function(MeadInflow,GrandCanyonTrib) {
  
  PowellRelease <- MeadInflow - GrandCanyonTrib;
  return(PowellRelease)  ;
}


# New function MeadInflowToLeeFerrylNatural that takes a Mead Inflow value and estimates a Lee Ferry Natural Flow value
# Simplistic relationship between natural flow at Lee Ferry and Mead Flow. I think this is something like:
  
#  [Lee Ferry Natural Flow]  =  [Mead Inflow]  - [0.3 to 0.8 MAF Grand Canyon Tributary inflow] + [0.6 MAF Powell Evaporation] + [4.5 MAF upper basin consumptive use] (numbers all very rough).

MeadInflowToLeeFerryNatural <- function(MeadInflow,GrandCanyonTrib,PowellEvap,UpperBasinConsumUse) {
  
  LeeFerryNatural <- MeadInflow - GrandCanyonTrib + PowellEvap + UpperBasinConsumUse;
  return(LeeFerryNatural)  ;
}



# New function interpNA to return NAs for values outside interpolation range (from https://stackoverflow.com/questions/47295879/using-interp1-in-r)
interpNA <- function(x, y, xi = x, ...) {
  yi <- rep(NA, length(xi));
  sel <- which(xi >= range(x)[1] & xi <= range(x)[2]);
  yi[sel] <- interp1(x = x, y = y, xi = xi[sel], ...);
  return(yi);
}

# New function which calculates the number of time periods to reach the reservoir's terminal state (low storage such as dead pool, high storage such top of dam)
# User provides
#   Sinit: an initial storage volume
#   inflow: steady constant inflow in each and every time step
#   delivery schedule (release as a function of...) defined by deliveryVolume and deliveryResStorage
#   sMethodRelease: the interpolation method used by interp1 for reservoir releases
#   eRate: evaporation rate in depth per year
#   reservoir bathymetry of ResArea and ResVolume
#   SminTarget: low storage target (when reached, simulation stops)
#   SmaxTarget: upper storage target (when reached, simulation stops)
#   MaxIts: maximum number of iterations before stopping
#   startYear: first year of simulation to help organize time series results
# Accounting is done using the storage balance equation sCurr_t+1 = Scurr_t + inflow - release - evaporation(sCurr_t) is done on an annual basis. 

# OUTPUTS
#   dfTimeResults - data frame of time series results including inflow and storage
#   periods - Number of periods to reach terminal state
#   finalstate - takes the value of either "Upper", "Lower", "Middle" to indicate where the final reservoir storage state is

#   
# For sMethodRelease options, see method in https://www.rdocumentation.org/packages/pracma/versions/1.9.9/topics/interp1
TimeToReservoirTarget <- function(Sinit, inflow, deliveryVolume, deliveryResStorage, sMethodRelease, eRate, 
                                  ResArea, ResVolume, sMinTarget, sMaxTarget, MaxIts, startYear) {
  #Start with zero years
  currT <- 1
  Scurr <- Sinit #Set current storage volume
  #Create empty data frame of results
  cReleases <- rep(NA,MaxIts)
  dfTimeResults <- data.frame(matrix(NA,nrow=MaxIts,ncol=5))
  names(dfTimeResults) <- c("Inflow","Year","index","Storage","Release")
  
  Smax <- min(max(ResVolume),max(deliveryResStorage),sMaxTarget) # Calculate maximum volume at which the simulation will stop. from the Bathymetry and Delivery curves and user provided SmaxTarget
  Smin <- max(min(ResVolume),min(deliveryResStorage),sMinTarget) # Calculate minimum volume at which the simulation will stop. from the Bathymetry and Delivery curves and user provided SminTarget
  
  
   while ((Scurr > Smin) && (currT <= MaxIts) && (Scurr <= Smax)){  #keep looping until storage drops to minimum threshold, storage increases to maximum threshold, or we hit the maximum number of interations
    #Record the current storage
    dfTimeResults$Storage[currT] <- Scurr
     
    #Calculate mass balance components in current time step at Scurr
    release <- interpNA(x=deliveryResStorage, y=deliveryVolume,xi = Scurr, method = sMethodRelease) # release is step function defined in the data
    evap <- eRate*interpNA(x=ResVolume, y=ResArea,xi = Scurr) # Evaporation is a linear interpolation off the reservoir bathymetry curve
    #Reservoir storage balance equation. New storage = Current Storage + Inflow - release - evaporation
    Scurr <- Scurr + inflow - release - evap
  
    cReleases[currT] <- release #Log the current release
    
    currT <- currT + 1 # Advance the time step
    
   }
  
  if (currT < MaxIts) {
    #Log the "next" storage
    #dfTimeResults$Storage[currT] <- Scurr
  }
  
  #Determine the ending storage state
  if (Scurr >= Smax) {
    sStatus <- "Top"
  } else if
   (Scurr <= Smin) {
    sStatus <- "Bottom"
  } else { sStatus <- "Middle"
  }
  
  #Further post-processing of results to turn into a time-series data from
  #Convert list to column
  dfTimeResults$Inflow <- rep(inflow, nrow(dfTimeResults))
  #Add calendar years
  dfTimeResults$Year <- seq(startYear,startYear+nrow(dfTimeResults)-1)
  #Add year index
  dfTimeResults$index <- seq(1,1+nrow(dfTimeResults)-1)
  #Convert storage as list to number
  dfTimeResults$Storage <- as.numeric(dfTimeResults$Storage)
  #Log the releases
  dfTimeResults$Release <- as.numeric(cReleases)
    
  
  ReturnList <- list("volume" = Scurr, "periods" = currT - 1, "status" = sStatus, "dfTimeResults" = dfTimeResults)
  
  return(ReturnList)
  #return(currT)
}


####  Small example to test the TimeToDeadPool function ######
#                                                            #
##############################################################
tStartVol <- 10
tMaxVol <- 15
tInflow <- 2
dfDeliverySchedule <- data.frame(release = c(2,2,5,5), stor = c(0,2,11,tMaxVol))
dfBath <- data.frame(volume = c(0,3,10,tMaxVol), area = c(1,3,5,6))
tErate <- 0.5

interpNA(x=dfDeliverySchedule$stor, y=dfDeliverySchedule$release, xi = tStartVol, method = "constant") 
interpNA(x=dfBath$volume, y=dfBath$area,xi = tStartVol)

#debug(TimeToReservoirTarget)
lTestReturn <- TimeToReservoirTarget(Sinit = tStartVol, inflow = tInflow, deliveryVolume = dfDeliverySchedule$release, 
                  deliveryResStorage = dfDeliverySchedule$stor, eRate = tErate, ResArea = dfBath$area, 
                  ResVolume = dfBath$volume, MaxIts = 50, sMethodRelease = "constant", sMinTarget = 3, sMaxTarget = 15, startYear = 2000)

#############################################################
#      Load Data for LAKE MEAD and LAKE POWELL              #
#############################################################

# Lower Basin Delivery Target for CA, AZ, NV, MX, and losses (maf per year)
vLowerBasinDeliveryTarget <- 9.6e6

###This reservoir data comes from CRSS. It was exported to Excel.

# Read elevation-storage data in from Excel
sExcelFile <- 'MeadDroughtContingencyPlan.xlsx'
dfMeadElevStor <- read_excel(sExcelFile, sheet = "Mead-Elevation-Area",  range = "A4:D676")
dfPowellElevStor <- read_excel(sExcelFile, sheet = 'Powell-Elevation-Area',  range = "A4:D689")

#Evaporation rates from CRSS
#EvapRates <- read_excel(sExcelFile, sheet = 'Data',  range = "P3:S15")
# Evaporation Rates from Schmidt et al (2016) Fill Mead First, p. 29, Table 2 - https://qcnr.usu.edu/wats/colorado_river_studies/files/documents/Fill_Mead_First_Analysis.pdf
dfEvapRates <- data.frame(Reservoir = c("Mead","Mead","Powell"),"Rate ft per year" = c(5.98,6.0, 5.73), Source = c("CRSS","FEIS-2008","Reclamation"), MinRate = c(NA,5.5,4.9), MaxRate = c(NA,6.4, 6.5))

# Define maximum storages
dfMaxStor <- data.frame(Reservoir = c("Powell","Mead"),Volume = c(24.32,25.95))


# Read in Reservoir Pools Volumes / Zones from Excel
dfPoolVols <- read_excel(sExcelFile, sheet = "Pools",  range = "D31:O43")
# Read in Reserved Flood Storage
dfReservedFlood <- read_excel(sExcelFile, sheet = "Pools",  range = "C46:E58")
#Convert dates to months
dfReservedFlood$month_num <- month(as.POSIXlt(dfReservedFlood$Month, format="%Y-%m-%Y"))

# Read in Paria, Little Colorado, and Virgin River Flows from CRSS DMI to convert Inflow to Mead to Natural Flow at Lee Ferry
sExcelFileGrandCanyonFlow <- 'HistoricalNaturalFlow.xlsx'
#dfGCFlows <- read_excel(sExcelFileGrandCanyonFlow, sheet = 'Total Natural Flow',  range = "V1:Y1324")
dfGCFlows <- read_excel(sExcelFileGrandCanyonFlow, sheet = 'Total Natural Flow',  range = "U1:Z1324")
dfGCDates <- read_excel(sExcelFileGrandCanyonFlow, sheet = 'Total Natural Flow',  range = "A1:A1324")


#Merge and combine into one Data frame
dfGCFlows$Date <- dfGCDates$`Natural Flow And Salt Calc model Object.Slot`

dfGCFlows$Year <- year(dfGCFlows$Date)
dfGCFlows$Month <- month(as.Date(dfGCFlows$Date,"%Y-%m-%d"))
dfGCFlows$WaterYear <- ifelse(dfGCFlows$Month >= 10,dfGCFlows$Year,dfGCFlows$Year - 1)


#Just tribs
#dfGCFlows$Total <- dfGCFlows$`CoRivPowellToVirgin:PariaGains.LocalInflow` + dfGCFlows$`CoRivPowellToVirgin:LittleCoR.LocalInflow` + 
#                          dfGCFlows$VirginRiver.Inflow

#Tribs + Gains above Hoover
dfGCFlows$Total <- dfGCFlows$`CoRivPowellToVirgin:PariaGains.LocalInflow` + dfGCFlows$`CoRivPowellToVirgin:LittleCoR.LocalInflow` + 
  dfGCFlows$VirginRiver.Inflow + dfGCFlows$`CoRivVirginToMead:GainsAboveHoover.LocalInflow` - dfGCFlows$`CoRivPowellToVirgin:GainsAboveGC.LocalInflow`

#Convert to Water Year and sum by water year
dfGCFlowsByYear <- aggregate(dfGCFlows$Total, by=list(Category=dfGCFlows$WaterYear), FUN=sum)
dfLeeFerryByYear <- aggregate(dfGCFlows$`HistoricalNaturalFlow.AboveLeesFerry`, by=list(Category=dfGCFlows$WaterYear), FUN=sum)

#Change the Names
colnames(dfGCFlowsByYear) <- c("WaterYear","GCFlow")
colnames(dfLeeFerryByYear) <- c("WaterYear", "LeeFerryFlow")
dfGCFlowsByYear$LeeFerryFlow <- dfLeeFerryByYear$LeeFerryFlow


#Calculate the median value
vMedGCFlow <- median(dfGCFlowsByYear$GCFlow)

# Read in the ISG and DCP cutbacks from Excel
dfCutbacksElev <- read_excel(sExcelFile, sheet = "Data",  range = "H21:H41") #Elevations
dfCutbacksVols <- read_excel(sExcelFile, sheet = "Data",  range = "O21:U41") #ISG and DCP for states + MX
dfCutbacksVolsFed <- read_excel(sExcelFile, sheet = "Data",  range = "Y21:Y41") # Federal cutback
#Merge into one data frame
dfCutbacks <- dfCutbacksElev
dfCutbacks$RowNum <- 0
dfCutbacksVols$RowNum <- 0
dfCutbacksVolsFed$RowNum <- 0
for (CurrRow in 1:nrow(dfCutbacks)) {
  dfCutbacks[CurrRow,"RowNum"] <- CurrRow
  dfCutbacksVols[CurrRow,"RowNum"] <- CurrRow
  dfCutbacksVolsFed[CurrRow,"RowNum"] <- CurrRow
}

dfCutbacks <- full_join(dfCutbacks,dfCutbacksVols)
dfCutbacks <- full_join(dfCutbacks,dfCutbacksVolsFed)

# Convert NAs to Zeros
dfCutbacks <- replace(dfCutbacks,is.na(dfCutbacks),0)

# Calculate Mead Volume from Elevation (interpolate from storage-elevation curve)
dfCutbacks$MeadActiveVolume <- interp1(xi = dfCutbacks$`Mead Elevation (ft)`,x=dfMeadElevStor$`Elevation (ft)` , y=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear")

#Calculate Total Reductions for ISG (use Federal and Mexico dating to 2012 )
dfCutbacks <- dfCutbacks %>% mutate(Total2007ISG = `Mexico Reduction (Minute 323) [2017]`+ 
                                      `2007-AZ Reduction (ac-ft)` + `2007-NV Reduction (ac-ft)` + `2007-CA Reduction (ac-ft)` +
                                     `DCP Federal Government (ac-ft)`)
#Remove federal amount at 1090 ft since IGS only starts at 1075 ft
dfCutbacks$Total2007ISG[dfCutbacks$`Mead Elevation (ft)` == 1090] <- 0

#Calculate Total Reudctions for DCP
dfCutbacks <- dfCutbacks %>% mutate(TotalDCP = `Mexico Reduction (Minute 323) [2017]`+ 
                                      `DCP-AZ Reduction (ac-ft)` + `DCP-NV Reduction (ac-ft)` + `DCP-CA Reduction (ac-ft)` +
                                      `DCP Federal Government (ac-ft)`)

#Calculate Delivers as Target - Reduction
dfCutbacks$DeliveryDCP <- vLowerBasinDeliveryTarget - dfCutbacks$TotalDCP
dfCutbacks$DeliveryISG <- vLowerBasinDeliveryTarget - dfCutbacks$Total2007ISG
dfCutbacks$DeliveryNorm <- vLowerBasinDeliveryTarget 

# Identify important Mead Levels to put as context on x-axis above the plot 
#Calculate Levels from volumes (interpolate from storage-elevation curve)
#Mead
dfMeadVals <- melt(subset(dfPoolVols,Reservoir == "Mead"),id.vars = c("Reservoir"))
dfMeadVals$level <- interp1(xi = dfMeadVals$value,x=dfMeadElevStor$`Live Storage (ac-ft)`,y=dfMeadElevStor$`Elevation (ft)`, method="linear")

#Powell
dfPowellVals <- melt(subset(dfPoolVols,Reservoir == "Powell"),id.vars = c("Reservoir"))
dfPowellVals$level <- interp1(xi = dfPowellVals$value,x=dfPowellElevStor$`Live Storage (ac-ft)`,y=dfPowellElevStor$`Elevation (ft)`, method="linear")

dfPowellVals <- melt(dfPowellVals,id.vars = c("Reservoir","variable","value","level"))
dfMeadVals <- melt(dfMeadVals,id.vars = c("Reservoir","variable","value","level"))

# Convert to MAF storage
dfMeadVals$stor_maf <- dfMeadVals$value / 1000000
dfPowellVals$stor_maf <- dfPowellVals$value / 1000000

#Calculate the volume of flood storage space reserved
dfReservedFlood$Mead_flood_stor <- dfMeadVals[2,c("stor_maf")] - dfReservedFlood$Mead
dfReservedFlood$Powell_flood_stor <- dfPowellVals[2,c("stor_maf")] - dfReservedFlood$Powell
#Calculate levels for the reserved flood volumes
dfReservedFlood$Mead_level <- interp1(xi = dfReservedFlood$Mead_flood_stor*1000000,x=dfMeadElevStor$`Live Storage (ac-ft)`,y=dfMeadElevStor$`Elevation (ft)`, method="linear")
dfReservedFlood$Powell_level <- interp1(xi = dfReservedFlood$Powell_flood_stor*1000000,x=dfPowellElevStor$`Live Storage (ac-ft)`,y=dfPowellElevStor$`Elevation (ft)`, method="linear")

# Include additional levels not in the CRSS pool data
#Specify Powell Equalization levels by Year (data values from Interim Guidelines)
dfPowellEqLevels <- data.frame(Year = c(2008:2026), Elevation = c(3636,3639,3642,3643,3645,3646,3648,3649,3651,3652,3654,3655,3657,3659,3660,3663,3663,3664,3666))
dfPowellEqLevels$Volume <- vlookup(dfPowellEqLevels$Elevation,dfPowellElevStor,result_column=2,lookup_column = 1)/1000000
#Need to convert these Powell volumes into equivalent Mead levels for the next step
dfPowellEqLevels$EqMeadLev <- interpNA(xi = dfPowellEqLevels$Volume*1000000,x=dfMeadElevStor$`Live Storage (ac-ft)`,y=dfMeadElevStor$`Elevation (ft)`, method="linear")


dfMeadValsAdd <- data.frame(Reservoir = "Mead",
                            variable = c("Flood pool","Pearce rapid","DCP trigger","ISG trigger","SNWA intake #1","DCP bottom","SNWA intake #2","Mead power","SNWA intake #3"),
                            level = c(max(dfReservedFlood$Mead_level),1135,1090,1075,1050,1025,1000,955,860))
nRowMead <- nrow(dfMeadValsAdd)
dfMeadValsAdd$value <- 0
#Interpolate live storage volume
dfMeadValsAdd$value[1:(nRowMead-1)] <- interp1(xi = dfMeadValsAdd$level[1:(nRowMead-1)],x=dfMeadElevStor$`Elevation (ft)`,y=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear")
#Add SNWA third straw which is below dead pool
dfMeadValsAdd$value[nRowMead] <- -dfMeadVals[10,3]
dfMeadValsAdd$stor_maf <- dfMeadValsAdd$value / 1000000

#Combine the original mead levels from CRSS with the levels added above
dfMeadAllPools <- rbind(dfMeadVals,dfMeadValsAdd)
#dfMeadAllPools <- dfMeadAllPools[order(dfMeadAllPools$month, dfMeadAllPools$level),]

#Pull out the desired rows
#dfMeadPoolsPlot <- dfMeadAllPools[c(3,6,7,9:13,16),]
cMeadVarNames <- c("Inactive Capacity", "Mead power", "SNWA intake #2", "DCP bottom", "SNWA intake #1", "DCP trigger", "Pearce rapid",
                  "Flood pool", "Live capacity")
dfMeadPoolsPlot <- dfMeadAllPools %>% filter(variable %in% cMeadVarNames) %>% arrange(level)
dfMeadPoolsPlot$name <- as.character(dfMeadPoolsPlot$variable)
#Rename a few of the variable labels
dfMeadPoolsPlot[1,c("name")] <- "Dead pool"
#dfMeadPoolsPlot[6,c("name")] <- "Flood Pool (1-Aug)"
#Create the y-axis tick label from the level and variable
#dfMeadPoolsPlot$label <- paste(round(dfMeadPoolsPlot$level,0),'\n',dfMeadPoolsPlot$name)
#Use label/labelComb when it's a secondary x axis
dfMeadPoolsPlot$label <- paste(str_replace_all(dfMeadPoolsPlot$name," ","\n"),'\n', round(dfMeadPoolsPlot$level,0))
dfMeadPoolsPlot$labelComb <- str_replace_all(dfMeadPoolsPlot$name," ","\n")
dfMeadPoolsPlot$labelComb[1] <- paste0(dfMeadPoolsPlot$labelComb[1],"s")
##Use labelSecY when it's a secondary y axis
dfMeadPoolsPlot$labelSecY <- paste(round(dfMeadPoolsPlot$level,0), " - ", dfMeadPoolsPlot$name)


#Assume deliveries hold constant when we go to even lower reservoir levels than defined in the DCP or ISG
#Copy the last row
dfCutbacks <- rbind(dfCutbacks, dfCutbacks %>% slice(rep(n(), each = 1)))
#Change the elevation and storage

dfCutbacks[nrow(dfCutbacks),c("Mead Elevation (ft)")] <- dfMeadAllPools %>% filter(Reservoir %in% c("Mead"), variable %in% c("Inactive Capacity")) %>%
                select(level)
dfCutbacks[nrow(dfCutbacks),"MeadActiveVolume"] <- dfMeadAllPools %>% filter(Reservoir %in% c("Mead"), variable %in% c("Inactive Capacity")) %>%
              select(stor_maf)*1000000

sReservoir <- "Mead"

#Identify the reservoir maximum active storage
tMaxVol <- as.numeric(round(dfMaxStor %>% filter(Reservoir %in% c(sReservoir)) %>% select(Volume)-0.5,0))
# CRSS value
eRateToUse <- dfEvapRates %>% filter(Reservoir %in% c(sReservoir), Source %in% c("CRSS")) %>% select(Rate.ft.per.year)
# 5-year running average from Moreo (2015)
eRateMoreo <- c(5.7,6.2,6.8)
eRateToUse <- 6.2 #I suggest that it is better to use the available 5-yr average for the latest Moreo data for Mead (6.2 ft/yr 2010-2015) 

yMax = 10
yMin = 0
dfOneToOne <- data.frame(MeadVol = c(yMin,yMax), Delivery = c(yMin,yMax))

nRows <- nrow(dfCutbacks)

### Plot #1. DCP and ISG Deliveries versus Mead active storage
ggplot() +
  #DCP and ISG step functions
  geom_step(data=dfCutbacks[1:nRows-1,],aes(x=MeadActiveVolume/1000000,y=DeliveryISG/1000000, color = "ISG", linetype="ISG"), size=2, direction="vh") +
  geom_step(data=dfCutbacks[1:nRows-1,],aes(x=MeadActiveVolume/1000000,y=DeliveryDCP/1000000, color = "DCP", linetype="DCP"), size=2, direction="vh") +
  geom_line(data=dfOneToOne,aes(x=MeadVol,y=Delivery, color="1:1",linetype="1:1"), size=1) +
  
  scale_color_manual(name="Guide1",values = c("1:1"="Black","ISG"="Blue", "DCP"="Red"),breaks=c("ISG","DCP","1:1"), labels= c("Interim Shortage Guidelines (2008)","Drought Contingency Plan (2019)","1:1" )) +
  scale_linetype_manual(name="Guide1",values=c("1:1"="dashed","ISG"="longdash","DCP"="solid"), breaks=c("ISG", "DCP","1:1"), labels= c("Interim Shortage Guidelines (2008)","Drought Contingency Plan (2019)","1:1" )) +
  
  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
  
  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  ylim(yMin,yMax) +
  theme_bw() +
  
  labs(x="Mead Active Storage (MAF)", y="Delivery (MAF per year)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.7,0.5))

ggsave("Fig1-DeliveryVsMeadStorage.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)


### Plot #1B. ISG only Deliveries versus Mead active storage
ggplot() +
  #DCP and ISG step functions
  geom_step(data=dfCutbacks[1:nRows-1,],aes(x=MeadActiveVolume/1000000,y=DeliveryISG/1000000, color = "ISG", linetype="ISG"), size=2, direction="vh") +
  #geom_step(data=dfCutbacks[1:nRows-1,],aes(x=MeadActiveVolume/1000000,y=DeliveryDCP/1000000, color = "DCP", linetype="DCP"), size=2, direction="vh") +
  geom_line(data=dfOneToOne,aes(x=MeadVol,y=Delivery, color="1:1",linetype="1:1"), size=1) +
  
  scale_color_manual(name="Guide1",values = c("1:1"="Black","ISG"="Blue"),breaks=c("ISG","1:1"), labels= c("Interim Shortage Guidelines (2008)","1:1")) +
  scale_linetype_manual(name="Guide1",values=c("1:1"="dashed","ISG"="longdash"), breaks=c("ISG", "1:1"), labels= c("Interim Shortage Guidelines (2008)","1:1" )) +
  
  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
  
  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  ylim(yMin,yMax) +
  theme_bw() +
  
  labs(x="Mead Active Storage (MAF)", y="Delivery (MAF per year)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.7,0.5))

ggsave("Fig1-ISGDeliveryVsMeadStorage.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)



### Plot #2. DCP and ISG Deliveries versus Mead active storage with Mead protection level

#Protect to bottom of DCP cutbacks
lProtectLevel <- 1025
sProtectlabel <- "1:1 Line-Protect 1,025"
#Convert to acre-feet
vProtectLevel <- interp1(xi = lProtectLevel,x=dfMeadElevStor$`Elevation (ft)` , y=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear")/1e6
# Construct a 1:1 line representing the Protection level. This line starts at (vProtectLevel,0)
dfProtectLine <- data.frame(MeadVol=c(vProtectLevel,vProtectLevel+yMax),Delivery=c(0,yMax))

ggplot() +
  #DCP and ISG step functions
  geom_step(data=dfCutbacks[1:nRows-1,],aes(x=MeadActiveVolume/1000000,y=DeliveryISG/1000000, color = "ISG", linetype="ISG"), size=2, direction="vh") +
  geom_step(data=dfCutbacks[1:nRows-1,],aes(x=MeadActiveVolume/1000000,y=DeliveryDCP/1000000, color = "DCP", linetype="DCP"), size=2, direction="vh") +
  geom_line(data=dfOneToOne,aes(x=MeadVol,y=Delivery, color="1:1 Line to Dead Pool",linetype="1:1 Line to Dead Pool"), size=1) +
  geom_line(data=dfProtectLine,aes(x=MeadVol,y=Delivery, color="1:1 Line-Protect 1,025",linetype="1:1 Line-Protect 1,025"), size=1) +
  
   
  scale_color_manual(name="Guide1",values = c("1:1 Line to Dead Pool"="Black","1:1 Line-Protect 1,025"="Grey","ISG"="Blue", "DCP"="Red"),breaks=c("ISG","DCP","1:1 Line to Dead Pool", "1:1 Line-Protect 1,025"), labels= c("Interim Shortage Guidelines (2008)","Drought Contingency Plan (2019)","1:1 Line to Dead Pool", "1:1 Line-Protect 1,025" )) +
  scale_linetype_manual(name="Guide1",values=c("1:1 Line to Dead Pool"="dashed","1:1 Line-Protect 1,025"="dashed","ISG"="longdash","DCP"="solid"), breaks=c("ISG", "DCP","1:1 Line to Dead Pool", "1:1 Line-Protect 1,025"), labels= c("Interim Shortage Guidelines (2008)","Drought Contingency Plan (2019)","1:1 Line to Dead Pool", "1:1 Line-Protect 1,025" )) +
  
  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
  
  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  ylim(yMin,yMax) +
  theme_bw() +
  
  labs(x="Mead Active Storage (MAF)", y="Delivery (MAF per year)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.7,0.5))

ggsave("Fig2-DeliveryVsMeadStorageProtect.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)


### Plot 3 - DCP Delivery vs Available Water for varying inflows. Available water is Mead Active Storage + Inflow.

# Create the data frame with deliveries as a function of mead active storage and inflow
cInflows <- c(5,6,7,8,8.5,9) #Million acre-feet per year
dfDeliveries <- dfCutbacks[, c("MeadActiveVolume", "DeliveryDCP", "DeliveryISG")]/1e6
dfDeliveries$Inflow <- 0
dfDeliveries[nrow(dfDeliveries),c("DeliveryDCP","DeliveryISG")] <- NA
dfDeliveriesInflows <- dfDeliveries
for (iFlow in cInflows){
  dfDeliveries$Inflow <- iFlow
  dfDeliveriesInflows <- rbind(dfDeliveriesInflows,dfDeliveries)
}

#Calculate available water
dfDeliveriesInflows$AvailableWater <- dfDeliveriesInflows$MeadActiveVolume + dfDeliveriesInflows$Inflow
dfDeliveriesInflows$Inflow=as.factor(dfDeliveriesInflows$Inflow)

#Get the blue color bar
pBlues <- brewer.pal(9,"Blues")

#Specify te order for traces on the plot
cBreakOrder <- c("1:1 Line to Dead Pool","1:1 Line-Protect 1,025",cInflows)
cColorVals <- c(pBlues[2],"Grey","Black",pBlues[3:9])
cLineVals <- c("solid","longdash","dashed",rep("solid",times=length(cInflows)))

## Make the plot

ggplot() + 
  geom_step(data=dfDeliveriesInflows,aes(x=AvailableWater,y=DeliveryDCP, color=Inflow, linetype=Inflow), size=2, direction="vh") +
  geom_line(data=dfOneToOne,aes(x=MeadVol,y=Delivery, color="1:1 Line to Dead Pool", linetype="1:1 Line to Dead Pool"), size=1.5) +
  geom_line(data=dfProtectLine,aes(x=MeadVol,y=Delivery, color="1:1 Line-Protect 1,025", linetype="1:1 Line-Protect 1,025"), size=1.5) +

  scale_color_manual(name="Guide1", values = cColorVals, breaks=cBreakOrder) +
  scale_linetype_manual(name="Guide1",values = cLineVals, breaks=cBreakOrder) +

  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
  
  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  ylim(yMin,yMax) +
  theme_bw() +
  
  labs(x="Available Water (Mead Active Storage + Inflow) (MAF)", y="Delivery (MAF per year)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.7,0.5))

#ggsave("Fig3-DeliveryVsAvailWater.jpg",width = 12,
#       height = 8, units = "in",
#       dpi = 300)

###############################################################################################
# RUN MEAD SIMULATIONS STARTING AT CURRENT APRIL 2019 storage WITH DIFFERNT cONSTANT INFLOWS ####
#
# Make a plot of reservoir storage (y-axis) over time. Show two zones above and below Mead 1025 ft
###############################################################################################
#Create the master dataframe of results
dfInflowSimulations <- data.frame(Storage=0, Year=0, index=0, Inflow=0, Release=0)
#Mead Initial Storage on April 9, 2019
sMeadApril2019 <- interp1(xi = 1089.74,y=dfMeadElevStor$`Live Storage (ac-ft)`,x=dfMeadElevStor$`Elevation (ft)`, method="linear")
sMeadOct2019 <- interp1(xi = 1083.05,y=dfMeadElevStor$`Live Storage (ac-ft)`,x=dfMeadElevStor$`Elevation (ft)`, method="linear")
sMeadOct2020 <- 10.1*1e6 # Oct 2020 volume ## 7.3*1e6 is long term ending storage at 9 maf per year
sMeadApril2021 <- 9.9*1e6  #April 2021 volume
sMeadStartStorage <- sMeadOct2020
sMeadDeadPool <- interp1(xi = 900,y=dfMeadElevStor$`Live Storage (ac-ft)`,x=dfMeadElevStor$`Elevation (ft)`, method="linear")

#Define start year
startYear <- 2021
#Define the maximum number of iterations. Use an even number so the inflow labels plot nicely
maxIts <- 24
#Define the evaporation rate
eRateToUse <- eRateMoreo[2]

#Loop over steady natural inflow values (stress tests)
for (tInflow in c(7, 8, 8.3, 8.6, 9, 10, 11, 12,14)*1e6){
  
    #tInflow <- 6e6
    #debug(TimeToReservoirTarget)
  
    # With lower basin delivery losses
    tRes <- TimeToReservoirTarget(Sinit = sMeadStartStorage, inflow = tInflow, deliveryVolume = dfCutbacks$DeliveryDCP, 
                                deliveryResStorage = dfCutbacks$MeadActiveVolume, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                                ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = maxIts, sMethodRelease = "constant", 
                                sMinTarget = sMeadDeadPool, sMaxTarget = tMaxVol*1e6, startYear = startYear )
  
   # Without lower basin delivery losses
    #tRes <- TimeToReservoirTarget(Sinit = sMeadApril2019, inflow = tInflow, deliveryVolume = dfCutbacks$DeliveryDCP, 
    #           deliveryResStorage = dfCutbacks$MeadActiveVolume, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
    #           ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = maxIts, sMethodRelease = "constant", 
    #              sMinTarget = 0, sMaxTarget = tMaxVol*1e6, startYear = startYear )

    #Append results to dataframe   
    dfInflowSimulations <- rbind(dfInflowSimulations, tRes$dfTimeResults)
    
}

#Remove the first dummy row of zeros
dfInflowSimulations <- dfInflowSimulations[2:nrow(dfInflowSimulations),]

# Plot up storage over time for different inflow traces.
dfTimeResults <- dfInflowSimulations    
# Calculate Steady Natural Lees Ferry Flow from Mead Inflow
# Lee Ferry Natural Flow = Mead Inflow - Grand Canyon Trib Flows + Upper Basin Demands + Powell Evaporation
ePowellRate <- dfEvapRates %>% filter(Reservoir %in% c("Powell"), Source %in% c("Reclamation")) %>% select(Rate.ft.per.year)
ePowellArea <- interp1(xi = 9e6,x=dfPowellElevStor$`Live Storage (ac-ft)` , y=dfPowellElevStor$`Area (acres)`, method="linear")

GrandCanyonTribFlows <- vMedGCFlow

vMeadInflowToLeeNaturalCorrection <- -GrandCanyonTribFlows + 4e6 + ePowellRate*ePowellArea
dfTimeResults$LeeFerryNaturalFlow <- dfTimeResults$Inflow + as.numeric(vMeadInflowToLeeNaturalCorrection )


#Calculate Powell Release from Mead Inflow
dfTimeResults$PowellRelease <- MeadInflowToPowellRelease(dfTimeResults$Inflow, GrandCanyonTribFlows)

# Select even rows for plotting flow labels
dfTimeResultsEven <- dfTimeResults[seq(4,nrow(dfTimeResults),by=4),]

## Define a polygons that identify the follow:
# 1. Level below Mead 1025 where deliveries are no longer defined by Drought Contingency Plan
# 2. Levels between Mead 1090 and 1025 where deliveries are defined by Drought COntingency Plan
# Define the polygons showing each tier to add to the plot. A polygon is defined by four points in the plot space. Lower-left, Lower-right, upper-right, upper left
# Polygon name
ids <- factor(c("Mead Releases Undefined\nStates Renegotiate","Drought Contingency Plan\nReleases"))
# Polygon corners (see above for defs)
dfPositions <- data.frame(id = rep(ids, each = 4),
                          Year = c(startYear,startYear+maxIts,startYear+maxIts,startYear,startYear,startYear+maxIts,startYear+maxIts,startYear),
                          MeadVol = c(0,0,dfMeadValsAdd$value[6],dfMeadValsAdd$value[6],dfMeadValsAdd$value[6],dfMeadValsAdd$value[6],dfMeadValsAdd$value[3],dfMeadValsAdd$value[3]))
#Number of polygons
nPts <- nrow(dfPositions)/4

#Polygon labels
dfPolyLabel <- data.frame(id = ids,
                         Label = c("Smallest DCP Releases", "Drought Contingency Plan\nReleases"),
                         DumVal = c(1:nPts))

### New PolyLabel with only one row
dfPolyLabel2 <- data.frame(id = ids[2],
                          Label = c("Drought Contingency Plan\nReleases"),
                          DumVal = c(1))
#Calculate midpoints
dfPolyLabel2$MidYear <- 0
dfPolyLabel2$MidMead <- 0
dfPolyLabel2$MidInflow <- mean(c(5,12))
point <- 1
dfPolyLabel2[point,c("MidYear")] =  0.35*min(dfPositions[(4*(point-1)+1):(4*point),c("Year")]) + 0.65*max(dfPositions[(4*(point-1)+1):(4*point),c("Year")])


#Calculate midpoints for each polygon. This is the average of the cooridinates for
# the polygon

dfPolyLabel$MidYear <- 0
dfPolyLabel$MidMead <- 0
dfPolyLabel$MidInflow <- mean(c(5,12))


for (point in 1:nPts) {
  #dfPolyLabel[point,c("MidYear")] = mean(dfPositions[(4*(point-1)+1):(4*point),c("Year")])
  #Weighted average for Year to push things to the right of the plot
  dfPolyLabel[point,c("MidYear")] =  0.35*min(dfPositions[(4*(point-1)+1):(4*point),c("Year")]) + 0.65*max(dfPositions[(4*(point-1)+1):(4*point),c("Year")])
  if (point==1) {
    dfPolyLabel[point,c("MidMead")] = mean(dfPositions[(4*(point-1)+1):(4*point),c("MeadVol")])
  } else {
    dfPolyLabel[point,c("MidMead")] = 0.35*dfPositions[(4*(point-1)+1),c("MeadVol")] + 0.65*dfPositions[(4*point),c("MeadVol")]
  }
  
}


# Currently we need to manually merge the two together
dfPolyAll <- merge(dfPolyLabel, dfPositions, by = c("id"))

#Add a variable for the annual inflow max and mins
dfPolyAll$Inflow <- c(5,12,12,5,5,12,12,5)
dfPolyAll$MidInflow <- mean(5,12)


#vertical line to show when the interim guidelines expire
tInterGuideExpire <- 2026
dfIntGuidelinesExpire <- data.frame(Year = c(tInterGuideExpire,tInterGuideExpire), MeadVol <- c(0,tMaxVol))

#Colors for the polygons
palReds <- brewer.pal(9, "Reds") #For plotting DCP tiers

#
#Now do the plot: Storage versus time with different Steady Mead inflow traces. Different DCP zones. And a vertical line showing the end of the Interim Guidelines
ggplot() +
  #Polygon zones
  geom_polygon(data = dfPolyAll, aes(x = Year, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyAll$DumVal)), show.legend = F) +
  #Inflow traces
  geom_line(data=dfTimeResults,aes(x=Year,y=Storage/1e6, group = Inflow/1e6, color = (Inflow/1e6)), size=2) +
  
  #Interim guidelines expire
  geom_line(data=dfIntGuidelinesExpire,aes(x=Year,y=MeadVol, linetype="IntGuide"), size=3,show.legend = F) +
  scale_linetype_manual(name="Guide1", values = c("IntGuide"="longdash"), breaks=c("IntGuide"), labels= c("Interim Guidelines Expire")) +
  geom_text(aes(x=tInterGuideExpire, y=25, label="Interim Guidelines\nExpire"), angle = 0, size = 7, hjust="middle") +
  #Label the plot
  #geom_label(aes(x=2037, y=20, label="Steady Inflow (MAF/year)\n(Stress Test)", fontface="bold"), angle = 0, size = 7) +
   
  #Label the constant inflow contours
  #Label inflow traces excluding non-integer traces
  geom_label(data=dfTimeResultsEven %>% filter(Inflow %in% seq(7*1e6, 14*1e6, by=1*1e6)), aes( x = Year, y = Storage/1e6, label = Inflow/1e6, fontface="bold", color = Inflow/1e6), size=5, angle = 0) + 
  #Label non integer inflow traces starting at year 8
  geom_label(data=dfTimeResultsEven %>% filter(!(Inflow %in% seq(7*1e6, 14*1e6, by=1*1e6)), index >= 8), aes( x = Year, y = Storage/1e6, label = Inflow/1e6, fontface="bold", color = Inflow/1e6), size=5, angle = 0) + 
  
  
   #Label the polygons
  geom_label(data=dfPolyLabel, aes(x = 2041, y = MidMead/1e6, label = Label, fontface="bold", fill=as.factor(dfPolyLabel$DumVal)), size=5, angle = 0) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +

  #Color scale for polygons - increasing red as go to lower levels
  #scale_fill_manual(breaks = c(2,1),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  scale_fill_manual(breaks = as.factor(dfPolyLabel$DumVal),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  
  
    
  theme_bw() +
  
  labs(x="", y="Mead Active Storage (MAF)", color =  "Natural Inflow\n(MAF/year)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18),
        legend.position = "none")

ggsave("Fig4-StorageVsTime-MeadInflow.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)

#Calculate the final Mead Elevation
dfTimeResults$Elevation <- interpNA(xi = dfTimeResults$Storage,y=dfMeadElevStor$`Elevation (ft)` , x=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear")

#############################
### Recovery Simulations
### Start at inflow simulation final points and simulate recovery for different larger inflows
#
#   There are two recovery scenarios:
#    1) Start at 2025 at 1,025 feet and look at recovery flows of 8.7 and 9 maf to stabilize Lake Mead or recover it to 1,050 feet.
#    2) Start at 2030 at 1,050 feet and look at recovery flows of 10, 11, and 12 maf each year.
#   The recovery flows can also be looked at as the lake inflow plus additional conservation beyond the DCP target
# 
#   Separate simulations are done for each scenarios and stored in separate data frames.
#   Then the two recovery data frames are plotted on the prior plot.
#############################

### Recovery case #1: From 2025 and elevation 1,025 feet.

#For each recovery case, define the key start year, start Mead storage, and inflow scenarios to use
nStartYearRecovery <- 0
dfRecoveryCases <- data.frame(startYear = rep(nStartYearRecovery,2),
                              sMeadStartStorage = c(6.0*1e6, as.numeric(dfInflowSimulations %>% filter(Year == 2030, Inflow == 9*1e6) %>% select(Storage))),
                              inflowsToUse = I(list(c(8.65, 9, 10), c(9, 10,11,12))),
                              Label = c("Recover from 1,025 ft", "Recover from 1,150 ft"))

#Initialize the results data frame
dfRecoverySimulations <- data.frame(Storage=0, Year=0, index=0, Inflow=0, Release=0, Case="", startYear=0)

#Loop over recovery cases
for (iRecovery in 1:nrow(dfRecoveryCases)){

  #Define start year
  startYear <- dfRecoveryCases$startYear[iRecovery]
  #Define the start storage
  sMeadStartStorage <- dfRecoveryCases$sMeadStartStorage[iRecovery]
  
  #Define the maximum number of iterations. Use an even number so the inflow labels plot nicely
  maxIts <- 16
  
  #Loop over steady natural inflow values (stress tests)
  for (tInflow in as.numeric(unlist(dfRecoveryCases$inflowsToUse[iRecovery]))*1e6){
    
    #tInflow <- 10e6
    #debug(TimeToReservoirTarget)
    
    # With lower basin delivery losses
    tRes <- TimeToReservoirTarget(Sinit = sMeadStartStorage, inflow = tInflow, deliveryVolume = dfCutbacks$DeliveryDCP, 
                                  deliveryResStorage = dfCutbacks$MeadActiveVolume, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                                  ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = maxIts, sMethodRelease = "constant", 
                                  sMinTarget = sMeadDeadPool, sMaxTarget = tMaxVol*1e6, startYear = startYear )
    
    # Without lower basin delivery losses
    #tRes <- TimeToReservoirTarget(Sinit = sMeadApril2019, inflow = tInflow, deliveryVolume = dfCutbacks$DeliveryDCP, 
    #           deliveryResStorage = dfCutbacks$MeadActiveVolume, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
    #           ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = maxIts, sMethodRelease = "constant", 
    #              sMinTarget = 0, sMaxTarget = tMaxVol*1e6, startYear = startYear )
    
    #Add fields to help in plotting
    tRes$dfTimeResults$Case <- dfRecoveryCases$Label[iRecovery]
    tRes$dfTimeResults$startYear <- dfRecoveryCases$startYear[iRecovery]
    
    #Append results to dataframe   
    dfRecoverySimulations <- rbind(dfRecoverySimulations, tRes$dfTimeResults)
    
  }
}

#Remove the first dummy row of zeros
dfRecoverySimulations <- dfRecoverySimulations[2:nrow(dfRecoverySimulations),]

# Plot up storage over time for different inflow traces.
dfRecoveryTimeResults <- dfRecoverySimulations  %>% filter(Year <= 2045)  

#Specify the interval in years to show line labels
nYearInterval <- 5

# Select specifc rows for plotting recovery labels
#First case is on the interval
dfRecoveryTimeResultsInterval <- dfRecoveryTimeResults %>% filter(Case == as.character(dfRecoveryCases$Label[1]) , Year %in% seq(min(dfRecoveryCases$startYear) + nYearInterval,max(dfRecoveryTimeResults$Year) - 1, by=nYearInterval))
dfTemp <- dfRecoveryTimeResults %>% filter(Case == as.character(dfRecoveryCases$Label[2]) , Year %in% seq(min(dfRecoveryCases$startYear) - 2 + nYearInterval,max(dfRecoveryTimeResults$Year) - 1, by=nYearInterval))
#Second case is one year earlier
dfRecoveryTimeResultsInterval <- rbind(dfRecoveryTimeResultsInterval, dfTemp )

#Filter out interger inflows to clean up plot compared to just inflows
dfTimeResultsInteger <- dfTimeResults %>% filter(Inflow %in% seq(7*1e6,10*1e6, by=1e6))

# Select same interval  rows for plotting flow labels
dfTimeResultsInterval <- dfTimeResults %>% filter(Year %in% seq(min(dfRecoveryCases$startYear), max(Year) - 1, by=nYearInterval))

cRecoveryColors <- c(pBlues[6], "Brown","Purple")
pPurples <-  brewer.pal(9,"Purples")
pOranges <- brewer.pal(9,"Oranges")
cRecoveryColors <- c(pPurples[9], pPurples[7],pBlues[7])
cRecoveryColors <- c(pBlues[5], pBlues[7])

#Now the recovery plot: Storage versus time with different Steady Mead inflow traces. Different DCP zones. And a vertical line showing the end of the Interim Guidelines
#Legend does not show, probably because color is not in aes#

xMax <- 15
dfPolyAll$Year2 <- ifelse(dfPolyAll$Year == 2045, xMax, dfPolyAll$Year )
dfPolyAll$Year2 <- ifelse(dfPolyAll$Year2 == 2021, nStartYearRecovery, dfPolyAll$Year2)


ggplot() +
  #Polygon zones
  geom_polygon(data = dfPolyAll, aes(x = Year2, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyAll$DumVal)), show.legend = F) +
  #Inflow trace 1
  #geom_line(data=dfTimeResultsInteger %>% filter(Inflow/1e6 == 8, Year <= 2025), aes(x=Year,y=Storage/1e6, group = Inflow/1e6), color = cRecoveryColors[1], size=2) +
  #geom_line(data=dfTimeResultsInteger %>% filter(Inflow/1e6 == 9, Year <= 2030), aes(x=Year,y=Storage/1e6, group = Inflow/1e6), color = cRecoveryColors[2], size=2) +
  
  #geom_line(data=dfTimeResultsInteger,aes(x=Year,y=Storage/1e6), color = cRecoveryColors[3], size=2) +
  
    #Recovery case 1
  geom_line(data=dfRecoveryTimeResults %>% filter(as.character(Case) == dfRecoveryCases$Label[1]), aes(x=Year,y=Storage/1e6, group = Inflow/1e6), color = cRecoveryColors[1], size=2, linetype = "dashed") +
  #Recovery case 2
  geom_line(data=dfRecoveryTimeResults %>% filter(as.character(Case) == dfRecoveryCases$Label[2]), aes(x=Year,y=Storage/1e6, group = Inflow/1e6), color = cRecoveryColors[2], size=2, linetype = "longdash") +
  
  #Interim guidelines expire
  #geom_line(data=dfIntGuidelinesExpire,aes(x=Year,y=MeadVol, linetype="IntGuide"), size=3,show.legend = F) +
  scale_linetype_manual(name="Guide1", values = c("IntGuide"="longdash"), breaks=c("IntGuide"), labels= c("Interim Guidelines Expire")) +
  #geom_text(aes(x=tInterGuideExpire, y=25, label="Interim Guidelines\nExpire"), angle = 0, size = 6, hjust="middle") +
  #Label the plot
  #geom_label(aes(x=2037, y=20, label="Steady Inflow (MAF/year)\n(Stress Test)", fontface="bold"), angle = 0, size = 7) +
  
  #Label the constant inflow contours
  #Label inflow traces excluding non-integer traces
  #geom_label(data=dfTimeResultsInterval %>% filter(Inflow == 8*1e6, Year <= 2025), aes( x = Year, y = Storage/1e6, label = Inflow/1e6, fontface="bold"),  color = cRecoveryColors[1], size=5, angle = 0) + 
  #geom_label(data=dfTimeResultsInterval %>% filter(Inflow == 9*1e6, Year < 2030), aes( x = Year, y = Storage/1e6, label = Inflow/1e6, fontface="bold"),  color = cRecoveryColors[2], size=5, angle = 0) + 
  
   #Label the recovery case 1 traces
  geom_label(data=dfRecoveryTimeResultsInterval %>% filter(Year > startYear, as.character(Case) == dfRecoveryCases$Label[1], !(Inflow/1e6 == 9 & Year == 2035)), aes( x = Year, y = Storage/1e6, label = round(Inflow/1e6, digits = 1), fontface="bold"), color=cRecoveryColors[1], size=5, angle = 0) + 
  #Label the recovery case 2 traces
  geom_label(data=dfRecoveryTimeResultsInterval %>% filter(Year > startYear, as.character(Case) == dfRecoveryCases$Label[2]), aes( x = Year, y = Storage/1e6, label = round(Inflow/1e6, digits = 1), fontface="bold"), color=cRecoveryColors[2], size=5, angle = 0) + 
  
  
  #Label the polygons
  geom_label(data=dfPolyLabel, aes(x = xMax-4, y = MidMead/1e6, label = Label, fontface="bold", fill=as.factor(dfPolyLabel$DumVal)), size=4, angle = 0) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  scale_x_continuous(limits = c(nStartYearRecovery,xMax)) +
  
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
  
  #Color scale for polygons - increasing red as go to lower levels
  #scale_fill_manual(breaks = c(2,1),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  scale_fill_manual(breaks = as.factor(dfPolyLabel$DumVal),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  
  guides(fill = "none", color = guide_legend(""), linetype = guide_legend("")) + 
  
  theme_bw() +
  
  labs(x="Year", y="Mead Active Storage (MAF)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18)) #,
        #legend.position = "none")

ggsave("Fig4b-Recovery-MeadInflow.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)


####################################################
##### Release to stabilize reservoir storage
#####
##### A stacked area plot of release vs inflow to keep reservoir storage steady
##### also shows the target, mandatory conservation target, additional conservation
########################################################

# Methods
# 1. Build a data frame for the desired reservoir levels and inflow scenarios
# 2. Calculate storage volume, evaporation, and mandatory conservation target for each storage
# 3. Calculate the release to stabilize reservoir level
# 4. Plot as area

#Step 1. Build data frame
nLowFlow <- 7

cInflowScenRecover <- c(seq(nLowFlow,14, by=0.05))*1e6

cElevations <- c(1025,1030,1045,1050,1075,1090)

nFlowScensRecover <- length(cInflowScenRecover)
nElevations <- length(cElevations)

#Create the dataframe. Pad the last column with extra values so have the same number as inflow elements
dfReleaseToStabilize <- data.frame(Elevation = c(cElevations,rep(cElevations[nElevations], nFlowScensRecover - nElevations)), Inflow = cInflowScenRecover )

#Create combinations of inflow and reservoir elevation
dfReleaseToStabilize <- dfReleaseToStabilize %>% expand(Elevation, Inflow)

#Calculate storage volume from elevation
dfReleaseToStabilize$Volume = interpNA(xi=dfReleaseToStabilize$Elevation, y=  dfMeadElevStor$`Live Storage (ac-ft)`, x=dfMeadElevStor$`Elevation (ft)`, method = "constant")
#Calculate Mandatory target from volume
dfReleaseToStabilize$MandatoryConservationTarget <- interpNA(xi= dfReleaseToStabilize$Elevation, x= dfCutbacks$`Mead Elevation (ft)`, dfCutbacks$TotalDCP, method = "constant")
#Calculate evaporation
dfReleaseToStabilize$Evaporation <- eRateToUse*interpNA(xi = dfReleaseToStabilize$Elevation, x=dfMeadElevStor$`Elevation (ft)`, y=dfMeadElevStor$`Area (acres)`, method = "constant") # Evaporation is a linear interpolation off the reservoir bathymetry curve
#Calculate the release to stabilize
dfReleaseToStabilize$ReleaseToStabilize <- dfReleaseToStabilize$Inflow - dfReleaseToStabilize$Evaporation
#Set the Delivery Target
dfReleaseToStabilize$DeliveryTarget <- vLowerBasinDeliveryTarget

#Reduce the release to stabilze if it starts crowding the DCP target
dfReleaseToStabilize$Release <- ifelse(dfReleaseToStabilize$ReleaseToStabilize > dfReleaseToStabilize$DeliveryTarget - dfReleaseToStabilize$MandatoryConservationTarget,
                                       dfReleaseToStabilize$DeliveryTarget - dfReleaseToStabilize$MandatoryConservationTarget,
                                       dfReleaseToStabilize$ReleaseToStabilize)

#Label and position the traces
dfTraceLabels <- data.frame(Elevation=c(rep(1090,3),rep(1025,3)),Inflow = c(8.5,7.5,8.5,8,7.4,8.5), Release = c(9.6-0.3/2, 8.3, 5,9.6-1.35/2,7.7,5), Label=rep(c("Mandatory conservation", "Additional\nconservation", "Release"),2))

#Calculate the additional conservation needed beyond DCP target
dfReleaseToStabilize$AdditionalConservation <- dfReleaseToStabilize$DeliveryTarget  - dfReleaseToStabilize$MandatoryConservationTarget - dfReleaseToStabilize$Release
dfReleaseToStabilize$AdditionalConservation <- ifelse(dfReleaseToStabilize$AdditionalConservation < 0, 0, dfReleaseToStabilize$AdditionalConservation)

#Melt the selected plot columns
dfReleaseToStabilizeMelt <- melt(dfReleaseToStabilize, id.vars = c("Elevation", "Volume", "Inflow"), measure.vars = c("MandatoryConservationTarget","AdditionalConservation","Release") )

#Create a data frame to right label the y-axis
dfReleaseLabels <- data.frame(Release = c(vLowerBasinDeliveryTarget,vLowerBasinDeliveryTarget - max(dfReleaseToStabilize$MandatoryConservationTarget),600000),
                                          Label = c("Target\nrelease","Max. mandatory\n conservation", "Havasu/Parker\nevap. + ET"))


ggplot(data = dfReleaseToStabilizeMelt %>% filter(Elevation %in% c("1025","1090"))) +
  #The main types
  geom_area(aes(x=Inflow/1e6, y=value/1e6, fill=variable)) +

  #Overplot a line for the line of releases to stabilize inflow
  geom_line(data=dfReleaseToStabilize %>% filter(Elevation %in% c("1025","1090")), aes(x=Inflow/1e6, y = ReleaseToStabilize/1e6), linetype = "longdash", size = 2, color = pBlues[8]) +
  #Labelthe  line of release to stabilize reservoir level
  geom_text(aes(x=8.5, y=7.8, label="Release to stabilize reservoir level"), size=5, color=pBlues[8], angle = -19) +
  #label the traces
  geom_text(data=dfTraceLabels, aes(x = Inflow, y = Release, label = Label), size=5) +
    
  facet_wrap( ~ Elevation) +
  
  #Limit the x-axis to reasonable inflows
  #xlim(7,10) +
  
  #Reverse x-axis so go from High to Low
  scale_x_reverse(limits = c(10,nLowFlow)) +
  scale_y_continuous(limits = c(0,10), breaks = seq(0,10,by=2), sec.axis = sec_axis(~. +0, name = "", breaks = dfReleaseLabels$Release/1e6, labels = dfReleaseLabels$Label)) +
  scale_fill_manual(values = c("Red","Pink", pBlues[4]), labels = c("Mandatory conservation\ntarget", "Additional conservation", "Release")) +
  
  #Add line annotations
  #Horizonal line for Havasu Parker
  geom_hline(yintercept = dfReleaseLabels$Release[3]/1e6, linetype = "dashed", size = 1.25, color = pBlues[9]) +
  #Sloped line for release to stabalize level
  #geom_abline(slope = -1, intercept =-0.4, linetype = "longdash", size = 2 ) +
  
  theme_bw() +
  
  labs(x="Inflow (MAF per year)", y="Release\n(MAF per year)", fill="") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18), legend.position = "none")
  



#PLOT 2: Reservoir releases: Storage versus time with different Steady Mead inflow traces. Different DCP zones. And a vertical line showing the end of the Interim Guidelines. Line Labels Show the reservoir release
ggplot() +
  #Polygon zones
  geom_polygon(data = dfPolyAll, aes(x = Year, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyAll$DumVal)), show.legend = F) +
  #Inflow traces
  geom_line(data=dfTimeResults,aes(x=Year,y=Storage/1e6, group = Inflow/1e6, color = (Inflow/1e6), size= (Inflow/1e6))) +
  
  #Interim guidelines expire
  geom_line(data=dfIntGuidelinesExpire,aes(x=Year,y=MeadVol, linetype="IntGuide"), size=3,show.legend = F) +
  scale_linetype_manual(name="Guide1", values = c("IntGuide"="longdash"), breaks=c("IntGuide"), labels= c("Interim Guidelines Expire")) +
  geom_text(aes(x=tInterGuideExpire, y=25, label="Interim Guidelines\nExpire"), angle = 0, size = 7, hjust="middle") +
  #geom_label(aes(x=2037, y=20, label="Release\n(MAF/year)", fontface="bold"), angle = 0, size = 7) +
  
  
  #Label the lines with release
  geom_label(data=dfTimeResultsEven , aes( x = Year, y = Storage/1e6, label = round(Release/1e6,1), fontface="bold"), size=5, angle = 0) + 
  #Label the polygons
  geom_label(data=dfPolyLabel, aes(x = MidYear, y = MidMead/1e6, label = Label, fontface="bold", fill=as.factor(dfPolyLabel$DumVal)), size=6, angle = 0) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
  
  #Color scale for polygons - increasing red as go to lower levels
  scale_fill_manual(breaks = as.factor(dfPolyLabel$DumVal),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  scale_color_continuous(low=pBlues[2],high=pBlues[9]) +
  guides(color = guide_legend("Steady Inflow\n(MAF/year)"), size = guide_legend("Steady Inflow\n(MAF/year)")) +
  
  theme_bw() +
  
  labs(x="Year", y="Mead Active Storage (MAF)") + #, color =  "Steady Inflow\n(MAF/year)", size = "Steady Inflow\n(MAF/year)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18)) #,
        #legend.position = "none")

#Another Plot of Lake Mead Release: storage versus time with different Annual Mead Release traces. Different DCP zones. And a vertical line showing the end of the Interim Guidelines
ggplot() +
  #Polygon zones
  geom_polygon(data = dfPolyAll, aes(x = Year, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyAll$DumVal)), show.legend = F) +
  #Inflow traces
  geom_line(data=dfTimeResults,aes(x=Year,y=Storage/1e6, group = PowellRelease/1e6, color = (PowellRelease/1e6)), size=2) +
  
  #Interim guidelines expire
  geom_line(data=dfIntGuidelinesExpire,aes(x=Year,y=MeadVol, linetype="IntGuide"), size=3,show.legend = F) +
  scale_linetype_manual(name="Guide1", values = c("IntGuide"="longdash"), breaks=c("IntGuide"), labels= c("Interim Guidelines Expire")) +
  geom_text(aes(x=tInterGuideExpire, y=25, label="Interim Guidelines\nExpire"), angle = 0, size = 7, hjust="middle") +
  #geom_label(aes(x=2037, y=18, label="Powell Release (MAF/year)\n= [Mead Inflow] + [0.3 MAF/year GC Tribs]", fontface="bold"), angle = 0, size = 7) +
  
  
  
  #Label the constant inflow contours
  geom_label(data=dfTimeResultsEven , aes( x = Year, y = Storage/1e6, label = round(PowellRelease/1e6,1), fontface="bold"), size=5, angle = 0) + 
  #Label the polygons
  geom_label(data=dfPolyLabel, aes(x = MidYear, y = MidMead/1e6, label = Label, fontface="bold", fill=as.factor(dfPolyLabel$DumVal)), size=6, angle = 0) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
  
  #Color scale for polygons - increasing red as go to lower levels
  scale_fill_manual(breaks = as.factor(dfPolyLabel$DumVal),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  
  
  theme_bw() +
  
  labs(x="Year", y="Mead Active Storage (MAF)", color =  "Powell Release\n(MAF/year)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18),
        legend.position = "none")

ggsave("Fig5-StorageVsTime-MeadRelease.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)


#Another Plot of Estimated Lee Ferry Natural Flow: storage versus time with different Lee Ferry Natural inflow traces. Different DCP zones. And a vertical line showing the end of the Interim Guidelines
ggplot() +
  #Polygon zones
  geom_polygon(data = dfPolyAll, aes(x = Year, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyAll$DumVal)), show.legend = F) +
  #Inflow traces
  geom_line(data=dfTimeResults,aes(x=Year,y=Storage/1e6, group = LeeFerryNaturalFlow/1e6, color = (LeeFerryNaturalFlow/1e6)), size=2) +
  
  #Interim guidelines expire
  geom_line(data=dfIntGuidelinesExpire,aes(x=Year,y=MeadVol, linetype="IntGuide"), size=3,show.legend = F) +
  scale_linetype_manual(name="Guide1", values = c("IntGuide"="longdash"), breaks=c("IntGuide"), labels= c("Interim Guidelines Expire")) +
  geom_text(aes(x=tInterGuideExpire, y=25, label="Interim Guidelines\nExpire"), angle = 0, size = 7, hjust="middle") +
  #geom_label(aes(x=2037, y=18, label="Lee Ferry Natural Flow (MAF/year)\n= [Mead Inflow] - [GC Tribs] + [Powell Evap] + [UB Consump. Use]\n= [Mead Inflow] - 0.3 + 0.46 + 4", fontface="bold"), angle = 0, size = 7) +
  
  
  
  #Label the constant inflow contours
  geom_label(data=dfTimeResultsEven , aes( x = Year, y = Storage/1e6, label = round(LeeFerryNaturalFlow/1e6,0), fontface="bold"), size=5, angle = 0) + 
  #Label the polygons
  geom_label(data=dfPolyLabel, aes(x = MidYear, y = MidMead/1e6, label = Label, fontface="bold", fill=as.factor(dfPolyLabel$DumVal)), size=6, angle = 0) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
  
  #Color scale for polygons - increasing red as go to lower levels
  scale_fill_manual(breaks = as.factor(dfPolyLabel$DumVal),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  
  
  theme_bw() +
  
  labs(x="Year", y="Mead Active Storage (MAF)", color =  "Natural Inflow\n(MAF/year)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18),
        legend.position = "none")


ggsave("Fig6-MeadStorageVsTime-LeeFerryFlow.jpg",width = 12,
       height = 8, units = "in",
       dpi = 300)



###############################################################################################
# CALCULATE Final state as a function of Steady Inflow and Initial Reservoir storage ####
#
#  Final state is either years to lower Target (e.g., Mead 1025 feet), years to Fill, or steady state volume
#
# Make a plot of inflow (x-axis), initial reservoir storage (y-axis), and time to bads
###############################################################################################
#Create the master dataframe of results
dfInflowStorageSimulations <- data.frame(InitStorage=0, Inflow=0, FinalStorage=0, Status="dummy", Year=0, index=0, Storage=0, Release=0)
maxIts <- 100

#Initial Storage scenarios (MAF)
cInitStorageScens <- seq(3,tMaxVol,by=2)*1e6
#Steady Inflow scenarios (MAF per year)
cInflowScens <- seq(4,14, by=0.5)*1e6
#Record the number of scenarios
nFlowScens <- length(cInflowScens)
nInitStorScens <- length(cInitStorageScens)

#Define DCP zone polygons
dfPolyScens <- dfPolyAll
dfPolyScens$Inflow <- c(cInflowScens[1],cInflowScens[nFlowScens],cInflowScens[nFlowScens],cInflowScens[1],cInflowScens[1],cInflowScens[nFlowScens],cInflowScens[nFlowScens],cInflowScens[1])/1e6
dfPolyScens$MidInflow <- mean(cInflowScens[1],cInflowScens[nFlowScens])/1e6


#Loop over initial storage
for (tInitStorage in cInitStorageScens) {

  #Loop over stead natural inflow values (stress tests)
  for (tInflow in cInflowScens){
    
    #tInflow <- 6e6
    #debug(TimeToReservoirTarget)
    tRes <- TimeToReservoirTarget(Sinit = tInitStorage, inflow = tInflow, deliveryVolume = dfCutbacks$DeliveryDCP, # deliveryVolume = dfCutbacks$DeliveryDCP, 
                                  deliveryResStorage = dfCutbacks$MeadActiveVolume, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                                  ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = maxIts, sMethodRelease = "constant", 
                                  #Down to 1025 ft
                                  #sMinTarget = dfMeadValsAdd$value[6], sMaxTarget = tMaxVol*1e6, startYear = startYear )
                                  #Down to Dead Pool  
                                  sMinTarget = dfMeadAllPools$value[9], sMaxTarget = tMaxVol*1e6, startYear = startYear )

    #Append results to dataframe   
    #dfTempRecord <- data.frame(InitStorage=tInitStorage, Inflow=tInflow, FinalStorage=tRes$volume, Status=tRes$status, Year=startYear+tRes$periods, index=tRes$periods, Release=tRes$dfTimeResults$Release)
    nIts <- nrow(tRes$dfTimeResults)
    dfTempRecord <- data.frame(InitStorage=rep(tInitStorage,nIts), Inflow=tRes$dfTimeResults$Inflow, FinalStorage=rep(tRes$volume,nIts), Status=rep(tRes$status,nIts), Year=tRes$dfTimeResults$Year, index=tRes$dfTimeResults$index, Storage= tRes$dfTimeResults$Storage, Release=tRes$dfTimeResults$Release)
    dfInflowStorageSimulations <- rbind(dfInflowStorageSimulations, dfTempRecord)
    
  }
}


#Remove the first dummy row of zeros
dfInflowStorageSimulations <- dfInflowStorageSimulations[2:nrow(dfInflowStorageSimulations),]

# Plot up storage over time for different inflow traces.
dfTimeInflowStorageResults <- dfInflowStorageSimulations    
# Select even rows for plotting flow labels
dfTimeInflowStorageResultsEven <- dfTimeInflowStorageResults[seq(2,nrow(dfTimeResults),by=2),]

xLabelPos <- 0.7*max(dfTimeInflowStorageResults$Inflow/1e6) # in inflow units
#Flow scale
xFlowScale <- seq(min(dfTimeInflowStorageResults$Inflow),max(dfTimeInflowStorageResults$Inflow),1e6)/1e6

#Remove rows with NA
dfTimeInflowStorageResultsNoNA <- dfTimeInflowStorageResults %>% drop_na()
#Keep the record with the largest index (time to) in each Initial Storage, Inflow, Status group
dfTimeInflowStorageResultsClean <- dfTimeInflowStorageResultsNoNA %>% 
                                      group_by(InitStorage, Inflow, FinalStorage, Status) %>%
                                      summarize(index = max(index))


#Remove duplicate rows and rows with NA
#dfTimeInflowStorageResultsClean <- dfTimeInflowStorageResults[complete.cases(dfTimeInflowStorageResults),] %>% distinct(InitStorage, Inflow, .keep_all=TRUE)

#Calculate label as either years to bottom target, years to full, or steady-state storage in maf
dfTimeInflowStorageResultsClean$Label <- ifelse(dfTimeInflowStorageResultsClean$Status == "Middle",
                                           paste(round(dfTimeInflowStorageResultsClean$FinalStorage/1e6, digits=1),'maf'),
                                           paste(dfTimeInflowStorageResultsClean$index,"yr"))

#Calculate contour value (primarily Duration) as either years to bottom target, years to full, or steady-state storage in maf
dfTimeInflowStorageResultsClean$ContourValue <- ifelse(dfTimeInflowStorageResultsClean$Status == "Middle",
                                                  round(dfTimeInflowStorageResultsClean$FinalStorage/1e6, digits=1),
                                                  dfTimeInflowStorageResultsClean$index)



#Now do the plot: X-axis is inflow, y-axis is initial storage, z-labels are time to catastrophy.
p <- ggplot() +
  #Polygon zones
  geom_polygon(data = dfPolyScens, aes(x = Inflow, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyScens$DumVal)), show.legend = F) +
  
#  geom_polygon(data = dfPolyAll, aes(x = Year, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyAll$DumVal)), show.legend = F) +
  #Inflow traces
  #geom_line(data=dfTimeInflowStorageResults,aes(x=Year,y=Storage/1e6, group = Inflow/1e6, color = (Inflow/1e6)), size=2) +
  
#  geom_text(aes(x=xLabelPos, y=23, label="Time to Mead 1025\n(Years)"), angle = 0, size = 7, hjust="middle") +

  #Plot labels that show the the numbre of years to
   
  #geom_label(data=dfTimeInflowStorageResults , aes( x = Inflow/1e6, y = InitStorage/1e6, label = round(FinalStorage/1e6,1), color = Status , size = index ,fontface="bold"),  angle = 0) + 
  #geom_label(data=dfTimeInflowStorageResults , aes( x = Inflow/1e6, y = InitStorage/1e6, label = Label, color = Status , size = 5 ,fontface="bold"),  angle = 0) + 
  geom_label(data=dfTimeInflowStorageResultsClean , aes( x = Inflow/1e6, y = InitStorage/1e6, label = Label, color = Status , size = 5 ,fontface="bold"),  angle = 0) + 
  
  #Label the polygons
  geom_label(data=dfPolyLabel[1,], aes(x = MidInflow, y = MidMead/1e6, label = Label, fontface="bold"), size=6, angle = 0) + 
  
    #Label the polygons
#  geom_label(data=dfPolyLabel, aes(x = xLabelPos, y = MidMead/1e6, label = Label, fontface="bold"), size=6, angle = 0) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  scale_x_continuous(breaks = xFlowScale, labels = xFlowScale) +
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
  
  #Color scale for polygons - increasing red as go to lower levels
  scale_fill_manual(breaks = c(2,1),values = c(palReds[5],palReds[4]),labels = dfPolyLabel$Label ) + 
  #scale_fill_manual(guide="Guide2", breaks = c("Top","Middle","Bottom"),values = c("Blue","Green","Red"),labels = c("Fill (years)","Steady volume (maf)","To 1,025 (years)" )) + 
  scale_color_manual(breaks = c("Top","Middle","Bottom"), values=c("red","green","blue"), labels=c("To Fill (years)","Steady volume (maf)","To 1,025 (years)")) +
  
  
  theme_bw() +
  
  scale_size(guide="none") +
  
  labs(x="Steady Inflow (MAF/year)", y="Mead Active Storage (MAF)", color =  "End State") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), legend.text=element_text(size=18), 
        panel.border = element_rect(colour = "black", fill=NA),
        legend.box.background = element_rect(colour = "black"),
        legend.box.margin = margin(6, 6, 6, 6),
        legend.position = c(1.125,0.85)) #,
        #legend.position = "none")

print(p)



### Plot Start Storage-Inflow results as contour plot
# y-axis: Mead active storage
# x-axis: either Steady Mead Inflow, Powell Release, or Lee Ferry Natural flow
# Contours: time to dead pool, time to fill, steady end storage

# Create a Data Frame to populate the three x-axes: Steady Mead Inflow, Powell Release, Lee Ferry Natural Flow
dfInflowAxes <- data.frame(Title = c("Steady Mead Inflow", "Powell Release", "Lee Ferry Natural Flow"),
                           TranformFromSteady = as.numeric(c(0,-GrandCanyonTribFlows ,vMeadInflowToLeeNaturalCorrection)),
                           FileName = c("MeadInflow","PowellRelease","LeeFerry"))


# plot following https://www.r-statistics.com/2016/07/using-2d-contour-plots-within-ggplot2-to-visualize-relationships-between-three-variables/

# Specify the contour intervals (years to reach target)
# See https://cran.r-project.org/web/packages/metR/vignettes/Visualization-tools.html

#Calculate inflow positions for labels of plot areas: bottom, mid, top. These are the min and max
#inflows for each group
#Remove plyr to group
detach(package:plyr)

if (!require(metR)) { 
  install.packages("metR") 
  library(metR) 
}

nRows <- nrow(dfInflowAxes)

for (i in (1:nRows)) {
  print(i)
}



# Loop over the inflow axes
for (i in (1:nRows)) {
  i <- 1
  #Print out the iteration
  print(i)
  
  #Calculate the inflow values to use
  dfTimeInflowStorageResultsClean$InflowToUse <- dfTimeInflowStorageResultsClean$Inflow + 
                                                    dfInflowAxes[i,2]

  #Calculate a convienent flow scale to use
  min(dfTimeInflowStorageResultsClean$InflowToUse/1e6,1e6)
  xFlowScaleCurr <- seq(floor(min(dfTimeInflowStorageResultsClean$InflowToUse/1e6)),ceiling(max(dfTimeInflowStorageResultsClean$InflowToUse/1e6)))
  

  #Calculate positions for the group labels
  dfStatusPositions <- dfTimeInflowStorageResultsClean %>% group_by(Status) %>% summarize(MinInflow = min(InflowToUse), MaxInflow = max(InflowToUse))
  #Add textlabels
  dfStatusPositions$Label <- c("Time to Dead Pool\n(Years)","Steady Storage\n(MAF)", "Time to Fill\n(Years)")
  dfStatusPositions$MidInflow <- (dfStatusPositions$MinInflow + dfStatusPositions$MaxInflow)/2
  
  #Use geom_contour as contour plot
 pPlot <- ggplot() +
    geom_polygon(data = dfPolyScens, aes(x = Inflow + dfInflowAxes[i,2]/1e6, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyScens$DumVal)), show.legend = F) +
    
    geom_contour(data=dfTimeInflowStorageResultsClean, aes(x=InflowToUse/1e6,y= InitStorage/1e6, z = ContourValue, color = Status), binwidth=4, size=1.5)   +
    geom_text_contour(data=dfTimeInflowStorageResultsClean, aes(x=InflowToUse/1e6,y= InitStorage/1e6, z = ContourValue), binwidth=4, size=6, check_overlap = TRUE, min.size = 5) +
    geom_label(data=dfStatusPositions, aes(x = MidInflow/1e6 , y = tMaxVol+2, label = Label, fontface="bold", color=Status), size=6, angle = 0) + 
    
    #Overplot the points
    #geom_point(data=dfTimeInflowStorageResultsClean,aes(x = InflowToUse/1e6, y = InitStorage/1e6), size=4) +
    #Label the polygons
    #  geom_label(data=dfPolyLabel, aes(x = xLabelPos, y = MidMead/1e6, label = Label, fontface="bold"), size=6, angle = 0) + 
    
    #Y-axis: Active storage on left, Elevation with labels on right 
    scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol+3), 
                       sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
    scale_x_continuous(breaks = xFlowScaleCurr, labels = xFlowScaleCurr) +
    #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
    #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
    
    #Color scale for polygons - increasing red as go to lower levels
    scale_fill_manual(breaks = c(2,1),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
    #scale_fill_manual(guide="Guide2", breaks = c("Top","Middle","Bottom"),values = c("Blue","Green","Red"),labels = c("Fill (years)","Steady volume (maf)","To 1,025 (years)" )) + 
    scale_color_manual(breaks = c("Top","Middle","Bottom"), values=c("red","purple","blue"), labels=c("To Fill (years)","Steady volume (maf)","To 1,025 (years)")) +
    
    
    theme_bw() +
    
    scale_size(guide="none") +
    
    labs(x=paste(dfInflowAxes[i,1]," (MAF per year)"), y="Mead Active Storage (MAF)") +
    #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
    #      legend.position = c(0.8,0.7))
    theme(text = element_text(size=20), 
          legend.position = "none")
 
    print(pPlot)
    
    sFigNum <- paste("Fig",i+6,"-InflowDurationStorage",sep="")
    sFigName <- paste(sFigNum,dfInflowAxes[i,3],sep="")
    
    ggsave(paste(sFigName,".jpg"),width = 12,
           height = 7.5, units = "in",
           dpi = 300)
 
  # End Loop over axes
}


### Plot Inflow-Duration results as contour plot
# y-axis: Duration (years)
# x-axis: either Steady Mead Inflow, Powell Release, or Lee Ferry Natural flow
# Contours: Initial starting reservoir storage


pPlotStor <- seq(1,nRows,by=1)

# Loop over the inflow axes
#for (i in (1:nRows)) {
  i <- 1
  #Print out the iteration
  print(i)
  
  #Calculate the inflow values to use
  dfTimeInflowStorageResultsClean$InflowToUse <- dfTimeInflowStorageResultsClean$Inflow + 
    dfInflowAxes[i,2]
  
  #Remove steady storage values and duplicates
  #dfResults <- dfTimeInflowStorageResultsClean %>% filter(Status == "Bottom" | Status == "Top") %>% group_by(Status,InflowToUse,ContourValue) %>%
  #          distinct(Status, InflowToUse, ContourValue, .keep_all = TRUE)
  
  #Keep middle status, remove duplicates
  # dfResults <- dfTimeInflowStorageResultsClean %>% filter(Status == "Middle") %>% group_by(Status,InflowToUse,ContourValue) %>%
  #          distinct(Status, InflowToUse, ContourValue, .keep_all = TRUE)

  #Remove the duplicates
  dfResults <- dfTimeInflowStorageResultsClean %>% group_by(Status,InflowToUse,ContourValue) %>%
    distinct(Status, InflowToUse, ContourValue, .keep_all = TRUE)
  
  #Filter out the duplicate records
  dfResults <- dfResults %>% distinct(ContourValue, InflowToUse, .keep_all=TRUE)
  
  #Rename the ContourValue the columns so it is easier to work with
  #Calculate contour value (primarily Duration) as either years to bottom target, years to full, or steady-state storage in maf
  dfResults$Duration <- dfResults$ContourValue
  #Calculate a new z column that is start storage for the Bottom and Top status. And is the end storage
  # for the Middle status
  dfResults$zStorage <- ifelse(dfResults$Status == "Middle",round(dfResults$FinalStorage, digits=1),
                                                         dfResults$InitStorage)/1e6
  
  
  #Calculate a convienent flow scale to use
  min(dfResults$InflowToUse/1e6,1e6)
  xFlowScaleCurr <- seq(floor(min(dfResults$InflowToUse/1e6)),ceiling(max(dfResults$InflowToUse/1e6)))
  MaxDuration <- max(dfResults$Duration)
  
  #Calculate positions for the group labels
  dfStatusPositionsStor <- dfResults %>% group_by(Status) %>% summarize(MinInflow = min(InflowToUse), MaxInflow = max(InflowToUse))
  #Add textlabels
  cStatusLabels <- c("To Dead Pool\n(Start storage [MCM])","Steady Storage\n(MCM)", "To Fill\n(Start storage [MCM])")
  dfStatusPositionsStor$Label <- cStatusLabels
  dfStatusPositionsStor$MidInflow <- (dfStatusPositionsStor$MinInflow + dfStatusPositionsStor$MaxInflow)/2
  
  #Redo the middle data as vertical lines from low to high
  dfResultsMid <- dfResults %>% filter(Status == "Middle")
  dfResultsMid <- dfResultsMid %>% group_by(InflowToUse) %>% summarize(zStorage = mean(zStorage))
  dfResultsMid$Duration <- 1
  
  dfResultsMidAdd <- data.frame(InflowToUse = rep(dfResultsMid$InflowToUse,3), 
                                Duration = c(rep(MaxDuration/2,nrow(dfResultsMid)),rep(MaxDuration,nrow(dfResultsMid)),rep(NA,nrow(dfResultsMid))), 
                                zStorage = rep(dfResultsMid$zStorage,3))
  #Bind the dataframes together
  dfResultsMid <- rbind(dfResultsMid,dfResultsMidAdd)
  dfResultsMid$Status <- "Middle"
  
  #Exclude the middle category
  dfResults <- dfResults %>% filter(Status != "Middle") 
  
  #Use geom_contour as contour plot
  # Plot strategy: dfResults is for Bottom and Top
  #                dfResultsMid is for Middle
  pPlotStor <- ggplot() +
    #geom_polygon(data = dfPolyScens, aes(x = Inflow + dfInflowAxes[i,2]/1e6, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyScens$DumVal)), show.legend = F) +
    
    #Plot the Bottom/Top groups as contours
    geom_contour(data=dfResults, aes(x=InflowToUse/1e6, y= Duration, z = zStorage, color = Status), binwidth=4, size=1.5)   +
    geom_text_contour(data=dfResults, aes(x=InflowToUse/1e6, y= Duration, z = zStorage), binwidth=4, size=6, check_overlap = TRUE, min.size = 5) +
    geom_label(data=dfStatusPositionsStor, aes(x = MidInflow/1e6 , y = MaxDuration+2, label = Label, fontface="bold", color=Status), size=6, angle = 0) + 
 
    #Plot the Middle groups as contours
    #geom_contour(data=dfResultsMid, aes(x=InflowToUse/1e6, y= Duration, z = zStorage, color = Status), binwidth=4, size=1.5)   +
    #geom_text_contour(data=dfResultsMid, aes(x=InflowToUse/1e6, y= Duration, z = zStorage), binwidth=4, size=6, check_overlap = TRUE, min.size = 5) +
    geom_line(data=dfResultsMid, aes(x=InflowToUse/1e6,y=Duration, color = Status), size=1.5) +
    geom_label(data = dfResultsMid %>% filter(Duration==MaxDuration/2), aes(x=InflowToUse/1e6, y=Duration, label = sprintf("%.1f",zStorage), size=5),angle=0) +
  
       
    #Overplot the data points
    #geom_point(data=dfResultsMid, aes(x=InflowToUse/1e6, y= Duration), color="Black", size = 5) +
    #Label the polygons
    #  geom_label(data=dfPolyLabel, aes(x = xLabelPos, y = MidMead/1e6, label = Label, fontface="bold"), size=6, angle = 0) + 
    
    #Y-axis: Active storage on left, Elevation with labels on right 
    scale_y_continuous(breaks = seq(0,MaxDuration,by=5), labels = seq(0,MaxDuration,by=5), limits = c(0, MaxDuration+3)) + 
                      # sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
    scale_x_continuous(breaks = xFlowScaleCurr, labels = xFlowScaleCurr) +
    #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
    #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
    
    #Color scale for polygons - increasing red as go to lower levels
    #scale_fill_manual(breaks = c(2,1),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
    scale_fill_manual(guide="Guide2", breaks = c("Top","Middle","Bottom"),values = c("Blue","Green","Red"),labels = c("Fill (years)","Steady volume (maf)","To 1,025 (years)" )) + 
    scale_color_manual(breaks = c("Top","Middle","Bottom"), values=c("red","purple","blue"), labels=c("To Fill (years)","Steady volume (maf)","To 1,025 (years)")) +
    
    
    theme_bw() +
    
    scale_size(guide="none") +
    
    labs(x=paste(dfInflowAxes[i,1]," (MAF per year)"), y="Duration (years)") +
    #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
    #      legend.position = c(0.8,0.7))
    theme(text = element_text(size=20), 
          legend.position = "none")
  
  print(pPlotStor)
  
  sFigNum <- paste("Fig",i+6,"-FlowDurationStorage",sep="")
  sFigName <- paste(sFigNum,dfInflowAxes[i,3],sep="")
  
  ggsave(paste(sFigName,".jpg"),width = 12,
         height = 7.5, units = "in",
         dpi = 300)
  
  # End Loop over axes
#}

### Dummy contour plot for vertical data
  dfDummyVertical <- data.frame(InflowToUse = rep(seq(8.5,10.5,by=0.5),3), 
                                Duration = c(rep(1,5),rep(10,5),rep(25,5)), 
                                zStorage = rep(seq(6,14,by=2),3))
  relBreaks <- seq(6,14,by=2)
  
  ggplot(dfDummyVertical, aes(x=InflowToUse, y= Duration, z = zStorage)) +
    #geom_polygon(data = dfPolyScens, aes(x = Inflow + dfInflowAxes[i,2]/1e6, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyScens$DumVal)), show.legend = F) +
    
    geom_contour2( colour = "black", size=0.75, breaks = relBreaks)   +
    #Label contour lines (This is not working very well)
    #metR::geom_text_contour(aes(label=..level..),size=6, check_overlap = TRUE, parse = TRUE) +
    #geom_dl(aes(label=..level..),method=list("angled.boxes", cex=2), stat="contour", breaks = relBreaks, na.rm = TRUE) +
    #geom_dl(aes(label=dfDummyVertical$zStorage),method=list("angled.boxes", cex=2), stat="contour", breaks = relBreaks) +
    
        #Overplot the data points
    #geom_point( color="Black", size = 5) +
    geom_label(data = dfDummyVertical %>% filter(Duration==10), aes(x=InflowToUse, y=Duration, label = zStorage, size=5),angle=0)
   
    
  
  
    #geom_contour(data=dfDummyVertical, aes(x=InflowToUse, y= Duration, z = zStorage), binwidth=2, size=1.5)   +
    #geom_text_contour(data=dfDummyVertical, aes(x=InflowToUse, y= Duration, z = zStorage), binwidth=2, size=6, check_overlap = TRUE, min.size = 5) +

    #Overplot the data points
    #geom_point(data=dfDummyVertical, aes(x=InflowToUse, y= Duration), color="Black", size = 5)
    


### Lee Ferry Flow plot with paleo events marked

# Read in the paleo flow data from Excel
sPaleoFile <- 'DroughtDurations.xlsx'
dfPaleoEvents <- read_excel(sPaleoFile, sheet = "Sheet1",  range = "A4:E18")

#Order the data frame by Flow
dfPaleoEvents <- dfPaleoEvents[order(dfPaleoEvents$`Average Flow (maf)`),]
dfPaleoEvents$YearRange <- paste(dfPaleoEvents$`Start Year`," to ",dfPaleoEvents$`End Year`)

dfDurations <- dfTimeInflowStorageResultsClean %>% filter(Status == "Bottom")
cLeeFlows <- unique(sort(dfDurations$InflowToUse))
cDurs <- unique(sort(dfDurations$index))
nDurs <- length(cDurs)
nLeeFlows <- length(cLeeFlows)


#Create a matrix of the storages for a particular Flow and Duration
mStors <- matrix(0, nrow = nLeeFlows, ncol = nDurs)

#Assign the right values to mgridStors
for (i in (1:nLeeFlows)) {
  iFlow <- cFlows[i]
  for (j in (1:nDurs)) {
    iDur <- cDurs[j]
    dfTempRecord <- dfDurations %>% filter(InflowToUse == iFlow, index == iDur)
    mStors[i,j] <- ifelse(nrow(dfTempRecord)==0,tMaxVol*1e6,dfTempRecord$InitStorage)
  }
}

#Loop through the Paleo events and interpolate a storage for the specified flow and duration
dfPaleoEvents$InitStor <- interp2(x=cDurs, y=cLeeFlows, Z = mStors/1e6, xp=dfPaleoEvents$`Length (years)`, yp=dfPaleoEvents$`Average Flow (maf)`*1e6, "linear")

## Draw the plot
# Rebring the code and integrate points/labels earlier
# Only use start year
# For events with start-storage larger than 25 MAF or greater than 12.3 MAF per year inflow, plot at 
#     top as second y axis
library(ggrepel)
## Add another layer to the plot which is the points
pPlot <- pPlot +
          geom_point(data=dfPaleoEvents, aes(x=`Average Flow (maf)`, y=InitStor), size=5) +
          geom_text_repel(data=dfPaleoEvents, aes(x=`Average Flow (maf)`, y=InitStor, label=dfPaleoEvents$YearRange), size = 5)

print(pPlot)

############################################################
##
## What steady reservoir releases over a specified number of years will keep the reservoir above a target storage level given a steady inflow and starting storage?
##
#########################################

#Define the function to calculate
SteadyRelease <- function(StartStorage,TargetStorage,SteadyInflow,NumYears,eRate,ResArea,ResVolume,StorageErrorCrit) {
  #StartStorage = starting reservoir storage volume
  #TargetStorage = target reservoir storage volume
  #SteadyInflow = steady inflow volume each and every year
  #NumYears = Number of years to reach the storage target
  #eRate = evaporation rate in length/year
  #ResArea = reservoir area from bathymetry curve
  #ResVolume = reservoir volume from bathymetry curve
  #StorageErrorCrit = the storage volume error criteria. When the difference between the simulated final reservoir storage value
  #       obtained with the steady release and the target storage falls below this criteria, the routine will
  #       stop iterating to find a new steady release value.
  
  #The guiding formula is:
  #     [Storage Target] = [Start Storage] + [Num Years] * ([Inflow] - [Release] - [Evaporation])
  # Solving for Release and noting Evaporation is an average of evaporation in Year 1, Year 2, ..., Year n
  #     [Release] = [Inflow] - (Evap_1 + Evap_2 + ... + Evap_n - [Storage Target] + [Start Storage])/[Num Years]
  
  # Calculate evaporation volumes in each year as a linear interpolation off the reservoir bathymetry curve from
  # each expected reservoir storage volume
  # Expected storage volumes
  sVols <- seq(StartStorage,TargetStorage,by=(TargetStorage-StartStorage)/NumYears)
  #evaporation volumes
  evaps <- eRate*interpNA(x=ResVolume, y=ResArea,xi = sVols)
  
  #print(sVols)
  #print(evaps)
  
  #Now calculate the steady annual release. Two vresions. One when Start and Target Storage are above 
  #The critical threshold. A second when they are below (no change in storage, steady storage)
  if (abs(StartStorage - TargetStorage) > StorageErrorCrit) {
      #When Start and Target storage are different
      CurrSteadyRelease <- SteadyInflow - (sum(evaps) - StartStorage + TargetStorage) / NumYears
  } else {
      #When start storage and target storage are numerically the same
      CurrSteadyRelease <- SteadyInflow - evaps[1]
  }
  
  #print(CurrSteadyRelease)
  
  maxVol = max(ResVolume) #Maximum volume of reservoir
  
  #Simulate the steady release, determine the actual ending storage, and check for differences
  #between the simulated storage and target storage that are larger than the StorageErrorCrit
  #If the error is above the StorageErrorCrit iterate to reduce the difference below the StorageErrorCritSet the initial
  #Start the difference above the StorageErrorCrit so we enter the while loop at least once 

  StorageDifference <- StorageErrorCrit + 1
  
  while(StorageDifference > StorageErrorCrit) {
    
    #Simulate the current steady release
    tSimTime <- TimeToReservoirTarget(Sinit = StartStorage, inflow = SteadyInflow, deliveryVolume = rep(CurrSteadyRelease,2), 
                                      deliveryResStorage = c(0,maxVol), eRate = eRateToUse, ResArea = ResArea, 
                                      ResVolume = ResVolume, MaxIts = NumYears+1, sMethodRelease = "constant", sMinTarget = 0, sMaxTarget = maxVol, startYear = 0)
    #Pull out the ending storage
    SimStorage <- tSimTime$dfTimeResults$Storage[NumYears+1]
    #Calculate the difference between the simulated storage and the target storage
    StorageDifference <- abs(SimStorage - TargetStorage)
    
    #print(StorageDifference)

    if (StorageDifference > StorageErrorCrit) {
      #Adjust the Steady Releaset
      CurrSteadyRelease <- CurrSteadyRelease + (SimStorage - TargetStorage) / (NumYears)
      }
    }
  
  SteadyRelease <- CurrSteadyRelease
  
  }

#Test the function
#Case 1: Decline to target
tReleaseTest <- SteadyRelease(StartStorage = 10e6, TargetStorage = 5e6, NumYears = 5, SteadyInflow = 8e6, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                          ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, StorageErrorCrit = 10000)

#Case 2: Increase to target
tReleaseTest <- SteadyRelease(StartStorage = 5e6, TargetStorage = 10e6, NumYears = 3, SteadyInflow = 8e6, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                              ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, StorageErrorCrit = 10000)


#Simulate the steady release to check
tTimeTo <- TimeToReservoirTarget(Sinit = 5e6, inflow = 8e6, deliveryVolume = rep(tReleaseTest,2), 
                                     deliveryResStorage = c(0,25e6), eRate = eRateToUse, ResArea = dfMeadElevStor$`Area (acres)`, 
                                     ResVolume =dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = 50, sMethodRelease = "constant", sMinTarget = 0, sMaxTarget = 25e6, startYear = 2020)
#Calculate the difference between the simulated storage and target storage
tTimeTo$dfTimeResults$Storage[4] - 10e6

##Another test with 1, 1, 5, 4e6

tReleaseTest <- SteadyRelease(StartStorage = 1e6, TargetStorage = 1e6, NumYears = 3, SteadyInflow = 4e6, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                              ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, StorageErrorCrit = 10000)


tTimeTo <- TimeToReservoirTarget(Sinit = 1e6, inflow = 4e6, deliveryVolume = rep(3.770e6,2), 
                                 deliveryResStorage = c(0,25e6), eRate = eRateToUse, ResArea = dfMeadElevStor$`Area (acres)`, 
                                 ResVolume =dfMeadElevStor$`Live Storage (ac-ft)`, MaxIts = 50, sMethodRelease = "constant", sMinTarget = 0, sMaxTarget = 25e6, startYear = 2020)

tTimeTo$dfTimeResults$Storage

### Let's simulate for a large number of scenarios of Initial Storage, Storage Targets, Inflow Scenarios, and Years to reaach the target
#Create the master dataframe of results
dfReleaseSimulations <- data.frame(StartStorage=0, StorageTarget=0, Inflow = 0, Years=0, Release=0)

#Initial Storage scenarios (MAF)
cInitStorageScens <- seq(1,tMaxVol,by=2)*1e6
#Storage targets
cStorageTargets <- seq(1, 15, by=1)*1e6
#Steady Inflow scenarios (MAF per year)
cInflowScens <- seq(4,14, by=1)*1e6
#Years to Target Storage
cYearsToTarget <- seq(1,10, by=1)
#Record the number of scenarios
nFlowScens <- length(cInflowScens)
nInitStorScens <- length(cInitStorageScens)
nYearsToTarget <- length(cYearsToTarget)

#Loop over initial storage values
for (tInitStorage in cInitStorageScens) {
  
  print(tInitStorage)
  
  #Loop over target storage values
  for (tStorageTarget in cStorageTargets) {
    
    #Loop over number of years to reach target
    for (tNumYears in cYearsToTarget) {
  
      #Loop over steady natural inflow values (stress tests)
      for (tInflow in cInflowScens){
        
        paste(tInitStorage, tStorageTarget, tNumYears,tInflow, sep=" ")
        
        tRelease <- SteadyRelease(StartStorage = tInitStorage, TargetStorage = tStorageTarget, NumYears = tNumYears, SteadyInflow = tInflow, eRate = eRateToUse,  ResArea = dfMeadElevStor$`Area (acres)`, 
                                      ResVolume = dfMeadElevStor$`Live Storage (ac-ft)`, StorageErrorCrit = 10000)
 
        dfTempRecord <- data.frame(StartStorage=tInitStorage, StorageTarget=tStorageTarget, Inflow = tInflow, Years=tNumYears, Release=tRelease)
        dfReleaseSimulations <- rbind(dfReleaseSimulations, dfTempRecord)
        }
    }
  }
}




#Plot as a contour plot of x= steady inflow, y = storage, a horizonal line of the storage target, and contours of release
#Select a target that is the elevation 1025
targetStorageVal <- 8e6 #dfMeadPoolsPlot$stor_maf[4]
YearToUse <- 3

ggplot() +
  geom_polygon(data = dfPolyScens, aes(x = Inflow + dfInflowAxes[i,2]/1e6, y = MeadVol/1e6, group = id, fill = as.factor(dfPolyScens$DumVal)), show.legend = F) +
  
  geom_contour(data=dfReleaseSimulations %>% filter(StorageTarget == targetStorageVal, Years == YearToUse), aes(x=Inflow/1e6,y= StartStorage/1e6, z = Release/1e6), binwidth=2, size=1.5)   +
  geom_text_contour(data=dfReleaseSimulations %>% filter(StorageTarget == targetStorageVal, Years == YearToUse), aes(x=Inflow/1e6,y= StartStorage/1e6, z = Release/1e6), binwidth=2, size=6, check_overlap = TRUE, min.size = 5) +
  #geom_label(data=dfStatusPositions, aes(x = MidInflow/1e6 , y = tMaxVol+2, label = Label, fontface="bold", color=Status), size=6, angle = 0) + 
  
  #Label the releases
  #geom_label(data=dfReleaseSimulations %>% filter(StorageTarget == targetStorageVal, Years == YearToUse), aes(x=Inflow/1e6,y= StartStorage/1e6, label = round(Release/1e6)), binwidth=4, size=6)   +
  
  
  
  #Add a horizontal line for the storage target
  geom_hline(yintercept = targetStorageVal/1e6, size = 2) + 
  
  #Y-axis: Active storage on left, Elevation with labels on right 
  scale_y_continuous(breaks = seq(0,tMaxVol,by=5), labels = seq(0,tMaxVol,by=5), limits = c(0, tMaxVol+3), 
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$labelSecY)) +
  scale_x_continuous(breaks = xFlowScaleCurr, labels = xFlowScaleCurr) +
  #limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
  #scale_y_continuous(breaks = seq(0,50,by=10), labels = seq(0,50,by=10), limits = c(0, 50)) +
  
  #Color scale for polygons - increasing red as go to lower levels
  scale_fill_manual(breaks = c(2,1),values = c(palReds[3],palReds[2]),labels = dfPolyLabel$Label ) + 
  #scale_fill_manual(guide="Guide2", breaks = c("Top","Middle","Bottom"),values = c("Blue","Green","Red"),labels = c("Fill (years)","Steady volume (maf)","To 1,025 (years)" )) + 
  scale_color_manual(breaks = c("Top","Middle","Bottom"), values=c("red","purple","blue"), labels=c("To Fill (years)","Steady volume (maf)","To 1,025 (years)")) +
  
  
  theme_bw() +
  
  scale_size(guide="none") +
  
  labs(x=paste(dfInflowAxes[i,1]," (MAF per year)"), y="Mead Active Storage (MAF)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), 
        legend.position = "none")



