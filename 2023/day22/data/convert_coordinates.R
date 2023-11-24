
mp <- read.table('NP.txt', sep=' ')

colnames(mp) <- c('long', 'lat', 'year')

# fix so values are between 180 and -180
# some projects don't like the 0 to 360 values
mp$long[mp$long > 180] = mp$long[mp$long > 180] - 360

# create spatial file
library(sf)
mps <- st_as_sf(mp, coords = c('long', 'lat'), crs=4326)
plot(mps)

#sf::st_write(mps, 'magnetic_north_locations.geojson', append=FALSE)
#sf::st_write(mps, 'mag_north/magnetic_north_locations.shp', append=FALSE)

use_proj <- 5938
use_proj <- 3995

mps_proj <- st_transform(mps, crs=use_proj)

# Download countries
library(giscoR)

wrld <- gisco_get_countries(
  year = "2020",
  epsg = "4326",
  cache = TRUE,
  update_cache = FALSE,
  cache_dir = NULL,
  verbose = FALSE,
  resolution = "10",
  spatialtype = "RG",
  country = NULL,
  region = NULL
)

# change projection
wrld_proj <- st_transform(wrld, crs=use_proj)

# only keep Northern countries
nc <- wrld_proj[wrld_proj$CNTR_ID %in% c("CA", "US", "GL", "RU", "NO", "FI", "SJ", "SE"),]

npole <- st_as_sf(data.frame(lat=c(90), long=c(0)), coords = c('long', 'lat'), crs=4326)
npole_proj <- st_transform(npole, crs=use_proj)

# empty plot using data bounds
svg(filename = "../raw_output_legend.svg")
plot(mps_proj['year'], pch=19)
dev.off()

svg(filename = "../raw_output.svg")
par(mar=c(0,0,0,0), family = "mono")
plot(nc$geometry, col=as.integer(as.factor(nc$CNTR_ID))+10, xlim=c(-2400000, 1000000), ylim=c(-800000,1800000))
plot(mps_proj['year'], pch=19, add=TRUE)
subsample <- seq(from=1, to=length(mps_proj$geometry), by=10)
text(st_coordinates(mps_proj[subsample,]), labels = mps_proj$year[subsample], pos = 3)
plot(npole_proj$geometry, add=TRUE, pch=19)
dev.off()
