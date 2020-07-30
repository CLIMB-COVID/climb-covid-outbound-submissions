#!/usr/bin/python
import sys
import csv

# usage: gisaid_to_majora.py <sam_gisaid_download> <majora_manifest> <last_weeks_gisaid_pags>

phec_map = {}
for row in csv.DictReader(open(sys.argv[2]), delimiter="\t"):
    if row["root_sample_id"].startswith("H"):
        phec_map[row["root_sample_id"].replace("H", "")] = row["central_sample_id"]

pag_map = {}
for row in csv.DictReader(open(sys.argv[3]), delimiter=','):
    pag_map[row["covv_virus_name"]] = row["pag_name"]

ack_table = open(sys.argv[1])
header = True
for line in ack_table:
    if header:
        if not line.startswith("Virus"):
            continue
        else:
            header = False
            continue

    fields = line.strip().split('\t')
    gisaid_identifier = fields[0]
    gisaid_accession = fields[1]

    if gisaid_identifier in pag_map:
        pag = pag_map[gisaid_identifier]
        contains = False
    else:
        cogid = gisaid_identifier.split("/")[2]
        if cogid in phec_map:
            cogid = phec_map[cogid]
        pag = "%s/" % cogid
        contains = True
    print("ocarina --env put publish --publish-group '%s' %s --service 'GISAID' --accession '%s' --accession2 '%s' --public" % (pag, '--contains' if contains else '', gisaid_accession, gisaid_identifier))

