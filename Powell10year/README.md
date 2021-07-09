# Lake Powell 10-Year Releases

This R script aggregates monthly Lake Powell release data reported by the Bureau of Reclamation (https://www.usbr.gov/rsvrWater/HistoricalApp.html)
And reports 10-year running sums of releases in acre-feet. These volumes are compared to the 75 MAF (to Lower Basin) and 82.5 MAF 
(to Lower Basin and Mexcico) delivery requirements specified in the 1922 Colorado River Compact. Summamtion is by water year. A difference between the
10-year release and 10-year 82.5 MAF requirement is calculated. This difference is potentially bankable in Lake Powell in future years
if the Upper Basin cut back it's future releases some (so the 10-year sum dropped to 82.5 MAF). The cutback would require
to change the customary practice to release 8.25 MAF per year (rather than 82.5 MAF per decande).

## Recommended Citation
David E. Rosenberg (2020). "Colorado River Futures - Code Projects: Powell 10 Year". Utah State University. Logan, Utah. https://github.com/dzeke/ColoradoRiverFutures.

## Explanation of Contents

1. **DecadePowllRelease.csv** - csv file output by Powell10Year.R with 10-year release volumes and differences
1. **DecadePOwellRease.xlsx** - Excel version with formatting to show in blog post
1. **Powell10Year.R** - R script that reads in raw release data, calculates 10-year sums and differences, dumps results to csv and shows plots of 
         (a) The 10-year values over time at a monthly time spacing, (b) 10-year values over time at an annual time spacing, and
		 (c) the difference between the 10-year sum and 82.5 MCM requirement
1. **PowellDataUSBRMay2020.csv** - Lake Powell release data downloaded from USBR for May 2020 on back
To run any code, download and install R and RStudio. Within the subfolder, open the .R file, highlight all the code, and run. 