#!/usr/bin/env python3
import sys
import csv
import json
from datetime import datetime

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--csv", required=True)
parser.add_argument("--response", required=True)
parser.add_argument("--response-mode", required=True)
parser.add_argument("--accessions-table", required=True)
args = parser.parse_args()

# Get a set of Gisaid IDs already in Majora
with open(args.accessions_table, "r") as accessions_table:
    gisaid_accessions = set(
        line.split("\t")[3] for line in accessions_table if len(line.split("\t")[3]) > 0
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


def do_json_record(record):
    record_type = record.get("code")
    if not record_type:
        return

    if record_type == "epi_isl_id":
        strain_id, accession_id = record["msg"].split(";")

        publish_group = strain_to_pag_map.get(strain_id)
        send_accession(publish_group, accession_id, strain_id)

    elif record_type == "validation_error":
        strain_id, error, error_json = record["msg"].split(";")

        error_data = json.loads(error_json)

        if error_data["covv_virus_name"] == "already exists":
            publish_group = strain_to_pag_map.get(strain_id)
            accession_id = error_data["existing_ids"]
            if accession_id not in gisaid_accessions:
                send_accession(publish_group, accession_id, strain_id)
        else:
            print("[FAIL] Validation error encountered: %s, %s" % (strain_id, error))

    elif record_type.endswith("_count"):
        print(record_type + ":" + record["msg"])


if args.response_mode.lower() == "json":
    j = json.load(open(args.response))
    for record in j:
        do_json_record(record)

elif args.response_mode.lower() == "json-bk":
    with open(args.response) as response_fh:
        for line in response_fh:
            j = json.loads(line.strip())
            do_json_record(j)

elif args.response_mode.lower() == "tsv":
    with open(args.response) as tsv_fh:
        for record in csv.DictReader(tsv_fh, delimiter="\t"):
            strain_id = record["covv_virus_name"]
            accession_id = record["covv_accession_id"]
            subm_date = record["covv_subm_date"]

            publish_group = strain_to_pag_map.get(strain_id)
            send_accession(publish_group, accession_id, strain_id, subm_date=subm_date)

else:
    sys.exit(2)

