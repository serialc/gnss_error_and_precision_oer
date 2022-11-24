
##### do base plots for each file ##################
# load the function that makes the sat plots
source('functions.R')

# will render figure for all data sets in the path below and save it to 'images'
for(sf in list.files('processing/sv_data/')) {
  plotFileSats(sf, one_gnss = 'GLN', invert=TRUE)
  plotFileSats(sf, one_gnss = 'GPS', invert=TRUE)
  plotFileSats(sf, invert=TRUE)
}

##### compare GPS SNR and GLONASS SS (signal strength) ##############
sv <- read.csv2('processing/sv_data/20221027-Crosscall-nmea.csv', sep=',')

head(sv)

# looks like GLONASS's signal strength is the same as GPS's SNR
hist(sv[sv$satsys == 'GPS', 'SNR'])
abline(v=mean(sv[sv$satsys == 'GPS', 'SNR'], na.rm = TRUE), lwd=2, col="red")
hist(sv[sv$satsys == 'GLN', 'SNR'])
abline(v=mean(sv[sv$satsys == 'GLN', 'SNR'], na.rm = TRUE), lwd=2, col="red")


