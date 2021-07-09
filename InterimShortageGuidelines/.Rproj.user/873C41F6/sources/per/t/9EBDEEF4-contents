# MeadDeliveryPlots.r
#
# Make plots for Interim Shortage Guidelines and Drought Contingency Plan operations versus Mead Active Storage 
#
# Mead specific:
# 1. Drought Contingency Plan (DCP) and Interim Shortage Guidelines (ISG) cutbacks versus Mead Active Storage
# 2. Drought Contingency Plan (DCP) and Interim Shortage Guidelines (ISG) deliveries versus Mead Active Storage
 
# Data is drawn from CRSS, analysis of DCP, and other sources as docummented in source Excel files (see below)
#
# Offers option to plot as specified in ISG and DCP (down to Mead 1025 ft, undefined at lower elevations) OR
#     As interpreted by CRSS (last tier continues down to Mead 895 ft, Dead pool)
#  PlotAs = "InGuidelines" or "InCRSS"
#
# Please report bugs/feedback to:
#
# David E. Rosenberg
# March 29, 2019
# Utah State University
# david.rosenberg@usu.edu

rm(list = ls())  #Clear history

PlotAs <- "InCRSS"


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

# New function interp2 to return NAs for values outside interpolation range (from https://stackoverflow.com/questions/47295879/using-interp1-in-r)
interp2 <- function(x, y, xi = x, ...) {
  yi <- rep(NA, length(xi));
  sel <- which(xi >= range(x)[1] & xi <= range(x)[2]);
  yi[sel] <- interp1(x = x, y = y, xi = xi[sel], ...);
  return(yi);
}


######### LAKE MEAD ############
#                              #
################################
# Load Data

# Lower Basin Delivery Target for CA, AZ, NV, and MX (maf per year)
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

# Read in the ISG and DCP cutbacks from Excel
dfCutbacksElev <- read_excel(sExcelFile, sheet = "Data",  range = "H21:H33") #Elevations
dfCutbacksVols <- read_excel(sExcelFile, sheet = "Data",  range = "O21:U33") #ISG and DCP for states + MX
dfCutbacksVolsFed <- read_excel(sExcelFile, sheet = "Data",  range = "Y21:Y33") # Federal cutback
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

#Culculate the storage to delivery ratio
dfCutbacks$StoDDCP <- dfCutbacks$MeadActiveVolume/dfCutbacks$DeliveryDCP
dfCutbacks$StoDISG <- dfCutbacks$MeadActiveVolume/dfCutbacks$DeliveryISG
dfCutbacks$StoDNorm <- dfCutbacks$MeadActiveVolume/dfCutbacks$DeliveryNorm

if (PlotAs=="InCRSS") { #Add a duplicate row to represent contiuation of last tier down to dead pool
  dfCutbacks <- rbind(dfCutbacks,dfCutbacks[nrow(dfCutbacks),])
  #Set the elevation in the last row to minimum
  dfCutbacks$`Mead Elevation (ft)`[nrow(dfCutbacks)] <- min(dfMeadElevStor$`Elevation (ft)`)
  # Calculate Mead Volume from Elevation (interpolate from storage-elevation curve)
  dfCutbacks$MeadActiveVolume <- interp1(xi = dfCutbacks$`Mead Elevation (ft)`,x=dfMeadElevStor$`Elevation (ft)` , y=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear")
  
}


interp1(xi = 1089.74,x=dfMeadElevStor$`Elevation (ft)`,y=dfMeadElevStor$`Live Storage (ac-ft)`, method="linear") + 8997607


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
dfPowellEqLevels$EqMeadLev <- interp2(xi = dfPowellEqLevels$Volume*1000000,x=dfMeadElevStor$`Live Storage (ac-ft)`,y=dfMeadElevStor$`Elevation (ft)`, method="linear")




dfMeadValsAdd <- data.frame(Reservoir = "Mead",
                            variable = c("Mead Flood Pool","Powell Eq. Level (2019)","DCP trigger","ISG trigger","SNWA Intake #1","Mead Eq. Tier","SNWA Intake #2","Mead Power","SNWA Intake #3"),
                            level = c(max(dfReservedFlood$Mead_level),dfPowellEqLevels$EqMeadLev[12],1090,1075,1050,1025,1000,955,860))
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
cMeadVarNames <- c("Inactive Capacity", "Mead Power", "SNWA Intake #2", "Mead Eq. Tier", "SNWA Intake #1", "DCP trigger", "Powell Eq. Level (2019)",
                  "Mead Flood Pool", "Live Capacity")
dfMeadPoolsPlot <- dfMeadAllPools %>% filter(variable %in% cMeadVarNames) %>% arrange(level)
dfMeadPoolsPlot$name <- as.character(dfMeadPoolsPlot$variable)
#Rename a few of the variable labels
dfMeadPoolsPlot[1,c("name")] <- "Dead Pool"
#dfMeadPoolsPlot[6,c("name")] <- "Flood Pool (1-Aug)"
#Create the y-axis tick label from the level and variable
#dfMeadPoolsPlot$label <- paste(round(dfMeadPoolsPlot$level,0),'\n',dfMeadPoolsPlot$name)
dfMeadPoolsPlot$label <- paste(str_replace_all(dfMeadPoolsPlot$name," ","\n"),'\n', round(dfMeadPoolsPlot$level,0))
dfMeadPoolsPlot$labelComb <- str_replace_all(dfMeadPoolsPlot$name," ","\n")
dfMeadPoolsPlot$labelComb[1] <- paste0(dfMeadPoolsPlot$labelComb[1],"s")


#Plot #1. Cutbacks versus Mead active storage
ggplot() +
  #DCP and ISG step functions
  geom_step(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=Total2007ISG/1000000, color = "ISG", linetype="ISG"), size=2, direction="vh") +
  geom_step(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=TotalDCP/1000000, color = "DCP", linetype="DCP"), size=2, direction="vh") +
  
  scale_color_manual(name="Guide1",values = c("Blue", "Red"),breaks=c("DCP", "ISG"), labels= c("Drought Contingency Plan (2019) Cutbacks", "Interim Shortage Guidelines (2008) Cutbacks")) +
  scale_linetype_manual(name="Guide1",values=c("DCP"="solid","ISG"="longdash"), breaks=c("DCP", "ISG"), labels= c("Drought Contingency Plan (2019) Cutbacks", "Interim Shortage Guidelines (2008) Cutbacks")) +
  
  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
 
  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  
  theme_bw() +
  
  labs(x="Mead Active Storage (MAF)", y="Water Volume (MAF per year)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.7,0.85))




#Plot #2. Deliveries versus Mead active storage
ggplot() +
  #DCP and ISG step functions
  geom_step(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=DeliveryISG/1000000, color = "ISG", linetype="ISG"), size=2, direction="vh") +
  geom_step(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=DeliveryDCP/1000000, color = "DCP", linetype="DCP"), size=2, direction="vh") +
  
  scale_color_manual(name="Guide1",values = c("Blue", "Red"),breaks=c("DCP", "ISG"), labels= c("Drought Contingency Plan (2019)", "Interim Shortage Guidelines (2008)")) +
  scale_linetype_manual(name="Guide1",values=c("DCP"="solid","ISG"="longdash"), breaks=c("DCP", "ISG"), labels= c("Drought Contingency Plan (2019)", "Interim Shortage Guidelines (2008)")) +
  
  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
  
  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  
  theme_bw() +
  
  labs(x="Mead Active Storage (MAF)", y="Delivery (MAF per year)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.7,0.85))

ggsave("MeadDelivery.png", width=9, height = 6.5, units="in")


# Plot 5. Storage to delivery ratio versus volume

sRatioTicks <- seq(from = 0, to = max(dfCutbacks$StoDISG), by = 0.2)

ggplot() +
  #DCP and ISG step functions
  geom_line(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=StoDISG, color = "ISG", linetype="ISG"), size=2, direction="vh") +
  geom_line(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=StoDDCP, color = "DCP", linetype="DCP"), size=2, direction="vh") +
  geom_line(data=dfCutbacks,aes(x=MeadActiveVolume/1000000,y=StoDNorm, color = "Norm", linetype="Norm"), size=2, direction="vh") +
   
  scale_color_manual(name="Guide1", values = c("Blue", "Red", "Black"), breaks=c("DCP", "ISG", "Norm"), labels= c("Drought Contingency Plan (2019)", "Interim Shortage Guidelines (2008)", "9 MAF/yr delivery (pre 2008)")) +
  scale_linetype_manual(name="Guide1", values = c("DCP"="solid","ISG"="longdash", "Norm"="twodash"), breaks=c("DCP", "ISG", "Norm"), labels= c("Drought Contingency Plan (2019)", "Interim Shortage Guidelines (2008)", "9 MAF/yr delivery (pre 2008)")) +
  
  scale_x_continuous(breaks = c(0,5,10,15,20,25),labels=c(0,5,10,15, 20,25), limits = c(0,as.numeric(dfMaxStor %>% filter(Reservoir %in% c("Mead")) %>% select(Volume))),
                     sec.axis = sec_axis(~. +0, name = "Mead Level (feet)", breaks = dfMeadPoolsPlot$stor_maf, labels = dfMeadPoolsPlot$label)) +
  #scale_y_continuous(breaks = sRatioTicks,labels=sRatioTicks, limits = c(min(sRatioTicks),max(sRatioTicks))) +

  guides(fill = guide_legend(keywidth = 1, keyheight = 1),
         linetype=guide_legend(keywidth = 3, keyheight = 1),
         colour=guide_legend(keywidth = 3, keyheight = 1)) +
  
  theme_bw() +
  
  labs(x="Mead Active Storage (MAF)", y="Active Storage Volume to Delivery Ratio\n(years to dead pool)") +
  theme(text = element_text(size=20),  legend.title = element_blank(), legend.text=element_text(size=18), legend.position = c(0.4,0.85))



