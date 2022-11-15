library(RColorBrewer) # for colours
library(plotrix) # for plotting circles

# function, takes a path to a SV file and creates the figure
plotFileSats <- function(source_file) {
  print(source_file)
  source_file <- 'belval.csv'
  ll <- read.table(paste0('processing/ll_data/', source_file), sep=',', header = TRUE)
  sv <- read.table(paste0('processing/sv_data/', source_file), sep=',', header = TRUE)
  data <- merge(ll, sv, by="llid", all.x=TRUE)
  
  # create datetime
  data$dt <- strptime(paste(data$date, data$time), format="%Y-%m-%d %H:%M:%S Z", tz = "UTC")
  
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

plotSats <- function(data, add=FALSE, bg=TRUE, fg=TRUE) {
  
  # create base dimension plot
  if (add==FALSE){
    plot(NULL, xlim=c(-90,90), ylim=c(-90,90), asp=1)
  }
  
  if (bg) {
    lines_col <- "gray"
    lines(c(0,0), c(-90,90), col=lines_col, lwd=2)
    lines(c(-90,90), c(0,0), col=lines_col, lwd=2)
    draw.circle(0,0,90,100, border = lines_col, lwd=2)
    draw.circle(0,0,45,100, border = lines_col, lwd = 2)
  }
  
  if (fg) {
    points(data$pathx, data$pathy, pch=21, cex=data$SNR/30, col="black", lwd=3)
    points(data$pathx, data$pathy, pch=19, cex=data$SNR/30, col=data$col, asp=1)
    
    text(c(0,0,0),c(0,-45,-90), labels = c(" 90°\nZenith"," 45°"," 0°\nHorizon"), bg="white", col="black", cex=2)
    text(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "E", "S", "W"), bg="white", col="black", cex=2)
  }
}
