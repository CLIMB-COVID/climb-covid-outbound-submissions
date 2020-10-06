#!/usr/bin/python
import json
import sys
import csv

JSON_MANIFEST = open(sys.argv[1])
SERVICES = [x.lower().replace('-', '_') for x in sys.argv[2].split(',')]


header = ["central_sample_id", "run_name", "sequencing_org_code"]
for service in SERVICES:
    header.append(service + '.accession')
    header.append(service + '.secondary_accession')

out_csv = csv.DictWriter(sys.stdout, delimiter='\t', fieldnames=header)
out_csv.writeheader()

json_data = json.load(JSON_MANIFEST)
for pag in json_data:
    prefix, sample, runinfo = pag["published_name"].split('/')
    seqsite, runname = runinfo.split(':')

    row = {
        "central_sample_id": sample,
        "run_name": runname,
        "sequencing_org_code": seqsite,
    }
    for service, accessions in pag["accessions"].items():
        service_col = service.lower().replace('-', '_')
        row[service_col + '.accession'] = accessions.get("accession", "")
        row[service_col + '.secondary_accession'] = accessions.get("secondary_accession", "")
    out_csv.writerow(row)

