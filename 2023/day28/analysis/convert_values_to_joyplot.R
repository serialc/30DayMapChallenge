# takes elevation profile data to make a joyplot

# Get the data
fcfull <- read.table('../data/VdL_profiles_200.5.tsv', sep='\t', header=T)
fcfull <- read.table('../data/VdL_profiles2_200.1.tsv', sep='\t', header=T)
fcfull <- read.table('../data/VdL_profiles_300.1.tsv', sep='\t', header=T)
fcfull <- read.table('../data/VdL_profiles3_500.1.tsv', sep='\t', header=T)
fcfull <- read.table('../data/VdL_profiles3_dtm_500.1.tsv', sep='\t', header=T)
fcfull <- read.table('../data/VdL_profiles_DTM.tsv', sep='\t', header=T)
fcfull <- read.table('../data/VdL_snake_DEM.1.tsv', sep='\t', header=T)

# summary stats of elevation (fcfull)
perp_lines <- length(unique(fcfull$fid))
points_per_line <- sapply(split(fcfull$fid, fcfull$fid), length)
table(points_per_line)

# Some lines have an extra data point
# Why? Hmm, because some lines end up being a fraction longer, allowing an extra point

dist_per_ine <- sapply(split(fcfull$dist, fcfull$fid), max)
table(dist_per_ine)
if( typeof(fcfull$value_s) == "character" ) {
  fcfull$value_s <- as.integer(t(sapply(strsplit(fcfull$value_s, split="[{}, }]", perl=TRUE), '[[', 3)))
}

# clean to equalize the length
fc_cln <- lapply(split(fcfull, fcfull$fid), function(x){
  # x <- fcfull[fcfull$fid == 18,]
  
  # subset if we have more points than the minimum
  set <- x[1:min(points_per_line),]
  
  # Give any values less than 0 the value 0
  set$value_s[set$value_s < 0] <- 0

  #plot(set$dist, set$value_s, type = 'l')
  
  # clean spikes with multiple filters
  spikes_a <- which(filter(set$value_s, c(-0.5,1,-0.5)) > 15)
  set$value_s[spikes_a] <- filter(set$value_s, c(0.5,0,0.5))[spikes_a]

  #points(set[spikes_a, 'dist'], set[spikes_a, 'elev'], col='red')
  
  # smoothing
  smooth_factor <- 3
  set$value_s <- filter(set$value_s, rep(1/smooth_factor, smooth_factor), sides = 2)
  set$value_s[1:2] <- set$value_s[3]
  set$value_s[(nrow(set)-1):nrow(set)] <- set$value_s[nrow(set)-2]
  
  #lines(set$dist, set$value_s, type = 'l', lwd=2)
  
  return(set)
})

max_elev <- max(sapply(fc_cln, function(x) { max(x$value_s, na.rm=TRUE)}))
min_elev <- min(sapply(fc_cln, function(x) { min(x$value_s, na.rm=TRUE)}))

# Make the plot
png(filename = "outputs/VdL_snake_dem.png", width=1000, height=4000)
png(filename = "outputs/VdL_dtm.png", width=1000, height=4000)
png(filename = "outputs/VdL3_dtm.png", width=2000, height=2000)
svg(filename = "outputs/VdL3_dtm.svg", width=10, height=10)

# margins
#par(mar=c(2,2,1,1))
par(mar=c(0,0,0,0), bg="black")
#par(mar=c(0,0,0,0), bg="white")

# don't show water
water_height <- min_elev - 1 
# vertical shift between plots
flatenning_factor <- 5
plot(NA, xlim=c(0, max(fc_cln[[1]]$dist)), ylim=c(min_elev, perp_lines * flatenning_factor + max_elev), type='n')

for( i in rev(1:perp_lines) ) {
  # i <- 100
  x <- fc_cln[[i]]

  x$water <- x$value_s
  x$water[x$water > water_height] <- NA
  
  # colour pillars
  # sapply(1:nrow(x), function(r) {
  #   # r <- 1
  #   rx <- x[r,]
  #   rc <- xcol[r,]
  #   lines(c(rx$dist, rx$dist), c(rx$value_s + i*flatenning_factor, 0), col=rgb(rc$r/255, rc$g/255, rc$b/255), lwd=2)
  # })
  
  # only show elevation lines that are not 0
  not_water <- (x$value_s + i*flatenning_factor)
  not_water[x$water <= water_height] <- NA
  # lines(x$dist, not_water)
  
  # white fill
  #polygon(c(0, x$dist, x$dist[nrow(x)]), c(0, x$value_s + i*flatenning_factor, 0), col=adjustcolor('white', alpha.f = 0.5), lty=0)
  # black fill
  polygon(c(0, x$dist, x$dist[nrow(x)]), c(min_elev, x$value_s + i*flatenning_factor, min_elev), col='black')
  
  # elevation
  #lines(x$dist, x$value_s + i*flatenning_factor, col="black")
  #lines(x$dist, x$value_s + i*flatenning_factor, col="white", lwd=1)
  lines(x$dist, not_water, col="white", lwd=2)
  
  # water
  lines(x$dist, x$water + i*flatenning_factor, col="lightblue", lwd=2)
}
dev.off()
  