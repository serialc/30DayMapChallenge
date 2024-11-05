# Make a hex map
library(sf)



HexPols2 <- st_make_grid(StudyArea , cellsize = 21750, square = FALSE)
