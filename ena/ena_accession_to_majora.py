#!/usr/bin/env python3
import sys
import csv
import json
from datetime import datetime

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--accessions", required=True)
parser.add_argument("--profile", required=True)
args = parser.parse_args()

# Borrowed from the GISAID version
# First attempt at ocarina as an import, this is going to need some love in future
from ocarina.client import Ocarina
from ocarina.util import get_config

ocarina = Ocarina()
ocarina.config = get_config(profile=args.profile)


def send_accession(publish_group, accession_id, assemblyname, subm_date=None):
    if not accession_id:
        print("[FAIL] No accession provided for %s" % publish_group)
        return False

    if not subm_date:
        subm_date = datetime.now().strftime("%Y-%m-%d")

    success, obj = ocarina.api.put_accession(
        publish_group=publish_group,
        service="ENA-ASSEMBLY",
        accession=accession_id.strip(),
        accession2=assemblyname.strip(),
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


with open(args.accessions) as ls_fh:
    for record in csv.DictReader(ls_fh, delimiter=" "):
        publish_group = record["published_name"]
        erz = record["ena_assembly_id"]
        name = record["assemblyname"]
        send_accession(publish_group, erz, name)
