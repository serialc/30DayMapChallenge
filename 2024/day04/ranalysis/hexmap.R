# Make a hex map
library(sf)

# get Luxembourg landuse 
lu <- st_read("../data/landuses.gpkg", layer = "relevant")
#plot(lu$geom, col='blue')

# Resolutions
hexcs <- c(16000, 8000, 4000, 2000, 1000)

svg(filename = 'maptuples/hextuples.svg', width = 20, height = 6)
par(mfrow=c(1, length(hexcs)))
par(mar=c(0,0,0,0))
sapply(hexcs, function(hexcellsize) {
  #hexcellsize <- 2000

    # Create hexagonal grid over the Luxembourg extent
  hex <- st_make_grid(lu , cellsize = hexcellsize, square = FALSE)
  #plot(hex)
  
  # Get the centroids of the Hexagons
  hexoid <- st_centroid(hex)
  #plot(hexoid)
  
  # Only keep hex that have centroids within Lux
  # find intersections
  vlh <- st_intersects(hexoid, lu)
  # deal with matrix returned -> boolean list
  vlhbool <- lengths(vlh) > 0
  luhex <- hex[vlhbool]
  
  # Now repeat for each landuse type
  # - forest
  # - urban
  # - water
  # - hills/other
  
  # We need centroids again of hex subset
  luhexoid <- st_centroid(luhex)
  #plot(luhexoid)
  
  # check which centroids fall within each landuse type
  luty <- sapply(names(table(lu$base_type)), function(lut) {
    # lut <- "forest"
    # get the feature intersection
    fint <- st_intersects(luhexoid, lu$geom[lu$base_type == lut])
    # return just the valid hexagons
    fhex <- luhex[lengths(fint) > 0]
  })
  
  # Make the map
  hexbounds <- st_union(luhex)
  # base
  plot(hexbounds, lwd=3)
  plot(hexbounds, col='sandybrown', lty=0, add=TRUE)
  plot(st_union(luty$forest), col='forestgreen', add=TRUE, lty=0)
  #plot(luty$hills, col='lightgreen', add=TRUE, lty=0)
  plot(st_union(luty$urban), col='darkred', add=TRUE, lty=0)
  plot(st_union(luty$water), col='skyblue', add=TRUE, lty=0)
  
  fpc <- round(length(luty$forest)/length(luhex)*100, 1)
  fph <- round(length(luty$hills)/length(luhex)*100, 1)
  fpu <- round(length(luty$urban)/length(luhex)*100, 1)
  fpw <- round(length(luty$water)/length(luhex)*100, 1)
  
  mtext(paste(sep=" ", hexcellsize, fpc, fph, fpu, fpw), line = -3)
})

dev.off()
