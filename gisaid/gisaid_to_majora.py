#!/usr/bin/python
import sys
import csv

# usage: gisaid_to_majora.py <rambaut_gisaid_csv> <majora_manifest> <eligible_ls>

eligible_identifiers = set([])
for line in open(sys.argv[3]):
    fields = line.strip().split()
    eligible_identifiers.add(fields[1].replace('_', ' ')) # GISAID add the spaces back into Northern_Ireland
    
phec_map = {}
for row in csv.DictReader(open(sys.argv[2]), delimiter="\t"):
    if row["root_sample_id"].startswith("H"):
        phec_map[row["root_sample_id"].replace("H", "")] = row["central_sample_id"]

for row in csv.DictReader(open(sys.argv[1])):
    if row["is_uk"]:
        gisaid_identifier = row["covv_virus_name"]
        gisaid_accession = row["covv_accession_id"]
        cogid = gisaid_identifier.split("/")[2]
        if cogid in phec_map:
            cogid = phec_map[cogid]
        if gisaid_identifier not in eligible_identifiers:
            sys.stderr.write("[SKIP] Skipping %s...\n" % gisaid_identifier)
            continue
        print("ocarina --env put publish --publish-group '%s/' --contains --service 'GISAID' --accession '%s' --accession2 '%s' --public" % (cogid, gisaid_accession, gisaid_identifier))
