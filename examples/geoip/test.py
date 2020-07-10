import csv
import gzip
import h3

csv_key = ['ip_start', 'ip_end', 'continent', 'country', 'stateprov', 'city', 'lat', 'lon']

with gzip.open('dbip-city-lite-2020-07.csv.gz', 'rt', encoding='utf-8') as f:
    print(f.readline())
    blob = csv.DictReader(f, csv_key)
    count = 0
    for r in blob:
        print(r['ip_start'], r['ip_end'], h3.geo_to_h3(float(r['lat']), float(r['lon']), 10))
        count += 1
        if count > 10000:
            break
