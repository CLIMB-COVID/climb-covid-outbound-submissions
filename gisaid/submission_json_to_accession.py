#!/usr/bin/env python

# submission_json_to_accession.py <gisaid json reply> <today.covv.csv>
import sys
import csv
import json
from datetime import datetime

# Map the submitted strains to pags
strain_to_pag_map = {}
for row in csv.DictReader(open(sys.argv[2]), delimiter=','):
    strain_to_pag_map[ row["covv_virus_name"] ] = row["pag_name"]

# First attempt at ocarina as an import, this is going to need some love in future
from ocarina.client import Ocarina
from ocarina.util import get_config

ocarina = Ocarina()
ocarina.config = get_config(env=True)

json = json.load(open(sys.argv[1]))
for record in json:
    record_type = record.get("code")
    if not record_type:
        continue

    if record_type == "epi_isl_id":
        strain_id, accession_id = record["msg"].split(";")

        publish_group = strain_to_pag_map.get(strain_id)
        if not publish_group:
            print("[FAIL] Could not map %s to PAG" % strain_id)
            continue

        success, obj = ocarina.api.put_accession(
                publish_group=publish_group,
                service="GISAID",
                accession=accession_id.strip(),
                accession2=strain_id.strip(),
                public=True,
                public_date=datetime.now().strftime("%Y-%m-%d"),
        )
        if not success:
            print("[FAIL] Failed to submit accession %s to PAG %s" % (accession_id, publish_group))

    elif record_type == "validation_error":
        strain_id, error = record["msg"].split(";", 1)
        print("[FAIL] Validation error encountered: %s, %s" % (strain_id, error))
    elif record_type.endswith("_count"):
        print(record_type + ':' + record["msg"])

