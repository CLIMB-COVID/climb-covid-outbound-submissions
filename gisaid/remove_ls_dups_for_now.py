#!/usr/bin/python
import sys

head_count = {}
f = open(sys.argv[1])
for line in f:
    fields = line.strip().split('\t')
    if fields[1] not in head_count:
        head_count[fields[1]] = 0
    head_count[fields[1]] += 1

f.seek(0)

ls_out = open(sys.argv[2], 'w')
for line in f:
    fields = line.strip().split('\t')
    if head_count[fields[1]] > 1:
        sys.stderr.write("%s suppressed as it appears more than once...\n" % fields[1])
        continue
    ls_out.write(line)
ls_out.close()

import csv
dr_fh = csv.DictReader(open(sys.argv[3]))
dw_fh = csv.DictWriter(open(sys.argv[4], 'w'), fieldnames=dr_fh.fieldnames)
dw_fh.writeheader()
for row in dr_fh:
    if head_count[row["covv_virus_name"]] > 1:
        continue
    row["covv_authors"] = row["covv_authors"].replace("\n", ",")
    dw_fh.writerow(row)
dr_fh.close()
dw_fh.close()
