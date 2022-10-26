import sys

if len(sys.argv) < 2:
    print("Please provide the filename(s) you would like to process:\n" +
    "python3 nmea_extract_latlng.py nmea_file.csv\n" +
    "python3 nmea_extract_latlng.py f1.csv f2.csv\n")

# go through each file
for fn in sys.argv[1:]:
    # open file
    fw = open(fn.split('.')[0] + '_latlng.csv', 'w')
    fw.write('rid,time,lat,lng\n')
    with open(fn, 'r') as fr:
        # go through each line
        rcount = 0
        for line in fr:
            # split csv into parts
            p = line.split(',')

            # Global Positioning System Fix Data
            if p[0] == '$GPGGA':

                # skip badly formed sentences
                if len(p) != 15 or p[2] == '' or p[4] == '':
                    continue

                time = p[1][0:3] + ':' + p[1][3:5] + ':' + p[1][5:6] + ' Z'

                # convert the lat/lng from deg-min to dec-deg
                lat = float(int(p[2][0:2])) + float(p[2][2:])/60
                if p[3] == 'S':
                    lat = -lat

                lng = float(p[4][0:3]) + float(p[4][3:])/60
                if p[5] == 'W':
                    lng = -lng

                print(rcount, time, lat, lng)
                fw.write(str(rcount) + ',' + time + ',' + str(lat) + ',' + str(lng) + '\n')
                rcount+=1
fr.close()
