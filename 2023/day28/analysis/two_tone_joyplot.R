# takes elevation profile data to make a joyplot

# Get the data
dsm <- read.table('../data/VdL_profiles3_500.1.tsv', sep='\t', header=T)
dtm <- read.table('../data/VdL_profiles3_dtm_500.1.tsv', sep='\t', header=T)

# summary stats of elevation (fcfull)
length(unique(dtm$fid))
perp_lines <- length(unique(dsm$fid))
# same, good

table(sapply(split(dtm$fid, dtm$fid), length))
points_per_line <- sapply(split(dsm$fid, dsm$fid), length)
table(points_per_line)
# same, good

# set variable for use later - number of samples per line
samples_per_line <- points_per_line[1]

if( typeof(dsm$value_s) == "character" ) {
  dsm$value_s <- as.integer(t(sapply(strsplit(dsm$value_s, split="[{}, }]", perl=TRUE), '[[', 3)))
}
if( typeof(dtm$value_s) == "character" ) {
  dtm$value_s <- as.integer(t(sapply(strsplit(dtm$value_s, split="[{}, }]", perl=TRUE), '[[', 3)))
}

CleanPaths <- function( path_set, smooth_factor=3 ) {
  
  ppl <- sapply(split(path_set$fid, dsm$fid), length)
  
  cln_path_set <- lapply(split(path_set, path_set$fid), function(x){
    # x <- fcfull[fcfull$fid == 18,]
    
    # subset if we have more points than the minimum
    set <- x[1:min(ppl),]
    
    # Give any values less than 0 the value 0
    set$value_s[set$value_s < 0] <- 0
  
    #plot(set$dist, set$value_s, type = 'l')
    # clean to equalize the length
    # clean spikes with multiple filters
    spikes_a <- which(filter(set$value_s, c(-0.5,1,-0.5)) > 15)
    set$value_s[spikes_a] <- filter(set$value_s, c(0.5,0,0.5))[spikes_a]
    
    # smoothing
    set$value_s <- filter(set$value_s, rep(1/smooth_factor, smooth_factor), sides = 2)
    set$value_s[1:2] <- set$value_s[3]
    set$value_s[(nrow(set)-1):nrow(set)] <- set$value_s[nrow(set)-2]
    
    #lines(set$dist, set$value_s, type = 'l', lwd=2)
    return(set)
  }
  return(cln_path_set)
)


    
  
}

dtm_cln <- CleanPaths(dtm, smooth_factor = 1)
dsm_cln <- CleanPaths(dsm, smooth_factor = 1)

max_elev <- max(sapply(dtm_cln, function(x) { max(x$value_s, na.rm=TRUE)}))
min_elev <- min(sapply(dsm_cln, function(x) { min(x$value_s, na.rm=TRUE)}))

# Make the plot

svg(filename = "outputs/VdL_dsm_dtm.svg", width=10, height=10)
#par(mar=c(2,2,1,1))
par(mar=c(0,0,0,0), bg="black")
#par(mar=c(0,0,0,0), bg="white")

# vertical shift between plots
flatenning_factor <- 5
plot(NA, xlim=c(0,samples_per_line), ylim=c(min_elev, perp_lines * flatenning_factor + max_elev), type='n')

#      _____surface___
#     /               \
#    /                 \
#====-------terrain-----======

for( i in rev(1:perp_lines) ) {
  # i <- 55 
  srf <- dsm_cln[[i]]
  ter <- dtm_cln[[i]]

  srf$vis <- NA
  ter$vis <- NA
  
  srf$vis[srf$value_s > ter$value_s] <- srf$value_s[srf$value_s > ter$value_s]
  ter$vis[srf$value_s == ter$value_s] <- ter$value_s[srf$value_s == ter$value_s]
  
  # white fill
  #polygon(c(0, x$dist, x$dist[nrow(x)]), c(0, x$value_s + i*flatenning_factor, 0), col=adjustcolor('white', alpha.f = 0.5), lty=0)
  # black fill
  polygon(c(0, srf$dist, srf$dist[nrow(srf)]), c(min_elev, srf$value_s + i*flatenning_factor, min_elev), col='black')
  
  # elevation
  #lines(srf$dist, srf$vis + i*flatenning_factor, col="red", lwd=2)
  lines(srf$dist, srf$value_s+ i*flatenning_factor, col="darkcyan", lwd=2)
  lines(ter$dist, ter$vis + i*flatenning_factor, col="white", lwd=2)
}
dev.off()
  