#install.packages("plotrix")
library(plotrix) # for plotting circles
library(RColorBrewer)
library(TeachingDemos)

# function, takes a path to a SV file and creates the figure
plotSats <- function(source_file) {
  print(source_file)
  sv <- read.table(paste0('processing/sv_data/', source_file), sep=',', header = TRUE)
  
  # replace SNR NA values with 0
  sv$SNR[is.na(sv$SNR)] <- 0
  # convert time to date
  sv$time <- strptime(sv$time, format="%H:%M:%S", tz = "UTC")
  str(sv)
  
  # I'm not sure I should add the elev as linear and not transformed (sin/cos?)...
  sv$pathx <- sin(sv$azim/180*pi)*(90-sv$elev)
  sv$pathy <- cos(sv$azim/180*pi)*(90-sv$elev)
  
  # get a bunch of unique colours
  qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
  col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
  
  png(filename = paste0('images/', strsplit(source_file, "[.]")[[1]][1], "_satpaths.png"), width=500, height=500)
  par(mar=rep(0,4))
  plot(NULL, xlim=c(-90,90), ylim=c(-90,90), pch=21, cex=sv$SNR/30, bg=col_vector[sv$satnum], asp=1, lwd=3, col="black")
  lines(c(0,0), c(-90,90))
  lines(c(-90,90), c(0,0))
  draw.circle(0,0,90,100)
  draw.circle(0,0,45,100)
  sapply(split(sv, sv$satnum), function(s) {
    points(s$pathx, s$pathy, pch=21, cex=s$SNR/30, col="black", lwd=3)
    points(s$pathx, s$pathy, pch=19, cex=s$SNR/30, col=col_vector[s$satnum], asp=1)
  })
  shadowtext(c(0,0,0),c(0,-45,-90), labels = c("90°\nZenith","45°","0°\nHorizon"), bg="white", col="black", r=0.1)
  shadowtext(c(0,70,0,-70), c(70,0,-70,0), labels = c("N", "E", "S", "W"), bg="white", col="black", r=0.1)
  dev.off()
}
         
# will render figure for all data sets in the path below and save it to 'images'
for(sf in list.files('processing/sv_data/')) {
  plotSats(sf)
}
                                                                                                                                    