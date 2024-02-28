# takes elevation profile data to make a joyplot

# load the function that does all the work
dsm_dtm_joyplot <- function(dsm, dtm, save_fp="", ...) {
  
  # compare the number of perpendicular lines in the dsm and dtm
  perp_lines <- length(unique(dsm$fid))
  if ( length(unique(dtm$fid)) != perp_lines ) {
    stop("Your DSM and DTM do not have the same dimensions")
  }
  # same, good
  
  # look at the number of data points per line
  dtm_ppl <- sapply(split(dtm$fid, dtm$fid), length)
  dsm_ppl <- sapply(split(dsm$fid, dsm$fid), length)
  if ( table(dtm_ppl) != table(dsm_ppl) ) {
    stop("Your DSM and DTM do not have the same number of points per line")
  }
  # same, good
  
  if( typeof(dsm$value_s) == "character" ) {
    dsm$value_s <- as.integer(t(sapply(strsplit(dsm$value_s, split="[{}, }]", perl=TRUE), '[[', 3)))
  }
  if( typeof(dtm$value_s) == "character" ) {
    dtm$value_s <- as.integer(t(sapply(strsplit(dtm$value_s, split="[{}, }]", perl=TRUE), '[[', 3)))
  }
  
  CleanPaths <- function( path_set, smooth_factor=3 ) {
    
    ppl <- sapply(split(path_set$fid, path_set$fid), length)
    
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
    })
    return(cln_path_set)
  }
  
  dtm_cln <- CleanPaths(dtm, smooth_factor = 1)
  dsm_cln <- CleanPaths(dsm, smooth_factor = 1)
  
  max_elev <- max(sapply(dtm_cln, function(x) { max(x$value_s, na.rm=TRUE)}))
  min_elev <- min(sapply(dsm_cln, function(x) { min(x$value_s, na.rm=TRUE)}))
  
  #save_fp <- 'something.2.svg'
  extension <- strsplit(save_fp, split = '[.]')[[1]]
  extension <- extension[length(extension)]
  if ( length(extension) == 0 ) {
    extension <- 'plot'
  }
  
  # determine whether to plot or export as svg/png/pdf
  accepted_formats <- c('plot', 'svg', 'png', 'pdf')
  if ( !extension %in%  accepted_formats) {
    stop(paste0("Export format must be one of the following", accepted_formats))
  }
  if ( extension == 'svg' ) {
    svg(filename = save_fp, ...)
  }
  if ( extension == 'png' ) {
    png(filename = save_fp, ...)
  }
  if ( extension == 'pdf' ) {
    pdf(file = save_fp, ...)
  }

  # Make the plot
  # margins
  par(mar=c(0,0,0,0), bg="black")
  #par(mar=c(0,0,0,0), bg="white")
  
  # vertical shift between plots
  flatenning_factor <- 5
  plot(NA, xlim=c(0, max(dtm_cln[[1]]$dist)), ylim=c(min_elev, perp_lines * flatenning_factor + max_elev), type='n')
  
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
  if ( extension != 'plot' ) {
    dev.off()
  }
}
  
orthophoto_joyplot <- function(dem, photo, save_fp="", bgcolour="black", plot_lwd=5, ...) {
  
  # compare the number of perpendicular lines in the dsm and dtm
  perp_lines <- length(unique(dem$fid))
  if ( length(unique(dem$fid)) != perp_lines ) {
    stop("Your DSM and DTM do not have the same dimensions")
  }
  # same, good
  
  # look at the number of data points per line
  dem_ppl <- sapply(split(dem$fid, dem$fid), length)
  photo_ppl <- sapply(split(photo$fid, photo$fid), length)
  ppl <- as.integer(dem_ppl[1])
  if ( table(dem_ppl) != table(photo_ppl) ) {
    stop("Your DSM and DTM do not have the same number of points per line")
  }
  # same, good
  
  if( typeof(dem$value_s) == "character" ) {
    dem$value_s <- as.integer(t(sapply(strsplit(dem$value_s, split="[{}, }]", perl=TRUE), '[[', 3)))
  }
  if( typeof(photo$value_s) == "character" ) {
    rgb <- as.integer(t(sapply(strsplit(photo$value_s, split="[{}, }]", perl=TRUE), function(x) { x[c(3,6,9)] } )))
    photo_rgb <- matrix(rgb, ncol=3)
  }
  
  CleanPaths <- function( path_set, smooth_factor=3 ) {
    
    ppl <- sapply(split(path_set$fid, path_set$fid), length)
    
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
      
      return(set)
    })
    return(cln_path_set)
  }
  
  dem_cln <- CleanPaths(dem, smooth_factor = 1)
  
  max_elev <- max(sapply(dem_cln, function(x) { max(x$value_s, na.rm=TRUE)}))
  min_elev <- min(sapply(dem_cln, function(x) { min(x$value_s, na.rm=TRUE)}))
  
  #save_fp <- 'something.2.svg'
  extension <- strsplit(save_fp, split = '[.]')[[1]]
  extension <- extension[length(extension)]
  if ( length(extension) == 0 ) {
    extension <- 'plot'
  }
  
  # determine whether to plot or export as svg/png/pdf
  accepted_formats <- c('plot', 'svg', 'png', 'pdf')
  if ( !extension %in%  accepted_formats) {
    stop(paste0("Export format must be one of the following", accepted_formats))
  }
  if ( extension == 'svg' ) {
    svg(filename = save_fp, ...)
  }
  if ( extension == 'png' ) {
    png(filename = save_fp, ...)
  }
  if ( extension == 'pdf' ) {
    pdf(file = save_fp, ...)
  }

  # Make the plot
  # margins
  par(mar=c(0,0,0,0), bg=bgcolour)
  #par(mar=c(0,0,0,0), bg="white")
  
  # vertical shift between plots
  flatenning_factor <- 5
  plot(NA, xlim=c(0, max(dem_cln[[1]]$dist)), ylim=c(min_elev, perp_lines * flatenning_factor + max_elev), type='n')
  
  for( i in rev(1:perp_lines) ) {
    # i <- 55 
    elev <- dem_cln[[i]]
  
    # black fill to hide lower lines in GB
    polygon(c(0, elev$dist, elev$dist[nrow(elev)]), c(min_elev, elev$value_s + i*flatenning_factor, min_elev), col='black')
    
    # paint each segement
    for ( s in 1:(ppl-1) ) {
      # s <- 1
      spair <- s:(s+1)
      rgbrow <- (i-1)*ppl + s
      scol <- rgb(photo_rgb[rgbrow, 1]/255, photo_rgb[rgbrow, 2]/255, photo_rgb[rgbrow, 3]/255)
      lines(elev$dist[spair], elev$value_s[spair] + i*flatenning_factor, col=scol, lwd=plot_lwd)
    }
  }
  
  # end the export if necessary
  if ( extension != 'plot' ) { dev.off() }
}

# Get the data
dsm <- read.table('../data/VdL_profiles3_500.1.tsv', sep='\t', header=T)
dtm <- read.table('../data/VdL_profiles3_dtm_500.1.tsv', sep='\t', header=T)

dsm_dtm_joyplot(dsm, dtm)

dsm_grund <- read.table('../data/VdL_grund_200.1m_dsm.tsv', sep='\t', header=T)
dtm_grund <- read.table('../data/VdL_grund_200.1m_dtm.tsv', sep='\t', header=T)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
dsm_dtm_joyplot(dsm_grund, dtm_grund)

dem <- read.table('../data/VdL_grund_200.1m_dsm.tsv', sep='\t', header=T)
photo <- read.table('../data/VdL_grund_200.1m_ortho.tsv', sep='\t', header=T)
orthophoto_joyplot(dem, photo, save_fp = "outputs/VdL_grund_ortho.png", plot_lwd=10, width="1000", height="4000")
