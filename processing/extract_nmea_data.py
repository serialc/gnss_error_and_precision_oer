import os
import sys
import operator
from functools import reduce

nmeadp = 'nmea_data/'
svdp = 'sv_data/'
lldp = 'll_data/'
mvdp = 'mv_data/'
asdp = 'as_data/'
tgdp = 'tg_data/'
gldp = 'gl_data/'

# make directories if they don't exist
for dp in [svdp, lldp, mvdp, asdp, tgdp, gldp]:
    if not os.path.isdir(dp):
        os.mkdir(dp)


# delimiter: csv, tsv, etc...
dlm = ','

if len(sys.argv) < 2:
    print("Please provide the path and filename(s) you would like to process:\n" +
    "python3 extract_nmea_data.py nmea_file.csv\n" +
    "python3 extract_nmea_data.py nmea/*\n" +
    "python3 extract_nmea_data.py nmea/f1.csv nmea/f2.csv\n")

# go through each file
for fp in sys.argv[1:]:
    # extract the filename
    fn = os.path.basename(fp)

    # save data to two files - latlng and satviews
    fll = open(lldp + fn.split('.')[0] + '.csv', 'w')
    fll.write('llid,date,time,lat,lng\n')

    fsv = open(svdp + fn.split('.')[0] + '.csv', 'w')
    fsv.write('svid,llid,satsys,satnum,elev,azim,SNR\n')

    fmv = open(mvdp + fn.split('.')[0] + '.csv', 'w')
    fmv.write('mvid,llid,dt,status,lat,lng,spd_knots,spd_ms,bearing,mag_var\n')

    fas = open(asdp + fn.split('.')[0] + '.csv', 'w')
    fas.write('asid,llid,mode,fix,satused,pdop,hdop,vdop,' + ','.join(['s' + str(s) for s in range(1,13)]) + '\n')

    ftg = open(tgdp + fn.split('.')[0] + '.csv', 'w')
    ftg.write('tgid,llid,true_bear,magn_bear,spd_knots,spd_kmh\n')

    # open file for reading
    with open(nmeadp + fn, 'r') as fr:

        # count the lines and save the last time observed
        sv_rcount = 0
        ll_rcount = 0
        mv_rcount = 0
        as_rcount = 0
        tg_rcount = 0
        gl_rcount = 0

        ll_time = ''
        mv_date = ''

        checksum_fails = 0
        lines = 0

        print("Processing file '" + fn + "':")

        # go through each line
        for line in fr:
            # count the lines
            lines += 1

            # remove new line character
            line = line.strip()

            # every line should have a ONE checksum - identified by '*'
            if '*' not in line or len(line.split('*')) != 2:
                continue

            # has a checksum - so validate it
            # validate checksum (https://gist.github.com/MattWoodhead/0bc2b3066796e19a3a350689b43b50ab)
            nmeapckg, checksum = line.strip('$\n').split('*')
            calc_checksum = reduce(operator.xor, (ord(s) for s in nmeapckg), 0)
            if int(checksum, base=16) != calc_checksum:
                #print("Corrupt line: " + line)
                checksum_fails += 1
                continue

            # split the nmea csv package into parts
            p = nmeapckg.split(',')

            ###########################################
            # $GPGSV - GNSS Satellite views (locations)
            # $GLGSV - GNSS (GLONASS) Satellite views (locations)
            ###########################################
            if p[0] == 'GPGSV' or p[0] == 'GLGSV':

                satsys = "ERR"
                if p[0] == 'GPGSV':
                    satsys = "GPS"
                elif p[0] == 'GLGSV':
                    satsys = "GLN"
 
                # https://www.hemispheregnss.com/technical-resource-manual/Import_Folder/GLGSV_Message.htm

                # can be of variable length, but in batches of 4
                # eat our way through 4 at a time
                peat = p[4:]

                # can be up to 4 SV per line - consume the first four parts
                while len(peat) >= 4:
                    # check each value
                    # write to file
                    # svid,llid,satsys,satnum,elev,azim,SNR
                    fsv.write(str(sv_rcount) + dlm + str(ll_rcount) + dlm + satsys + dlm + peat[0] + dlm + peat[1] + dlm + peat[2] + dlm + peat[3] + '\n')
                    peat = peat[4:]
                    sv_rcount += 1

                # end of GPGSV - continue to next line
                continue

            ###########################################
            # $GPGGA - GNSS Fix Data (lat/long)
            ###########################################
            if p[0] == 'GPGGA':

                ll_time = p[1][0:2] + ':' + p[1][2:4] + ':' + p[1][4:6] + ' Z'

                # if lat or long are missing go to next line
                if p[2] == '' or p[4] == '':
                    continue

                # convert the lat/lng from deg-min to dec-deg
                lat = float(int(p[2][0:2])) + float(p[2][2:])/60
                if p[3] == 'S':
                    lat = -lat

                lng = float(p[4][0:3]) + float(p[4][3:])/60
                if p[5] == 'W':
                    lng = -lng

                # llid,date,time,lat,lng
                fll.write(str(ll_rcount) + dlm + mv_date + dlm + ll_time + dlm + str(lat) + dlm + str(lng) + '\n')

                ll_rcount += 1

                # end of GPGSV - continue to next line
                continue

            ###########################################
            # $GPRMC - Transit/movement data
            ###########################################
            if p[0] == 'GPRMC':
                mv_time = p[1][0:2] + ':' + p[1][2:4] + ':' + p[1][4:6] + ' Z'
                mv_date = '20' + p[9][4:] + '-' + p[9][2:4] + '-' + p[9][0:2]
                dt = mv_date + ' ' + mv_time

                warn = p[2]

                # if invalid go to next line
                if warn == 'V':
                    continue

                # convert the lat/lng from deg-min to dec-deg
                try:
                    lat = float(int(p[3][0:2])) + float(p[3][2:])/60
                    if p[4] == 'S':
                        lat = -lat

                    lng = float(p[5][0:3]) + float(p[5][3:])/60
                    if p[6] == 'W':
                        lng = -lng
                except ValueError:
                    print(p)
                    exit()

                spd_ms = float(p[7]) * 0.514444

                bearing = p[8]

                magvar = p[10]
                if p[11] == 'W':
                    magvar = '-' + magvar

                # mvid,llid,dt,warning,lat,lng,spd_knots,spd_ms,bearing,mag_var
                fmv.write(str(mv_rcount) + dlm + str(ll_rcount) + dlm + dt + dlm + warn + dlm + str(lat) + dlm + str(lng) + dlm + p[7] + dlm + str(spd_ms) + dlm + bearing + dlm + str(magvar) + "\n")

                mv_rcount += 1
                # end of GPRMC - continue to next line
                continue

            ###########################################
            # $GPGSA - Error and sat count
            ###########################################
            if p[0] == 'GPGSA':

                mode = p[1]
                fix= p[2]
                
                # count the empty slots and substract from max of 12
                sats = p[3:15]
                satused = 12 - sum([sat == '' for sat in sats])

                pdop = p[15]
                hdop = p[16]
                vdop = p[17]

                # asid,llid,mode,fix,satused,pdop,hdop,vdop
                fas.write(str(as_rcount) + dlm + str(ll_rcount) + dlm + mode + dlm + fix + dlm + str(satused) + dlm + pdop + dlm + hdop + dlm + vdop + dlm + ",".join(sats) + "\n")

                as_rcount += 1

                # end of GPGSA - error and sat count
                continue

            ###########################################
            # $GPVTG  - Bearings and speed
            ###########################################
            if p[0] == 'GPVTG':

                # tgid,llid,true_bear,magn_bear,spd_knots,spd_kmh
                ftg.write(str(tg_rcount) + dlm + str(ll_rcount) + dlm + p[1] + dlm + p[3] + dlm + p[5] + dlm + p[7] + "\n")

                tg_rcount += 1

                # end of GPVTG - error and sat count
                continue

            print("NMEA line not processed: " + line)

        # end of reading file
        # file closed

    print("Finished file '" + fn + "'. Contained " + str(lines) + " lines, " + str(checksum_fails) + " corrupt.\n")
    
    fll.close()
    fsv.close()
    fmv.close()
    fas.close()
    ftg.close()
