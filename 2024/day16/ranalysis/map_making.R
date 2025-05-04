# Create a choropleth map showing the distribution
# of visitors who provided their postal codes

library(sf)
library(osmdata) #install.packages('osmdata')
library(classInt)
library(RColorBrewer)
library(ggspatial) #install.packages('ggspatial')

## Load data
# get the postal codes
pc <- st_read('../data/plz-5stellig.shp')

# get the event pc-count data
evt = read.table('../data/pc_data.csv', header = TRUE, sep = ',')

# Alter/clean data
# remove bad data
evt <- evt[evt$p_HeimOrt > 0,]

evtfrq <- table(evt$p_HeimOrt)

ef <- data.frame(evtfrq)
colnames(ef) <- c('pc', 'freq')

# change projection to ETRS/89
gpc <- st_transform(pc, crs=4839)

## Merge data sets
# merge data table to spatial
e <- merge(gpc, ef, by.x='plz', by.y='pc')

custbnds <- c(-315996, -192479, -223385, -62977)
names(custbnds) <- c('xmin', 'ymin', 'xmax', 'ymax')

## Mapping
#st_bbox(gpc)
# to find the desired mapping bounds use: locator() 
par(mar=c(1,1,1,1))
plot(e$geometry)
plot(e['freq'])

brewer.pal('Blues')

plot(e$geometry, xlim=c(-315996, -223385), ylim=c(-192479, -62977), lty=0, main="")
plot(e$geometry, border=adjustcolor("black", alpha.f = 0.3), add=TRUE)

# add roads, rivers, border
# download the data

# need bbox/bnds in WGS84
bnds <- st_transform(st_bbox(e), crs=4326)

osm_save_name = 'osm_features.RData'
if( file.exists(osm_save_name) ) {
  load(osm_save_name)
} else {
  hwy_opq <- opq(bbox=bnds, timeout = 180)
  hwy_opqf <- add_osm_feature(hwy_opq, key = "highway", value = "motorway")
  hwy <- osmdata_sf(hwy_opqf, quiet = FALSE)
  
  riv_opq <- opq(bbox=bnds, timeout = 180)
  riv_opqf <- add_osm_feature(riv_opq, key = "waterway", value = "river")
  riv <- osmdata_sf(riv_opqf, quiet = FALSE)
  
  bord_opq <- opq(bbox=bnds, timeout = 180)
  bord_opqf <- add_osm_feature(bord_opq, key = "admin_level", value = 2)
  bord <- osmdata_sf(bord_opqf, quiet = FALSE)

  save(hwy, file=osm_save_name)
}

phwy <- st_transform(hwy$osm_lines, 4839)
phwy_simp <- st_simplify(phwy)

plot(phwy_simp$geometry)
plot(phwy_simp$geometry, col="black", lwd=2, add=TRUE)
plot(phwy$geometry, col='black', lwd=2, add=TRUE)
plot(add=TRUE, riv, col='blue', lwd=2)