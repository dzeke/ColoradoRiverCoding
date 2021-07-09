#####
#     Grand Canyon Intervening flows
#     
#     Grand Canyon intervening flows are sum of Paria, Little Colorado River, Virgin, and Powell to Virgin natural flows
#     in the USBR Natural Flow database
#
#     Produces 3 plots:
#
#       1. Box and whiskers of flow
#       2. Correlation with Lee Ferry Natural Flow
#       3. Dotty plot of Salehabadi and Tarboton (2020)
#
#
#     David E. Rosenberg
#     May 10, 2021
#     Utah State University
#     david.rosenberg@usu.edu
#
#####


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


### Read in the Natural Flow data and convert it to annual flows
sExcelFileGrandCanyonFlow <- 'HistoricalNaturalFlow.xlsx'
dfGCFlows <- read_excel(sExcelFileGrandCanyonFlow, sheet = 'Total Natural Flow',  range = "U1:Z1324")
dfGCDates <- read_excel(sExcelFileGrandCanyonFlow, sheet = 'Total Natural Flow',  range = "A1:A1324")

#Merge and combine into one Data frame
dfGCFlows$Date <- dfGCDates$`Natural Flow And Salt Calc model Object.Slot`

#Calculate Grand Canyon Tributary flows as sum of Paria, Little Colorado Riverr, Virgin, and intervening flows
#Just tribs (without intervening)
#dfGCFlows$Total <- dfGCFlows$`CoRivPowellToVirgin:PariaGains.LocalInflow` + dfGCFlows$`CoRivPowellToVirgin:LittleCoR.LocalInflow` + 
#                          dfGCFlows$VirginRiver.Inflow

#Tribs + Gains above Hoover
dfGCFlows$Total <- dfGCFlows$`CoRivPowellToVirgin:PariaGains.LocalInflow` + dfGCFlows$`CoRivPowellToVirgin:LittleCoR.LocalInflow` + 
  dfGCFlows$VirginRiver.Inflow + dfGCFlows$`CoRivVirginToMead:GainsAboveHoover.LocalInflow` - dfGCFlows$`CoRivPowellToVirgin:GainsAboveGC.LocalInflow`

dfGCFlows$Year <- year(dfGCFlows$Date)
dfGCFlows$Month <- month(as.Date(dfGCFlows$Date,"%Y-%m-%d"))
dfGCFlows$WaterYear <- ifelse(dfGCFlows$Month >= 10,dfGCFlows$Year,dfGCFlows$Year + 1)


#Convert to Water Year and sum by water year
dfGCFlowsByYear <- aggregate(dfGCFlows$Total, by=list(Category=dfGCFlows$WaterYear), FUN=sum)
dfLeeFerryByYear <- aggregate(dfGCFlows$`HistoricalNaturalFlow.AboveLeesFerry`, by=list(Category=dfGCFlows$WaterYear), FUN=sum)

#Change the Names
colnames(dfGCFlowsByYear) <- c("WaterYear","GCFlow")
colnames(dfLeeFerryByYear) <- c("WaterYear", "LeeFerryFlow")
dfGCFlowsByYear$LeeFerryFlow <- dfLeeFerryByYear$LeeFerryFlow


#### Figure 1 - Plot Grand Canyon Tributary Inflows as a box-and-whiskers
#Plot as a box-and whiskers

ggplot(dfGCFlowsByYear, aes(y=GCFlow/1e6)) +
  geom_boxplot() +
  theme_bw() +
  
  labs(x="", y="Grand Canyon Intervening Flow\n(MAF per year)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), 
        legend.position = "none",axis.text.x = element_blank(), axis.ticks = element_blank())


#Calculate the median value
vMedGCFlow <- median(dfGCFlowsByYear$GCFlow)


#### Figure 2. Show the correlation between Grand Canyon Flow and Lee Ferry Flow
#
ggplot(dfGCFlowsByYear, aes(x= LeeFerryFlow/1e6, y=GCFlow/1e6)) +
  geom_point() +
  theme_bw() +
  
  labs(x="Lee Ferry Natural Flow\n(MAF per year)", y="Grand Canyon Intervening Flows\n(MAF per year)") +
  #theme(text = element_text(size=20), legend.title=element_blank(), legend.text=element_text(size=18),
  #      legend.position = c(0.8,0.7))
  theme(text = element_text(size=20), 
        legend.position = "none")

## Show the correlation matrix
cor(dfGCFlowsByYear)

#### Figure 3. Show the sequence average plot using Salehabadi code.

############################################################################################################
###### Sequence Average Plot (Dotty Plot)                                                             ######
######  - creat the Sequence-Average plot (blue dots: full period,  red dots: post-yr period)         ######                                      
######  - Add the long term average of the flow over the full and post-yr periods as horizontal lines ######
######                                                                                                ######
######  Homa Salehabadi                                                                               ###### 
############################################################################################################

# This may not be needed if already installed.
#install.packages("openxlsx") 
library(openxlsx)

#####==================================================================================================================
##### Inputs (change them if needed) ==================================================================================

## Set working directory if necessary e.g.
# setwd("H:/Homa/PhD/Research/Works/SeqAvePlots")

##### n.lowest function: find the nth lowest value (or index) in x ====================================================

n.lowest <- function(x,n,value=TRUE){
  s <- sort(x,index.return=TRUE)
  if(value==TRUE)  {s$x[n]}  else  {s$ix[n]}    ## TRUE: n.lowest=value   FALSE: n.lowest=index
} 


# Natural Flow Plot
## Input Files ------------------------------------------------------------------------------
#filename1 <- "R_InputData.xlsx"
#sheetname1 <-  "AnnualWYTotalNaturalFlow_LF2018"    ## Natural flow: "AnnualWYTotalNaturalFlow_LF2018"   ## Tree ring: "TR_Meko_2017-SK"  

## Factor to change the current unit --------------------------------------------------------
unit_factor <- 10^(-6)   ## ac-ft to MAF

## Maximum length of sequence (sequences will be from 1 to seq_yr) --------------------------
seq_yr <- 15 ## 25

## desired period ---------------------------------------------------------------------------
yr1 <- 1905   ## NF:1906   TR:1416       
yr2 <- 2016   ## NF:2018   TR:2015    
  
## A year to devide the period into two period.  --------------------------------------------
post_year <- 2000   ## post-year will be distinguished in plot


### Pull the data into the data data frame for plotting
data <- dfGCFlowsByYear

yr1 <- min(data$WaterYear)
yr2 <- max(data$WaterYear)


#data <- read.xlsx(filename1, sheet=sheetname1, colNames=TRUE)
#data <- read.csv(file = "GrandCanyonFlows.csv", header = TRUE, sep =",", strip.white = TRUE)
years <- yr1:yr2
n <- length(years)


#### Sequence Average plot ###########################################################################################     
####   - creat the Sequence-Average plot                                                 
####   - add the long term average of the flow over the full and post-yr periods as horizontal lines
####
#### >> Check Legend if needed  

## take the flow data ------------
flow <- data[ which(data[,1]==yr1):which(data[,1]==yr2) ,(2)]

## define empty matrixes -------------
Mean<- matrix(rep(NA), nrow=n , ncol=seq_yr)
lowest <- matrix(rep(NA), nrow=n , ncol=seq_yr)
lowest_index <- matrix(rep(NA), nrow=n , ncol=seq_yr)
lowest_year <- matrix(rep(NA), nrow=n , ncol=seq_yr)

## calculate the averages over the sequences---------------
## Loop: over the defined sequences
for (m_yr in 1:seq_yr){  
  
  mean_m_yr <- rep(NA)
  sort <- rep(NA)
  
  for (m in 1:(n-(m_yr-1))){
    mean_m_yr[m] <- mean( flow[ m : (m+(m_yr-1)) ] )
    Mean[m ,m_yr] <- mean_m_yr[m]
  }
  
  for (m in 1:(n-(m_yr-1))){
    lowest[m ,m_yr] <- n.lowest( mean_m_yr,m,value=TRUE)
    lowest_index[m ,m_yr] <- n.lowest(mean_m_yr,m,value=FALSE)   
    lowest_year[m ,m_yr] <- years[lowest_index[m ,m_yr]]
  }
  
}


## change unit to MAF ----------------------
lowest_MAF <- lowest*unit_factor  

###### Plot SeqAve (dotty plots) ==========================================================================

## the final dataframe that you want its dotty plot will be SeqAve
SeqAve <- lowest_MAF

## will be used to plot with a better scale:
min <- -0.5 #floor(min(SeqAve, na.rm=TRUE))
max <- ceiling(max(SeqAve, na.rm=TRUE))

##### plot -----------------------------------------------------------
x <- c(1:seq_yr)
par(mar=c(5, 4, 3, 2) + 0.2 , mgp=c(2.5, 1, 0) )

## 1- For natural flow run this:
plot(x, SeqAve[1,], col="white", ylim=c(min, max) , xlim=c(1, seq_yr+1), xaxt="n" ,yaxt="n",
     pch=16, cex=0.6, xlab="Length of sequence (year)", ylab="Mean flow (maf)", cex.lab=1.3, 
     main=paste0("Grand Canyon Tributary Flow (Powell to Mead),  Period: " ,yr1,"-",yr2) )  ## , cex.main=1.3

### axis of the plot -------
axis(1, at=seq(1,seq_yr,1), cex.axis=1)
axis(2, at=seq((min-2),max,0.5), cex.axis=1, las=1)  ## las=1 to rotate the y lables


### plot dots and seperate them to blue and red ones ---------

## full period
for (j in 1:seq_yr){  
  for (i in 1:(n-(j-1))){  #1:n
    points(j, SeqAve[i,j], col= "lightskyblue2" ,pch=1, cex=0.5, lwd=1)
  }
}

## specify post-yr period
for (j in 1:seq_yr){  
  for (i in 1:(n-(j-1))){  #1:n
    
    if ( lowest_year[i,j]>=post_year) {
      points(j, SeqAve[i,j], col= "black" ,bg="red" ,pch=21, cex=0.7, lwd=0.2)
    }
  }
}


### add a line representing the long-term average of flow during the full period -----------
ave_all <- mean(flow)* unit_factor
abline (ave_all, 0, col="steelblue2", lwd=1.2)

### add a line representing the long-term average of flow during the post-yr period 
while(post_year<=yr2){
  ave_post <- mean(flow[(which(years==post_year) : which(years==yr2))] ) * unit_factor
  abline (ave_post, 0, col="red", lwd=1.2)
  break}


### lable the two lines of long-term average -----------
if(post_year<=yr2){
  if(ave_all>ave_post){
    text((seq_yr+0.2),(ave_all+0.3), labels= paste(round(ave_all, digits=2)), pos = 4, cex=1, col="dodgerblue3", xpd=TRUE)  ##, font=2
    text((seq_yr+0.2),(ave_post-0.4), labels= paste(round(ave_post, digits=2)), pos = 4, cex=1, col="red", xpd=TRUE)
  }
  if(ave_all<ave_post){
    text((seq_yr+0.2),(ave_all-0.4), labels= paste(round(ave_all, digits=2)), pos = 4, cex=1, col="dodgerblue3", xpd=TRUE)  ##, font=2
    text((seq_yr+0.2),(ave_post+0.4), labels= paste(round(ave_post, digits=2)), pos = 4, cex=1, col="red", xpd=TRUE)
  }
} else {
  text((seq_yr+0.2),(ave_all+0.3), labels= paste(round(ave_all, digits=2)), pos = 4, cex=1, col="dodgerblue3", xpd=TRUE)
}


### lable the first and second lowest SeqAve ----------
text(SeqAve[1,]~x, labels=lowest_year[1,], pos = 1, cex=0.6, col="black", srt=0) ## the lowest     (vertical text: srt=90)
text(SeqAve[2,]~x, labels=lowest_year[2,], pos = 2, cex=0.5, col="gray47", srt=0)  ## the second lowest


### 1- Legend for natural flow 1906-2018 -----------
legend("topright", legend=c("Full Period (1906-2018)","Post-2000 (2000-2018)", "Long term mean (1906-2018)",  "Long term mean (2000-2018)"),
       col=c("lightskyblue3","black","steelblue2","red"), pt.bg=c(NA,"red", NA,NA) , pch=c(1,21, NA, NA), pt.cex=c(0.6, 0.8),
       lwd=1,  lty=c(0,0,1,1), inset=c(0.05, 0.03), bty = "n")




  


