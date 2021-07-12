# Colorado River Modeling Musings

### Quick link to download: [Pilot flex accounting to encourage more water conservation in a combined Lake Powell-Lake Mead system](https://github.com/dzeke/ColoradoRiverCoding/raw/main/ModelMusings/PilotFlexAccounting-CombinedPowellMead.xlsx)
														
This Github repository contains model musings. A model musing is an idea to build on existing Colorado River operations that includes a numerical implementation. A model musing includes a description, model structure, requirements and directions to use, model files, and comparisons to current basin operations.

## Pilot flex accounting tool to encourage more water conservation in a combined Lake Powell-Lake Mead system

## Description
Key features of this model musing are:
1. Give each party more flexibility to make their individual water consumption, conservation, and reservoir storage decisions independent of other parties.
1. Stretch the Lee Ferry compact point to be a region of combined management that starts with the natural inflow to Lake Powell and ends with Lake Mead releases.
1. Give each party an individual account in the combined reservoir system.
1. Each party makes their individual water consumption and conservation decisions within their available water. Each party's available water is their account balance, plus share of inflow, minus share of combined reservoir evaporation, plus water purchases, and minus water sales.
1. Add a "shared, reserve" account equal in volume to the current Lake Powell and Lake Mead protection volumes. The shared, reserve account is managed by consensus of all parties and is intended to prevent the parties from simulataneously drawing down the combined reservoir storage to zero (dead pools). The assumption is that 
the parties will not all agree on a withdraw. Thus, the water will stay parked in the account as a buffer pool, check, and balance so the parties do not collectively draw down the combined reservoir storage to zero.

The Pilot flex accounting tool is a structured Excel spreadsheet. When the spreadsheet is moved into a Google sheet, role players representing the Upper Basin, Lower Basin, Mexico, and other parties can synchronously access and collaboratively use the tool. Players make their
year-to-year water consumption and conservation decsions while they track other players' choices and monitor combined and individual reservoir storage.

Players can explore water conservation and consumptive use strategies for different scenarios of natural flow and different political (player) decisions. Player decisions include:
add more parties or stakeholders, split existing reservoir storage among users, split future inflows among users, and split the combined reservoir storage among reservoirs. 

See pdf file with visuals of the key ideas for this model musing: **[PilotFlexAccounting-KeyIdeas.pdf](https://github.com/dzeke/ColoradoRiverCoding/raw/main/ModelMusings/PilotFlexAccounting-KeyIdeas.pdf)**.

**Can flex accounting encourage more water conservation in the Colorado River basin?** Follow the directions below to download and try out the tool by yourself or with colleagues, friends, or family.
Please share feedback about this model musing -- things you like, things to improve -- with David Rosenberg at david.rosenberg@usu.edu. Or Tweet to [@WaterModeler](https://twitter.com/WaterModeler).

## Model Structure
**Spreadsheet structure**:
 * Rows represent the components of an interactive water budget for a combined Lake Powell-Lake Mead system. Interactive mean the players must enter some components of the water budget. The different types of components (cell fill) are:
   * Physical watershed data (Peach fill, blue text) such as inflows and reservoir evaporation,
   * Political (player) decisions (Orange fill, white text) such as individual water consumption and conservation,
   * Calculations (Grey fill), and
   * Facilitation steps (White fill).
 * Columns represent years. Each year has a natural inflow to Lake Powell, Grand Canyon Tributary flow (between Lake Powell and Lake Mead), and Natural flow between Hoover Dam and the US-Mexico boarder. Results from the end of one year carry on to the beginning of the next year.

**Model Uncertainties**:
 * Hydrologic: A facillitator or player(s) choose each year's natural flows.
 * Water demands: Players enter their individual water consumption and conservation decisions.
 
## Requirements to Use
1. A Google account. [Create a Google account](https://accounts.google.com/signup/v2/webcreateaccount?hl=en&flowName=GlifWebSignIn&flowEntry=SignUp)
1. Another participant (for synchronous play). A participant may role play one or more parties (e.g., Upper Basin and Mexico).
1. ~ 1 to 2 hours (may split over multiple periods).

## Directions to Use
1. Download the file **[PilotFlexAccounting-CombinedPowellMead.xlsx](https://github.com/dzeke/ColoradoRiverCoding/raw/main/ModelMusings/PilotFlexAccounting-CombinedPowellMead.xlsx)** to your computer.
1. Move the Excel file to be a Google Sheet in a Google Drive folder associated with your Google Account.
1. Invite the other players to join the Google Sheet. Copy + share the URL to the Sheet. Or in the upper right of the Sheet, click the **Share** button, add emails, and set permissions so players can access the sheet.
1. In the Google Sheet, select the left-most worksheet *ReadMe-Directions*. Follow the further directions to start and complete the role play.
 
## Requested Feedback
Please email feedback -- things you like, things to improve -- about the pilot flex water accounting tool or the role play to David Rosenberg at david.rosenberg@usu.edu. Or Tweet at [@WaterModeler](https://twitter.com/WaterModeler).
 
## Model File(s)
1. **[PilotFlexAccounting-CombinedPowellMead.xlsx](https://github.com/dzeke/ColoradoRiverCoding/raw/main/ModelMusings/PilotFlexAccounting-CombinedPowellMead.xlsx)** - An Excel file with the pilot flex accounting tool and directions to role play. For syncronous access by multiple players, download and move this file into a Google Sheet. See the ReadMe-Directions worksheet for directions.
1. **[PilotFlexAccounting-KeyIdeas.pdf](https://github.com/dzeke/ColoradoRiverCoding/raw/main/ModelMusings/PilotFlexAccounting-KeyIdeas.pdf)** - A PDF file that illustrates key ideas for this model musing.
1. **Hydrology** - Folder with Excel files used to generate hydrologic scenarios. CRB_29gages.xlsx: Listing of gages in the Colorado River basin used to estimate natural flow. NaturalFlows1906-2018_20200110.xlsx: Natural flow hydrology downloaded from the USBR website and modified to pick out particular 10- and 20- year sequences of flows from the observed and paleo reconstructed records.
1. **OldVersions** - Folder with older versions of the pilot flex accounting tool.

## Requested Citation
David E. Rosenberg (2021). "Pilot flex accounting to encourage more water conservation in a combined Lake Powell-Lake Mead system." Utah State University, Logan, UT. https://github.com/dzeke/ColoradoRiverCoding/tree/main/PilotFlexAccounting.

## License
BSD-3-Clause (https://github.com/dzeke/ColoradoRiverCoding/blob/main/LICENSE). Available to use, modify, distribute, etc. for free.
All modified or derivative products must use the same BSD-3-Clause license. This license keeps this work in the public domain forever.

