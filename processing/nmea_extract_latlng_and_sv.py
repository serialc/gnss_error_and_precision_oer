import os
import sys
import operator
from functools import reduce

nmeadp = 'nmea_data/'
svdp = 'sv_data/'
lldp = 'll_data/'

if len(sys.argv) < 2:
    print("Please provide the path and filename(s) you would like to process:\n" +
    "python3 nmea_extract_latlng.py nmea_file.csv\n" +
    "python3 nmea_extract_latlng.py nmea/f1.csv f2.csv\n")

# go through each file
for fp in sys.argv[1:]:
    # extract the filename
    fn = os.path.basename(fp)

    # save data to two files - latlng and satviews
    fll = open(lldp + fn.split('.')[0] + '_latlng.csv', 'w')
    fll.write('rid,time,lat,lng\n')
    fsv = open(svdp + fn.split('.')[0] + '_sv.csv', 'w')
    fsv.write('rid,time,satnum,elev,azim,SNR\n')

    # open file for reading
    with open(nmeadp + fn, 'r') as fr:

        # count the lines and save the last time observed
        rcount = 0
        time = ''

        # go through each line
        for line in fr:
            # split csv into parts
            p = line.strip().split(',')

            # every line should have a ONE checksum - identified by '*'
            if '*' not in line or len(line.split('*')) != 2:
                continue

            # has a checksum - so validate it
            # validate checksum (https://gist.github.com/MattWoodhead/0bc2b3066796e19a3a350689b43b50ab)
            nmeapckg, checksum = line.strip('$\n').split('*')
            calc_checksum = reduce(operator.xor, (ord(s) for s in nmeapckg), 0)
            if int(checksum, base=16) != calc_checksum:
                continue

            # GNSS Satellite views (locations)
            if p[0] == '$GPGSV':

                p = nmeapckg.split(',')
                peat = p[4:]

                # can be up to 4 SV per line - consume the first four parts
                while len(peat) >= 4:
                    # check each value
                    # write to file
                    fsv.write(str(rcount) + ',' + time + ',' + peat[0] + ',' + peat[1] + ',' + peat[2] + ',' + peat[3] + '\n')
                    peat = peat[4:]

            # GNSS Fix Data
            if p[0] == '$GPGGA':

                # validate
                # skip badly formed sentences
                if len(p) != 15 or p[2] == '' or p[4] == '':
                    continue

                time = p[1][0:2] + ':' + p[1][2:4] + ':' + p[1][4:6] + ' Z'

                # convert the lat/lng from deg-min to dec-deg
                lat = float(int(p[2][0:2])) + float(p[2][2:])/60
                if p[3] == 'S':
                    lat = -lat

                lng = float(p[4][0:3]) + float(p[4][3:])/60
                if p[5] == 'W':
                    lng = -lng

                #print(rcount, time, lat, lng)
                fll.write(str(rcount) + ',' + time + ',' + str(lat) + ',' + str(lng) + '\n')
                rcount+=1
fll.close()
fsv.close()
