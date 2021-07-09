# Lower Basin Agricultural Uses

The scripts in this folder helps visualize Lower Basin consumptive uses from input data for Colorado River Simulation System model (CRSS)(version January 2021). Three plots show:

 1. Monthly consumptive use requests
 2. Annual consumptive use requests
 3. Seasonal (Summer/Winter) consumptive use requests

The last plot can help estimate the water volume potentially saved if Lower Basin districts stop summer season water use and focus on irrigating higher value winter crops (dark leafy greens).

Data comes from The main CRSS data file DIT_CRSS_LBshortageEIS_2016UCRC_v1.8. This data represents the 2016 Upper Colorado River schedule (for upper basin states).

## Recommended Citation
Rosenberg (2021). "Lower Basin Water Uses from CRSS". Utah State University, Logan, Utah. https://github.com/dzeke/ColoradoRiverFutures/tree/master/LowerBasinAgUses.

## Explanation of Contents

1. **PlotLowerBasinAgUsers.r** - The R script to run
1. **DIT_CRSS_LBshortageEIS_2016UCRC_v1.8.xlsm** - Excel macro file copied from CRSS dmi folder. This file has consumptive use requests for every modeled entity in both the Upper and Lower basins.
1. **LowerBasinAgUses.rmd** - R markdown file with the code in PlotLowerBasinAgUsers.r and markup text. Generates LowerBasinAgUses.pdf
1. **LowerBasinAgUses** - Pdf file generated when run LowerBasinAgUses.rmd. File shows the three plots.

## To Run
1. Download and Install R and R Studio (Version 1.1.456)
1. In your file browser, double click the file LowerBasinAgUses.Rproject. This will open the project workspace and the script files
1. Select all the code in the file PlotLowerBasinAgUsers.r and run (Cntrol - Enter or the Run icon in the top right). The figures should generate.
1. Alternatively, Switch to the LowerBasinAgUses.Rmd pane. Then click the Knit icon above the code. The pdf file should generate.