#install.packages("plotrix")
library(plotrix) # for plotting circles

sv <- read.table('data/sylvain_sv.csv', sep=',', header = TRUE)

# replace SNR NA values with 0
sv$SNR[is.na(sv$SNR)] <- 0

sv$time <- strptime(sv$time, format="%H:%M:%S", tz = "UTC")
str(sv)

# I'm not sure I should add the elev as linear and not transformed (sin/cos?)...
sv$pathx <- sin(sv$azim/180*pi)*(90-sv$elev)
sv$pathy <- cos(sv$azim/180*pi)*(90-sv$elev)

par(mar=rep(0,4))
plot(sv$pathx, sv$pathy, xlim=c(-90,90), ylim=c(-90,90), pch=19, cex=sv$SNR/30, col=sv$satnum, asp=1)
abline(h=0)
abline(v=0)
draw.circle(0,0,90,100)
draw.circle(0,0,45,100)
text(c(0,0),c(90,45), labels = c(90,45))
