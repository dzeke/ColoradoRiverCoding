# Grand Canyon Intervening Flow (Lees Ferry to Lake Mead)

Here I use the USBR **Natural Flow Database (1907 to 2016)** and **USGS data (1990 to present)** to show Grand Canyon Intervening Flows from Lake Powell to Lake Mead. This analysis
includes variations in flows, correlations to Lee Ferry natural flows, and sequence average values using the method of Salehabadi and Tarboton (2020).

## View Results
Open the file **[GrandCanyonTribFlow.pdf](https://raw.githubusercontent.com/dzeke/ColoradoRiverCoding/main/GrandCanyonInterveningFlow/GrandCanyonTribFlow.pdf)** to view results and read n explanation of how results were generated.

## Requirements to Run
* R version 4.1.1. Download from https://cran.r-project.org/.
* R Studio 1.1.456. Download from https://www.rstudio.com/.

## Directions to Generate Results
1. Download and install R and RStudio (see requirements)
1. Within this subfolder, open the **GrandCanyonInterveningFlow.Rproject** file. R Studio should open.
1. Select the **GrandCanyonTribFlow.Rmd** tab (R markdown file) within R Studio.
1. Just below the tab, click the **Knit** button.
1. The code will run and generate the file **GrandCanyonTribFlow.pdf**. Open the pdf file to view results.

## Explanation of Contents
1. **SalehabadiEtAl-SequenceAverage** - Folder with code of sequence averaging method. Downloaded from Salehabadi and Tarboton (2020). Code from SeqAvePlot.R was modified and moved in **GrandCanyonTribFlow.Rmd** and **GrandCanyonInterveneFlow.r** files to work with the USGS and Natural flow datasets.
1. **GrandCanyonTribFlow.Rmd** - R markdown file with code to knit (run) to generate primary output file **GrandCanyonTribFlow.pdf**.
1. **GrandCanyonInterveneFlow.r** - R file with same code as **GrandCanyonTribFlow.Rmd** but pushes results to console. Use for testing code.
1. **GrandCanyonInterveningFlow.Rproject** - R project file. Use to open the project.
1. **HistoricalNaturalFlow.xlsx** - Excel file with monthly natural flow data from Prairie et al (2020). Only monthly sheet retained. See readme worksheet for more information.
1. **Supplementary_file-WangSchmidt.xlsx** - The excel file from Wang and Schmidt (2020) that compares USGS and Natural flow data for their period of analysis. See readme worksheet for more info.
1. **USGSInterveningFlowData.xlsx** - Excel data with USGS data for Colorado River near Peach Springs [9404200], Colorado River at Lees Feery [9382000], and Virign River at Littlefield [9415000] downloaded from USGS data service.

## Requested Citation
David E. Rosenberg (2020). "Grand Canyon Intervening Flow". Utah State University. Logan, Utah. https://github.com/dzeke/ColoradoRiverCoding/tree/main/GrandCanyonInterveningFlow.

## References
Prairie, J. (2020). "Colorado River Basin Natural Flow and Salt Data." U.S. Bureau of Reclamation. https://www.usbr.gov/lc/region/g4000/NaturalFlow/current.html.

Salehabadi, H., and D. Tarboton (2020), Sequence-Average and Cumulative Flow Loss Analyses for Colorado River Streamflow at Lees Ferry, edited, Hydroshare. http://www.hydroshare.org/resource/bbe8dffacb07458783b2e6924aa615bb.

Wang, J., and Schmidt, J. C. (2020). "Stream flow and Losses of the Colorado River in the Southern Colorado Plateau." Center for Colorado River Studies, Utah State University, Logan, Utah. https://qcnr.usu.edu/coloradoriver/files/WhitePaper5.pdf.
