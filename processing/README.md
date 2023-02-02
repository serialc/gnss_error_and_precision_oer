# NMEA parsing (Python script)

The `extract_nmea_data.py` script in the [processing](https://github.com/serialc/gnss_accuracy_and_error_oer/tree/main/processing) folder will parse NMEA data and split it into the following CSV folders:
- as_data ($GPGSA): containing DOP and identifiers of satellites used for position fix.
- ll_data ($GPGGA): contains the date, time, latitude and longitude.
- mv_data ($GPRMC): contains movement data such as speed, bearing.
- sv_data ($GPGSV/GLGSV): contains the satellite details (e.g., type, elev, azim, SNR).
- tg_data ($GPVTG): contains bearings and speeds. Some repetition from mv_data.

## Instructions
Place your nmea data in the `nmea_data` folder and then execute the script as suits you:
```
python3 extract_nmea_data.py nmea_data/nmea_file.csv
python3 extract_nmea_data.py nmea_data/*
python3 extract_nmea_data.py nmea_data/f1.csv nmea_data/f2.csv
```

Note that the llid field in the generated files allows synchronizing data, such as date or location, between files.

