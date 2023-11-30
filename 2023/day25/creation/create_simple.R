
# create spatial file
library(sf)

# Download countries
library(giscoR)

ata <- gisco_get_countries(
  year = "2020",
  epsg = "4326",
  cache = TRUE,
  update_cache = FALSE,
  cache_dir = NULL,
  verbose = FALSE,
  resolution = "01",
  spatialtype = "RG",
  country = c('ATA'),
  region =  NULL
)

# change projection
spole_stereog <- 3031
atap <- st_transform(ata, crs=spole_stereog)

atap$FID <- as.integer(1)

sf::write_sf(atap, '../data/antarctica.gpkg', 'continent')

spole <- st_as_sf(data.frame(lat=c(-90), long=c(0)), coords = c('long', 'lat'), crs=4326)
spolep <- st_transform(spole, crs=spole_stereog)

svg(filename = "../raw_output.svg")
par(mar=c(0,0,0,0), family = "mono")
plot(atap$geometry)
plot(spolep$geometry, add=TRUE, pch=19)
dev.off()
