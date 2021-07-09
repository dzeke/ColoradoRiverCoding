
############################################################################################################
###### Cumulative Flow Loss Plot (Dotty Plot)                                                         ######
######  - creat the Cumulative Flow Loss plot (blue dots: full period,  red dots: post-yr period)     ######                                      
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

## Input Files ------------------------------------------------------------------------------
filename1 <- "R_InputData.xlsx"

##### n.lowest function: find the nth lowest value (or index) in x ====================================================

n.lowest <- function(x,n,value=TRUE){
  s <- sort(x,index.return=TRUE)
  if(value==TRUE)  {s$x[n]}  else  {s$ix[n]}    ## TRUE: n.lowest=value   FALSE: n.lowest=index
} 

# First Plot Tree Ring Flow
sheetname1 <-  "TR_Meko_2017-SK"    ## Natural flow: "AnnualWYTotalNaturalFlow_LF2018"   ## Tree ring: "TR_Meko_2017-SK"  

## Factor to change the current unit --------------------------------------------------------
unit_factor <- 10^(-6)   ## ac-ft to MAF

## Maximum length of sequence (sequences will be from 1 to seq_yr) --------------------------
seq_yr <- 25

## desired period ---------------------------------------------------------------------------
yr1 <- 1416   ## NF:1906   TR:1416       
yr2 <- 2015   ## NF:2018   TR:2015    
  
## A year to devide the period into two period.  --------------------------------------------
post_year <- 2000   ## post-year will be distinguished in plot

###  read data ========================================================================================================

data <- read.xlsx(filename1, sheet=sheetname1, colNames=TRUE)
years <- yr1:yr2
n <- length(years)

#### Cumulative Flow Loss plot ###########################################################################################     
####   - Calculate the sequnce averages and then Cumulative Flow Losses
####   - creat the dotty plot                                                 
####

#### Calculate the sequnce averages =================================

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
lowest_unit <- lowest*unit_factor  

### Calculate the cumulative flow loss ====================================

## The mean flow as a crirerion to calculate the losses
mean_criterion <- mean(flow)* unit_factor

## empty matrix
lowest_loss <- matrix(rep(NA), nrow=n , ncol=seq_yr)

## calculate the losses for each sequance average
for(s in 1:seq_yr){
  lowest_loss[,s] <- (mean_criterion - lowest_unit[,s]) * s
}


###### Creat dotty plot (Cumulative Flow Loss) ====================================

## the final dataframe that you want its dotty plot will be SeqAve
SeqAve <- lowest_loss

## will be used to plot with a better scale:
min <- floor(min(SeqAve, na.rm=TRUE))
max <- ceiling(max(SeqAve, na.rm=TRUE))

##### plot -----------------------
x <- c(1:seq_yr)
par(mar=c(5, 4, 3, 2) + 0.2 , mgp=c(2.5, 1, 0) )

### >>>>> NOTE: run just one of the following plot (1 or 2) <<<<<<

# ## 2- For tree ring reconstructed flow run this:
plot(x, SeqAve[1,], col="white", ylim=c(min, max) , xlim=c(1, seq_yr+1), xaxt="n" ,yaxt="n",
     pch=16, cex=0.6, xlab="Length of sequence (year)", ylab="Mean flow (MAF)", cex.lab=1.3,
     main=paste0("Tree Ring Reconstructed Flow at Lees Ferry \n Meko et al. 2017 (Most Skillful Model),    Period: " ,yr1,"-",yr2))

### axis of the plot ------------
axis(1, at=seq(1,seq_yr,1), cex.axis=1)
axis(2, at=seq((-100),(100),20), cex.axis=1, las=1)  ## las=1 to rotate the y lables

## Horizontal line of zero
abline(h=0)

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


### lable the first and second highest cumulative flow loss ----------
text(SeqAve[1,]~x, labels=lowest_year[1,], pos = 3, cex=0.6, col="black", srt=0)
text(SeqAve[2,]~x, labels=lowest_year[2,], pos = 4, cex=0.5, col="gray47", srt=0)

#### >>>>> NOTE: run just one of the following legend (1 or 2) <<<<<<

### 2- Legend for tree ring reconstructed flow 1416-2015 -----------
legend("topleft", legend=c("Full Period (1416-2015)","Post-2000 (2000-2015)"),
       col=c("lightskyblue3","black"), pt.bg=c(NA,"red") , pch=c(1,21), pt.cex=c(0.6, 0.8),
       lty=c(0,0), inset=c(0.05, 0.03), bty = "n")

# Second Plot Historic Natural flow
sheetname1 <-  "AnnualWYTotalNaturalFlow_LF2018"    ## Natural flow: "AnnualWYTotalNaturalFlow_LF2018"   ## Tree ring: "TR_Meko_2017-SK"  

## Factor to change the current unit --------------------------------------------------------
unit_factor <- 10^(-6)   ## ac-ft to MAF

## Maximum length of sequence (sequences will be from 1 to seq_yr) --------------------------
seq_yr <- 25

## desired period ---------------------------------------------------------------------------
yr1 <- 1906   ## NF:1906   TR:1416       
yr2 <- 2018   ## NF:2018   TR:2015    

## A year to devide the period into two period.  --------------------------------------------
post_year <- 2000   ## post-year will be distinguished in plot

###  read data ========================================================================================================

data <- read.xlsx(filename1, sheet=sheetname1, colNames=TRUE)
years <- yr1:yr2
n <- length(years)

#### Cumulative Flow Loss plot ###########################################################################################     
####   - Calculate the sequnce averages and then Cumulative Flow Losses
####   - creat the dotty plot                                                 
####

#### Calculate the sequnce averages =================================

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
lowest_unit <- lowest*unit_factor  

### Calculate the cumulative flow loss ====================================

## The mean flow as a crirerion to calculate the losses
mean_criterion <- mean(flow)* unit_factor

## empty matrix
lowest_loss <- matrix(rep(NA), nrow=n , ncol=seq_yr)

## calculate the losses for each sequance average
for(s in 1:seq_yr){
  lowest_loss[,s] <- (mean_criterion - lowest_unit[,s]) * s
}


###### Creat dotty plot (Cumulative Flow Loss) ====================================

## the final dataframe that you want its dotty plot will be SeqAve
SeqAve <- lowest_loss

## will be used to plot with a better scale:
min <- floor(min(SeqAve, na.rm=TRUE))
max <- ceiling(max(SeqAve, na.rm=TRUE))

##### plot -----------------------
x <- c(1:seq_yr)
par(mar=c(5, 4, 3, 2) + 0.2 , mgp=c(2.5, 1, 0) )


### >>>>> NOTE: run just one of the following plot (1 or 2) <<<<<<

## 1- For natural flow run this:
plot(x, SeqAve[1,], col="white", ylim=c(-100, 100) , xlim=c(1, seq_yr+1), xaxt="n" ,yaxt="n",
     pch=16, cex=0.6, xlab="Length of sequence (year)", ylab="Cumulative Flow Loss (MAF)", cex.lab=1.3,
     main=paste0("Natural Flow at Lees Ferry,  Period: " ,yr1,"-",yr2) )  ## , cex.main=1.3

### axis of the plot ------------
axis(1, at=seq(1,seq_yr,1), cex.axis=1)
axis(2, at=seq((-100),(100),20), cex.axis=1, las=1)  ## las=1 to rotate the y lables

## Horizontal line of zero
abline(h=0)


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



### lable the first and second highest cumulative flow loss ----------
text(SeqAve[1,]~x, labels=lowest_year[1,], pos = 3, cex=0.6, col="black", srt=0)
text(SeqAve[2,]~x, labels=lowest_year[2,], pos = 4, cex=0.5, col="gray47", srt=0)


#### >>>>> NOTE: run just one of the following legend (1 or 2) <<<<<<

### 1- Legend for natural flow 1906-2018 -----------
legend("topleft", legend=c("Full Period (1906-2018)","Post-2000 (2000-2018)"),
       col=c("lightskyblue3","black"), pt.bg=c(NA,"red") , pch=c(1,21), pt.cex=c(0.6, 0.8),
       lty=c(0,0), inset=c(0.05, 0.03), bty = "n")




