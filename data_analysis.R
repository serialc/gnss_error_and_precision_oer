#install.packages("plotrix")
library(plotrix) # for plotting circles
library(RColorBrewer)
library(TeachingDemos)

# function, takes a path to a SV file and creates the figure
plotSats <- function(source_file) {
  #source_file <- '20221027-Crosscall-nmea.csv'
  print(source_file)
  sv <- read.table(paste0('processing/sv_data/', source_file), sep=',', header = TRUE)
  gsv <- read.table(paste0('processing/gl_data/', source_file), sep=',', header = TRUE)
  
  # replace SNR NA values with 0
  sv$SNR[is.na(sv$SNR)] <- 0
  gsv$SS[is.na(gsv$SS)] <- 0
  # convert time to date
  sv$time <- strptime(sv$time, format="%H:%M:%S", tz = "UTC")
  gsv$time <- strptime(gsv$time, format="%H:%M:%S", tz = "UTC")
  #str(sv)
  
  # I'm not sure I should add the elev as linear and not transformed (sin/cos?)...
  sv$pathx <- sin(sv$azim/180*pi)*(90-sv$elev)
  sv$pathy <- cos(sv$azim/180*pi)*(90-sv$elev)
  gsv$pathx <- sin(gsv$azim/180*pi)*(90-gsv$elev)
  gsv$pathy <- cos(gsv$azim/180*pi)*(90-gsv$elev)
  
  # get a bunch of unique colours
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  
  # create plot
  imgsize <- 1000
  png(filename = paste0('images/', strsplit(source_file, "[.]")[[1]][1], "_satpaths.png"), width=imgsize, height=imgsize)
  par(mar=rep(0,4))
  plot(NULL, xlim=c(-90,90), ylim=c(-90,90), pch=21, cex=sv$SNR/30, bg=col_vector[sv$satnum], asp=1, lwd=3, col="black")

  lines_col <- "gray"
  lines(c(0,0), c(-90,90), col=lines_col, lwd=2)
  lines(c(-90,90), c(0,0), col=lines_col, lwd=2)
  draw.circle(0,0,90,100, border = lines_col, lwd=2)
  draw.circle(0,0,45,100, border = lines_col, lwd = 2)
  sapply(split(sv, sv$satnum), function(s) {
    points(s$pathx, s$pathy, pch=21, cex=s$SNR/30, col="black", lwd=3)
    points(s$pathx, s$pathy, pch=19, cex=s$SNR/30, col=col_vector[s$satnum], asp=1)
  })
  sapply(split(gsv, gsv$satnum), function(s) {
    points(s$pathx, s$pathy, pch=21, cex=s$SS/30, col="black", lwd=3)
    # glonass uses ids from 65 to 96 - adjust id for colour to fit end of colours range
    # want 96 to map to 74, so -22
    points(s$pathx, s$pathy, pch=19, cex=s$SS/30, col=col_vector[s$satnum-22], asp=1)
  })
  text(c(0,0,0),c(0,-45,-90), labels = c(" 90°\nZenith"," 45°"," 0°\nHorizon"), bg="white", col="black", cex=2)
  text(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "E", "S", "W"), bg="white", col="black", cex=2)
  #shadowtext(c(0,0,0),c(0,-45,-90), labels = c(" 90°\nZenith"," 45°"," 0°\nHorizon"), bg="white", col="black", r=0.1)
  #shadowtext(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "E", "S", "W"), bg="white", col="black", r=0.1)
  dev.off()
}

# will render figure for all data sets in the path below and save it to 'images'
for(sf in list.files('processing/sv_data/')) {
  plotSats(sf)
}


# compare GPS SNR and GLONASS SS (signal strength)
gps <- read.csv2('processing/sv_data/20221027-Crosscall-nmea.csv', sep=',')
gln <- read.csv2('processing/gl_data/20221027-Crosscall-nmea.csv', sep=',')

head(gps)
head(gln)

# looks like GLONASS's signal strength is the same as GPS's SNR
hist(gps$SNR)
abline(v=mean(gps$SNR, na.rm = TRUE), lwd=2, col="red")
hist(gln$SS)
abline(v=mean(gln$SS, na.rm = TRUE), lwd=2, col="red")


