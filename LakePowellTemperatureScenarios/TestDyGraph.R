#test of dygraphs interactive time series
#https://www.r-graph-gallery.com/318-custom-dygraphs-time-series-example.html

install.packages(c("dygraphs","xts"))

# Library
library(dygraphs)
library(xts)          # To make the convertion data-frame / xts format
library(tidyverse)
library(lubridate)

# Read the data (hosted on the gallery website)
data <- read.table("https://python-graph-gallery.com/wp-content/uploads/bike.csv", header=T, sep=",") %>% head(300)

# Check type of variable
# str(data)

# Since my time is currently a factor, I have to convert it to a date-time format!
data$datetime <- ymd_hms(data$datetime)

# Then you can create the xts necessary to use dygraph
don <- xts(x = data$count, order.by = data$datetime)
don <- xts(x = data$temp, order.by = data$datetime)

# Finally the plot
p <- dygraph(don) %>%
  dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="#D8AE5A") %>%
  dyRangeSelector() %>%
  dyCrosshair(direction = "vertical") %>%
  dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  %>%
  dyRoller(rollPeriod = 1)

p

# save the widget
# library(htmlwidgets)
# saveWidget(p, file=paste0( getwd(), "/HtmlWidget/dygraphs318.html"))