#!/usr/bin/env python
import sys
import csv
import json
from datetime import datetime

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--csv", required=True)
parser.add_argument("--response", required=True)
parser.add_argument("--response-mode", required=True)
args = parser.parse_args()

# Map the submitted strains to pags
strain_to_pag_map = {}
for row in csv.DictReader(open(args.csv), delimiter=','):
    strain_to_pag_map[ row["covv_virus_name"] ] = row["pag_name"]

# First attempt at ocarina as an import, this is going to need some love in future
from ocarina.client import Ocarina
from ocarina.util import get_config

ocarina = Ocarina()
ocarina.config = get_config(env=True)

def send_accession(publish_group, accession_id, strain_id, subm_date=None):
    if not publish_group:
        print("[FAIL] Could not map %s to PAG" % strain_id)
        return False
    if not accession_id:
        print("[FAIL] No accession provided for %s" % strain_id)
        return False

    if not subm_date:
        subm_date = datetime.now().strftime("%Y-%m-%d")

    success, obj = ocarina.api.put_accession(
            publish_group=publish_group,
            service="GISAID",
            accession=accession_id.strip(),
            accession2=strain_id.strip(),
            public=True,
            public_date=subm_date,
    )
    if not success:
        print("[FAIL] Failed to submit accession %s to PAG %s" % (accession_id, publish_group))
    else:
        print("[OKAY] %s:%s" % (publish_group, accession_id))
    return success

if args.response_mode.lower() == "json":
    json = json.load(open(args.response))
    for record in json:
        record_type = record.get("code")
        if not record_type:
            continue

        if record_type == "epi_isl_id":
            strain_id, accession_id = record["msg"].split(";")

            publish_group = strain_to_pag_map.get(strain_id)
            send_accession(publish_group, accession_id, strain_id)

        elif record_type == "validation_error":
            strain_id, error = record["msg"].split(";", 1)
            print("[FAIL] Validation error encountered: %s, %s" % (strain_id, error))
        elif record_type.endswith("_count"):
            print(record_type + ':' + record["msg"])

elif args.response_mode.lower() == "tsv":
    with open(args.response) as tsv_fh:
        for record in csv.DictReader(tsv_fh, delimiter='\t'):
            strain_id = record["covv_virus_name"]
            accession_id = record["covv_accession_id"]
            subm_date = record["covv_subm_date"]

            publish_group = strain_to_pag_map.get(strain_id)
            send_accession(publish_group, accession_id, strain_id, subm_date=subm_date)

else:
    sys.exit(2)

