#!/usr/bin/python
import sys
import csv

# usage: gisaid_submitted_to_majora.py <gisaid_undup_csv>

for row in csv.DictReader(open(sys.argv[1])):
    print("ocarina --env put publish --publish-group '%s' --service 'GISAID' --submitted" % row["pag_name"])

