library(rayshader)
library(raster)

# Following tutorial from
# https://www.rayshader.com/

ul <- raster::raster('1_Second_DSM.tif')

# increase the resolution with smoothing
ulu <- raster::disaggregate(ul, fact=4, method='bilinear')

crs(ulu)

# reproject from 4283 to 7845 (Conformal Conic)
ulup <- raster::projectRaster(ulu, crs = 7845)
raster::plot(ulup)

# convert to matrix - no longer georeferenced
ulmat <- raster_to_matrix(ulup)

ulmat %>%
  sphere_shade(texture = "desert", sunangle=70) %>%
#  add_water(detect_water(ulmat, max_height = 554, cutoff = 0.9), color="palegreen3") %>%
  plot_map()

ulmat %>%
  sphere_shade(texture = "desert", sunangle = 70) %>%
#  add_water(detect_water(ulmat), color = "black") %>%
#  add_water(detect_water(ulmat, max_height = 554, cutoff = 0.9), color="palegreen3") %>%
  add_shadow(ray_shade(ulmat, sunaltitude=65, sunangle=70), 0.5) %>%
  add_shadow(ambient_shade(ulmat), 0.3) %>%
  plot_map()


png(filename = 'raw_ouput_proj.png', width = 2000, height=1600)
par(mar=c(0,0,0,0))
ulmat %>%
  sphere_shade(texture = "desert", sunangle = 60) %>%
#  add_water(detect_water(ulmat), color = "black") %>%
#  add_water(detect_water(ulmat, max_height = 554, cutoff = 0.9), color="palegreen3") %>%
  #add_shadow(ambient_shade(ulmat), 0.3) %>%
  add_shadow(ray_shade(ulmat, sunaltitude=65, sunangle=70), 0.5) %>%
  plot_3d(ulmat, zscale = 10, fov = 0, theta = 0, zoom = 0.65, phi = 45, baseshape = "circle", windowsize = c(2000, 1600))
Sys.sleep(0.2)
render_snapshot()
dev.off()