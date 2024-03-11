#!/usr/bin/env python3
import sys
import csv
import json
from datetime import datetime

import argparse

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
        print(
            "[FAIL] Failed to submit accession %s to PAG %s"
            % (accession_id, publish_group)
        )
    else:
        print("[OKAY] %s:%s" % (publish_group, accession_id))
    return success


def do_json_record(line):
    
    record = json.loads(line)
    
    if record["code"] == "ok":
        return
    
    elif record["code"] == "epi_isl_id":
        strain_id, accession_id = record["msg"].split("; ")
        
        publish_group = strain_to_pag_map.get(strain_id)
        
        if not args.test_mode:
            send_accession(publish_group, accession_id, strain_id)
        else:
            print(
                f"{publish_group} would be added to majora if not in test mode as: {accession_id}\t{strain_id}",
                file=sys.stdout,
            )

    elif record["code"] == "validation_error":
        
        msg, strain_id_msg, accession_id_msg = record["msg"].split("; ")
        if msg != "covv_virus_name: already exists":
            print(f"Unknown error: {msg}", file=sys.stdout)
            sys.exit(1)
            
        strain_id = strain_id_msg.replace("existing_virus_name: ", "")
        accession_id = accession_id_msg.replace("existing_ids: ['", "").replace("']", "")
        
        publish_group = strain_to_pag_map.get(strain_id)
        if accession_id not in existing_gisaid_accessions:
            if not args.test_mode:
                send_accession(publish_group, accession_id, strain_id)
                print(
                    f"[NOTE] {accession_id} returned as extant by GISAID",
                    file=sys.stdout,
                )
            else:
                print(
                    f"[NOTE] {publish_group} would be added to majora (as an existing upload not in majora) if not in test mode as: {accession_id}\t{strain_id}",
                    file=sys.stdout,
                )
        else:
            print(f"[NOTE] Previously submitted accession: {accession_id} already in Majora, no need to resubmit for: {publish_group}", file=sys.stdout)
            
    else:
        print("[FAIL] Validation error encountered for the following response: %s" % (record), file=sys.stdout)

parser = argparse.ArgumentParser()
parser.add_argument("--csv", required=True)
parser.add_argument("--response", required=True)
parser.add_argument("--accessions-table", required=True)
parser.add_argument("--test-mode", default=False, action="store_true")
args = parser.parse_args()

# Get a set of Gisaid IDs already in Majora
with open(args.accessions_table, "r") as accessions_tsv:
    reader = csv.DictReader(accessions_tsv, delimiter="\t")
    existing_gisaid_accessions = set(
        line["gisaid.accession"] for line in reader if line["gisaid.accession"]
    )

# Map the submitted strains to pags
strain_to_pag_map = {}
for row in csv.DictReader(open(args.csv), delimiter=","):
    strain_to_pag_map[row["covv_virus_name"]] = row["pag_name"]

# First attempt at ocarina as an import, this is going to need some love in future
from ocarina.client import Ocarina
from ocarina.util import get_config

ocarina = Ocarina()
ocarina.config = get_config(env=True)

with open(args.response, "rt") as resp_fh:
    for line in resp_fh:
        do_json_record(line)