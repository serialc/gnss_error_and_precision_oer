# load the function that makes the sat plots
source('functions.R')

animateSats('20221027-Crosscall-nmea.csv')
animateSats('berlin.csv')

##### Try adding the plots over a basemap ####

library(basemaps, add=TRUE)
library(sf)

luxpcs <- 2169
wgs84 <- 4326
loccoords <- data.frame(lat=data$lat, lng=data$lng)
wgspnts <- st_as_sf(loccoords, coords = c('lng', 'lat'), crs=wgs84)
luxpnts <- st_transform(wgspnts, crs=luxpcs)
luxbb <- st_bbox(luxpnts)
wgsbb <- st_bbox(wgspnts)


plot(luxpnts, type="l")



# highlight the selected satellites used for geolocation
