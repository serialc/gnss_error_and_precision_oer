
##### do base plots for each file ##################
# load the function that makes the sat plots
source('functions.R')

# will render figure for all data sets in the path below and save it to 'images'
for(sf in list.files('processing/sv_data/')) {
  plotFileSats(sf)
}

##### compare GPS SNR and GLONASS SS (signal strength) ##############
gps <- read.csv2('processing/sv_data/20221027-Crosscall-nmea.csv', sep=',')
gln <- read.csv2('processing/gl_data/20221027-Crosscall-nmea.csv', sep=',')

head(gps)
head(gln)

# looks like GLONASS's signal strength is the same as GPS's SNR
hist(gps$SNR)
abline(v=mean(gps$SNR, na.rm = TRUE), lwd=2, col="red")
hist(gln$SS)
abline(v=mean(gln$SS, na.rm = TRUE), lwd=2, col="red")


