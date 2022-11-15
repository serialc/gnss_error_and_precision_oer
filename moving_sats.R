# load the function that makes the sat plots
source('functions.R')

source_file <- '20221027-Crosscall-nmea.csv'

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

png_path <- file.path('images/anim_frames/', "frame_%04d.png")
for (t in 1:nrow(ll)) {
  png(png_path, width = 1000, height = 1000)
  thistime <- ll[t,'dt']
  
  # subset
  sats_now <- data[data$dt==thistime,]
  sats_used_now <- unlist(fixsat[fixsat$dt==thistime,][,13:24])
  lock_sats <- sats_now[sats_now$satnum %in% sats_used_now,]
  
  # plot
  plotSats(sats_now, fg = FALSE)
  for (s in 1:nrow(lock_sats)) {
    lines(c(0, lock_sats[s, 'pathx']), c(0, lock_sats[s, 'pathy']), lwd=4, col='black')
    lines(c(0, lock_sats[s, 'pathx']), c(0, lock_sats[s, 'pathy']), lwd=2, col=lock_sats[s, 'col'])
  }
  plotSats(sats_now, add=TRUE, bg=FALSE)
  dev.off()
}

# make animation
png_files <- sprintf(png_path, 1:10)
gif_file <- file.path('images', 'sat_anim.gif')
gifski(png_files, gif_file)
# unlink(png_files) # delete all the png
utils::browseURL(gif_file)

png_files <- list.files('images/anim_frames/')
gif_file <- tempfile(fileext = ".gif")
gifski(png_files, gif_file)
unlink(png_files)
utils::browseURL(gif_file)




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
