#!/usr/bin/python
import csv
import sys
import json
import datetime

# load date flag
with open("/cephfs/covid/software/sam/flags/gisaid.last") as datestamp_f:
    last_datestamp = datetime.datetime.strptime(datestamp_f.readline().strip(), "%Y-%m-%d").date()
if not last_datestamp:
    sys.exit(1)

# thanks for keeping it complex phe
phec_map = {}
for row in csv.DictReader(open(sys.argv[2]), delimiter="\t"):
    if row["root_sample_id"].startswith("H"):
        phec_map[row["root_sample_id"].replace("H", "")] = row["central_sample_id"]

pag_map = {}
for row in csv.DictReader(open(sys.argv[3]), delimiter=','):
    pag_map[row["covv_virus_name"]] = row["pag_name"]

JSON_FH = sys.argv[1]
for line in open(JSON_FH):
    payload = json.loads(line)

    if not payload["covv_location"].startswith("Europe / United Kingdom"):
        continue

    submitted = datetime.datetime.strptime(payload["covv_subm_date"], "%Y-%m-%d").date()

    if submitted < last_datestamp:
        continue

    gisaid_identifier = payload["covv_virus_name"]
    gisaid_accession = payload["covv_accession_id"]

    cogid = gisaid_identifier.split("/")[2]
    if cogid in phec_map:
        cogid = phec_map[cogid]

    if gisaid_identifier in pag_map:
        pag = pag_map[gisaid_identifier]
        contains = False
    else:
        cogid = gisaid_identifier.split("/")[2]
        if cogid in phec_map:
            cogid = phec_map[cogid]
        pag = "%s/" % cogid
        contains = True

    #print('\t'.join([
    #    'GISAID', cogid, payload["covv_accession_id"], gisaid_identifier, payload["covv_subm_date"]
    #]))
    print("ocarina --env put publish --publish-group '%s' %s --service 'GISAID' --accession '%s' --accession2 '%s' --public --public-date '%s'" % (pag, '--contains' if contains else '', gisaid_accession, gisaid_identifier, payload["covv_subm_date"]))
