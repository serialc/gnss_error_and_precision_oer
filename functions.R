library(RColorBrewer) # for colours
library(plotrix) # for plotting circles
library(gifski)

# function, takes a path to a SV file and creates the figure
plotFileSats <- function(source_file, one_gnss=FALSE, invert=FALSE) {
  print(source_file)
  
  data <- loadSatData(source_file)
  
  # remove any records that have no satsys, satnum, or llid
  data <- data[!(is.na(data$satsys) | is.na(data$satnum) | is.na(data$llid)),]
  
  if (!isFALSE(one_gnss)) {
    data <- data[data$satsys == one_gnss, ]
    if (nrow(data) == 0) {
      print("SKipping as there's no data to plot for this file with current parameters")
      return(FALSE)
    }
  }
  
  # get a bunch of unique colours
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  
  
  # give each sat a colour
  data$col = col_vector[data$satnum]
  # Glonass uses ids from 65 to 96 - adjust id for colour to fit end of colours range
  # want 96 to map to 74, so -22
  if (any(data$satsys == "GLN", na.rm = TRUE)) {
    data[data$satsys == "GLN", 'col'] = col_vector[data[data$satsys == "GLN", 'satnum'] - 22]
  }
  
  # file name postfixes
  postfixes <- ''
  if (invert) { postfixes <- paste0(postfixes, '_INV') }
  if (!isFALSE(one_gnss)) { postfixes <- paste0(postfixes, '_', one_gnss) }
  
  # create plot
  imgsize <- 600
  png(filename = paste0('images/', strsplit(source_file, "[.]")[[1]][1], "_satpaths", postfixes, ".png"), width=imgsize, height=imgsize)
  par(mar=rep(0,4))
  plotSats(data, invert=invert)
  dev.off()
}

animateSats <- function(source_file) {
  # source_file <- '20221027-Crosscall-nmea.csv'
  file_name <- substr(source_file, 1, nchar(source_file) - 4)
  
  ll <- read.table(paste0('processing/ll_data/', source_file), sep=',', header = TRUE)
  sv <- read.table(paste0('processing/sv_data/', source_file), sep=',', header = TRUE)
  as <- read.table(paste0('processing/as_data/', source_file), sep=',', header = TRUE)
  
  # only keep one row from 'as' per llid
  as2 <- do.call('rbind', lapply(split(as, as$llid), function(x) {
    # only keep the last row
    x[nrow(x),]
  }))
  
  # only keep one row per satellite from 'sv' per llid
  sv2 <- do.call('rbind', lapply(split(sv, sv$llid), function(x) {
    #x <- split(sv, sv$llid)[[1]]
    do.call('rbind', lapply(split(x, x$satnum), function(y) {
      y[nrow(y),]
    }))
  }))

  data <- merge(ll, sv2, by="llid", all.y=TRUE)
  fixsat <- merge(ll, as2, by="llid", all.x=TRUE)

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
  
  # Finally, to optimize rendering speed - remove duplicates
  # create a simplified data set that has unique coordinates, no duplicates for ploting
  data$ucoords <- paste(data$satnum, data$elev, data$azim)
  #simple_data <- simple_data[!duplicated(simple_data$ucoords),] # doesn't get highest SNR
  simple_data <- do.call('rbind', lapply(split(data, data$ucoords), function(x) {
    # for each unique set get just the reading with the highest SNR
    x[which(x$SNR == max(x$SNR, na.rm = TRUE))[1],]
  }))
  
  
  # some options
  imgsize <- 600
  opacity <- 0.6 # connected lines opacity
  
  # make directory if needed
  dest_dir <- 'images/anim_frames/'
  if (!file.exists(dest_dir)) {
    dir.create(dest_dir)
  }
  
  for (t in 1:nrow(ll)) {
    #t <- 1
    png(sprintf('%sframe_%04d.png', dest_dir, t), width = imgsize, height = imgsize)
    par(mar=c(1,1,1,1))
    thistime <- ll[t,'dt']

    # subset
    sats_now <- data[data$dt==thistime,]
    sats_used_now <- unlist(fixsat[fixsat$dt==thistime,][,13:24])
    lock_sats <- sats_now[sats_now$satnum %in% sats_used_now,]
    # other sats from the last 600 seconds
    #past_sats <- data[data$dt > (thistime - 600) & data$dt < thistime,]
    
    # plot the background
    # faded - removed
    #plotSats(sats_now, fg = FALSE, fade=past_sats)
    plotSats(simple_data, fg = TRUE, opacity=32/255, sat.bg=FALSE)
    
    # show which satellites we're locked on to
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

loadSatData <- function(file_name) {
  # file_name <- "belval.csv"
  ll <- read.table(paste0('processing/ll_data/', file_name), sep=',', header = TRUE)
  sv <- read.table(paste0('processing/sv_data/', file_name), sep=',', header = TRUE)
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

plotSats <- function(data, add=FALSE, bg=TRUE, fg=TRUE, fade=NULL, opacity=1, sat.bg=TRUE, invert=FALSE) {
  
  # While E is right and W on the left, when looking up at the sky this is backwards
  # This is adequate when looking down at the 'sky' map though.
  # You can invert the x-axis
  if (invert == TRUE) {
    data$pathx <- data$pathx * -1
  }
  
  # create base dimension/limits plot
  if (add==FALSE) {
    plot(NULL, xlim=c(-90,90), ylim=c(-90,90), asp=1, xlab="", ylab="", axes=FALSE)
  }
  
  # show other points, but faded
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
    if (sat.bg) {
      points(data$pathx, data$pathy, pch=21, cex=data$SNR/30, col=adjustcolor("black", alpha.f = opacity), lwd=3, asp=1)
    }
    points(data$pathx, data$pathy, pch=21, lwd=0, cex=data$SNR/30, col=NA, bg=adjustcolor(data$col, alpha.f = opacity), asp=1)
    
    text(c(0,0,0),c(0,-45,-90), labels = c(" 90°\nZenith"," 45°"," 0°\nHorizon"), bg="white", col="black", cex=1.5)
    if (invert == TRUE) {
      text(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "W", "S", "E"), bg="white", col="black", cex=1.5)
    } else {
      text(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "E", "S", "W"), bg="white", col="black", cex=1.5)
    }
  }
}
