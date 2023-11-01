library(rjson)

##### clean and parse data ####

colh <- rjson::fromJSON(file='CoL_hygiene_ratings.json')

# only want restaurants with score breakdown and geocode
valid <- sapply(colh$EstablishmentCollection$EstablishmentDetail, function(x) { 
  length(unlist(x$scores)) == 3 && !any(sapply(x$geocode, is.null))
})

colhdf <- data.frame(
  do.call('rbind', lapply(colh$EstablishmentCollection$EstablishmentDetail[valid], function(x) { 
    # x <- colh$EstablishmentCollection$EstablishmentDetail[valid][[1]]
    c(x$BusinessName,
      as.integer(x$RatingValue),
      as.integer(unlist(x$scores)),
      sum(as.integer(unlist(x$scores))),
      as.numeric(unlist(x$geocode)))
  })), stringsAsFactors = F)

colnames(colhdf) <- c('name', 'rating', 'hygiene', 'structural', 'conf_manage', 'demerits', 'long', 'lat')

write.table(colhdf, file = 'CoL_hygiene_ratings_valid.csv', quote = FALSE, sep=';;', row.names = FALSE)

##### Convert to spatial data #####

library(sf)

# want int for rating
colhdf$rating <- as.integer(colhdf$rating)

# create sf object
spp <- st_as_sf(colhdf[colhdf$rating < 3,], coords = c('long', 'lat'), crs=4326)

# first look - one is out of bounds
plot(spp$geometry, col=spp$rating)

# remove the value outside City of London
spvalid <- spp[sapply(spp$geometry, '[[', 1) < max(sapply(spp$geometry, '[[', 1)),]

# better
plot(spvalid$geometry)

# classify points? No, we aren't bothered with the rankings 0-2

##### Let's get some OSM base map data #####
library(osmdata) #install.packages('osmdata')

data_bbox <- st_bbox(spvalid)

# get City of London bounds
bnds_opqf <- opq(bbox=data_bbox) %>%
  add_osm_feature(key = "boundary", value="police")
bnds <- osmdata_sf(bnds_opqf, quiet=FALSE)

# select the CoL bounds
bnds$osm_multipolygons$name
londbound <- bnds$osm_multipolygons$geometry[1]

# convert to metric projection coordinate system, buffer and convert back
londbound_bng <- st_transform(londbound, crs=27700)
londbound_buf <- st_transform(st_buffer(londbound_bng, 100), 4327)

# widen bounding box
col_bbox <- st_bbox(londbound_buf)

# retrieve osm data
bld_opq <- opq(bbox=col_bbox) # creates overpass query
bld_opqf <- add_osm_feature(bld_opq, key = "building") # adds feature to request for overpass query
bld <- osmdata_sf(bld_opqf, quiet=FALSE) # retrieve the data

hwy_opq <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "highway")
hwy <- osmdata_sf(hwy_opq, quiet = FALSE)

grass_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "landuse", value = "grass")
grass <- osmdata_sf(grass_opqf, quiet=FALSE)

meadow_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "landuse", value = "meadow")
meadow <- osmdata_sf(meadow_opqf, quiet=FALSE)

scrub_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "natural", value = "scrub")
scrub <- osmdata_sf(scrub_opqf, quiet=FALSE)

wetland_opqf <- opq(col_bbox) %>%
  add_osm_feature(key = "natural", value = "wetland")
wetland <- osmdata_sf(wetland_opqf, quiet=FALSE)

vineyard_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "landuse", value="vineyard")
vineyard <- osmdata_sf(vineyard_opqf, quiet = FALSE)

parks_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "leisure", value = "park") 
parks <- osmdata_sf(parks_opqf, quiet = FALSE)

wood_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "natural", value = "wood")
wood <- osmdata_sf(wood_opqf, quiet = TRUE)

forests_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "landuse", value = "forest")
forests <- osmdata_sf(forests_opqf, quiet = TRUE)

rail_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "railway", value = "rail")
rail <- osmdata_sf(rail_opqf, quiet = TRUE)

blue_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "natural", value = "water")
blue <- osmdata_sf(blue_opqf, quiet = FALSE)

stream_opqf <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "waterway", value = "stream")
stream <- osmdata_sf(stream_opqf, quiet = FALSE)

blue_ocean <- opq(bbox=col_bbox) %>%
  add_osm_feature(key = "natural", value = "water")
ocean <- osmdata_sf(blue_ocean, quiet = FALSE)

##### Create map #####

# create map
lgreen <- '#66ff0033'
dgreen <- '#33990033'

svg(filename = "col_restaurants.svg")
# add 'green' spaces
plot(forests$osm_polygons$geometry, col=dgreen, border=0, xlim = col_bbox[c(1,3)], ylim = col_bbox[c(2,4)])
#plot(wood$osm_polygons$geometry, add=TRUE, col=dgreen, border=0)
plot(parks$osm_polygons$geometry, add=TRUE, col=lgreen, border=0)
plot(wetland$osm_polygons$geometry, add=TRUE, col=lgreen, border=0)
#plot(vineyard$osm_polygons$geometry, add=TRUE, col=lgreen, border=0)
plot(grass$osm_polygons$geometry, add=TRUE, col=lgreen, border=0)
#plot(meadow$osm_polygons$geometry, add=TRUE, col=lgreen, border=0)
#plot(scrub$osm_polygons$geometry, add=TRUE, col=lgreen, border=0)

# blue spaces
plot(blue$osm_polygons$geometry, add=TRUE, col='lightblue', border='steelblue2')
plot(stream$osm_lines$geometry, add=TRUE, col='steelblue2', lwd=1)
plot(ocean$osm_multipolygons$geometry, add=TRUE, col='steelblue', border=NA)

# built env.
plot(bld$osm_polygons$geometry, add=TRUE, col='wheat3', lty=0)
plot(hwy$osm_lines$geometry, add=TRUE, col='grey80', lty=1, lwd = 1)
plot(rail$osm_lines$geometry, add=TRUE, col='grey60', lty=2, lwd=2)

# bounds
plot(bnds$osm_lines$geometry, add=TRUE, col='black', lty=2, lwd=2)

plot(spvalid$geometry, col="blue", add = TRUE, pch=21, fill="white")
text(st_coordinates(spvalid), labels = spvalid$name, pos = 1, cex = 0.5)

dev.off()
