library(raster)
library(sf)

source <- raster('~/Downloads/orthophoto-2022-10cm-rgb-luxembourg.jp2')
extent <- raster('../data/VdL_DTM.tif')

plot(source)

cropped_ortho <- crop(source, extent)

plot(cropped_ortho)

raster::writeRaster(cropped_ortho, '../data/VdL_ortho.tif')

