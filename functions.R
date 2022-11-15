library(RColorBrewer) # for colours
library(plotrix) # for plotting circles

# function, takes a path to a SV file and creates the figure
plotFileSats <- function(source_file) {
  print(source_file)
  
  data <- loadSatData(source_file)
  
  # get a bunch of unique colours
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  
  # remove any records that have no satsys or satnum
  data <- data[!(is.na(data$satsys) | is.na(data$satnum)),]
  
  # give each sat a colour
  data$col = col_vector[data$satnum]
  # Glonass uses ids from 65 to 96 - adjust id for colour to fit end of colours range
  # want 96 to map to 74, so -22
  if (any(data$satsys == "GLN", na.rm = TRUE)) {
    data[data$satsys == "GLN", 'col'] = col_vector[data[data$satsys == "GLN", 'satnum'] - 22]
  }
  
  # create plot
  imgsize <- 1000
  png(filename = paste0('images/', strsplit(source_file, "[.]")[[1]][1], "_satpaths.png"), width=imgsize, height=imgsize)
  par(mar=rep(0,4))
  plotSats(data)
  dev.off()
}

animateSats <- function(source_file) {
  file_name <- substr(source_file, 1, nchar(source_file) - 4)
  
  ll <- read.table(paste0('processing/ll_data/', source_file), sep=',', header = TRUE)
  sv <- read.table(paste0('processing/sv_data/', source_file), sep=',', header = TRUE)
  as <- read.table(paste0('processing/as_data/', source_file), sep=',', header = TRUE)
  
  data <- merge(ll, sv, by="llid", all.y=TRUE)
  fixsat <- merge(ll, as, by="llid", all.x=TRUE)
  
  # create datetime (we also need this for ll - after the merge)
  data$dt <- strptime(paste(data$date, data$time), format="%Y-%m-%d %H:%M:%S Z", tz = "UTC")
  fixsat$dt <- strptime(paste(fixsat$date, fixsat$time), format="%Y-%m-%d %H:%M:%S Z", tz = "UTC")
  ll$dt <- strptime(paste(ll$date, ll$time), format="%Y-%m-%d %H:%M:%S Z", tz = "UTC")
  
  # replace SNR NA values with 0
  data$SNR[is.na(data$SNR)] <- 0
  
  # I'm not sure I should add the elev as linear and not transformed (sin/cos?)...
  data$pathx <- sin(data$azim/180*pi)*(90-data$elev)
  data$pathy <- cos(data$azim/180*pi)*(90-data$elev)
  
  # get a bunch of unique colours
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  
  # remove any records that have no satsys or satnum
  data <- data[!(is.na(data$satsys) | is.na(data$satnum)),]
  
  # give each sat a colour
  data$col = col_vector[data$satnum]
  
  # give each sat a colour
  data$col = col_vector[data$satnum]
  # Glonass uses ids from 65 to 96 - adjust id for colour to fit end of colours range
  # want 96 to map to 74, so -22
  if (any(data$satsys == "GLN", na.rm = TRUE)) {
    data[data$satsys == "GLN", 'col'] = col_vector[data[data$satsys == "GLN", 'satnum'] - 22]
  }
  
  # some options
  imgsize <- 600
  opacity <- 0.3 # connected lines opacity
  
  for (t in 1:nrow(ll)) {
    png(sprintf('images/anim_frames/frame_%04d.png', t), width = imgsize, height = imgsize)
    par(mar=c(1,1,1,1))
    thistime <- ll[t,'dt']
    
    # subset
    sats_now <- data[data$dt==thistime,]
    sats_used_now <- unlist(fixsat[fixsat$dt==thistime,][,13:24])
    lock_sats <- sats_now[sats_now$satnum %in% sats_used_now,]
    # other sats from the last 600 seconds
    past_sats <- data[data$dt > (thistime - 600) & data$dt < thistime,]
    
    # plot
    plotSats(sats_now, fg = FALSE, fade=past_sats)
    for (s in 1:nrow(lock_sats)) {
      lines(c(0, lock_sats[s, 'pathx']), c(0, lock_sats[s, 'pathy']), lwd=4, col=adjustcolor('black', alpha.f = opacity/2))
      lines(c(0, lock_sats[s, 'pathx']), c(0, lock_sats[s, 'pathy']), lwd=2, col=adjustcolor(lock_sats[s, 'col'], alpha.f = opacity))
    }
    plotSats(sats_now, add=TRUE, bg=FALSE)
    mtext(text = thistime, side = 1, line = 0, adj = 1)
    dev.off()
  }
  
  # make animation
  png_files <- list.files('images/anim_frames/', full.names = TRUE)
  gif_file <- file.path('images', paste0(file_name, '.gif'))
  gifski(png_files = png_files, gif_file = gif_file, width = imgsize, height = imgsize, delay = 1/30, loop = TRUE)
  
  # delete all the png
  unlink(png_files)
  # show the animation
  utils::browseURL(gif_file)
}

loadSatData <- function() {
  ll <- read.table(paste0('processing/ll_data/', source_file), sep=',', header = TRUE)
  sv <- read.table(paste0('processing/sv_data/', source_file), sep=',', header = TRUE)
  data <- merge(ll, sv, by="llid", all.x=TRUE)
  
  # create datetime
  data$dt <- strptime(paste(data$date, data$time), format="%Y-%m-%d %H:%M:%S Z", tz = "UTC")
  
  # replace SNR NA values with 0
  data$SNR[is.na(data$SNR)] <- 0
  
  # convert angular to x/y coordinates
  data$pathx <- sin(data$azim/180*pi)*(90-data$elev)
  data$pathy <- cos(data$azim/180*pi)*(90-data$elev)
  
  return(data)
}

plotSats <- function(data, add=FALSE, bg=TRUE, fg=TRUE, fade=NULL) {
  
  # create base dimension plot
  if (add==FALSE) {
    plot(NULL, xlim=c(-90,90), ylim=c(-90,90), asp=1, xlab="", ylab="", axes=FALSE)
  }
  
  if (!is.null(fade)) {
    now <- min(data$dt)
    earliest <- min(fade$dt)
    max_secs <- as.integer(difftime(now, earliest, units='secs'))
    fade_opacity <- as.hexmode(as.integer(difftime(fade$dt, earliest, units='secs')/max_secs*256))
    fade_col <- paste0(fade$col, sprintf("%02X", fade_opacity))
    points(fade$pathx, fade$pathy, pch=19, cex=data$SNR/30, col=adjustcolor(fade_col, alpha.f = 0.01), asp=1)
  }
  
  if (bg) {
    lines_col <- "gray"
    lines(c(0,0), c(-90,90), col=lines_col, lwd=2)
    lines(c(-90,90), c(0,0), col=lines_col, lwd=2)
    draw.circle(0,0,90,100, border = lines_col, lwd=2)
    draw.circle(0,0,45,100, border = lines_col, lwd = 2)
  }
  
  if (fg) {
    points(data$pathx, data$pathy, pch=21, cex=data$SNR/30, col="black", lwd=3, asp=1)
    points(data$pathx, data$pathy, pch=19, cex=data$SNR/30, col=data$col, asp=1)
    
    text(c(0,0,0),c(0,-45,-90), labels = c(" 90°\nZenith"," 45°"," 0°\nHorizon"), bg="white", col="black", cex=1.5)
    text(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "E", "S", "W"), bg="white", col="black", cex=1.5)
  }
}
