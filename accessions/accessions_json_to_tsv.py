#!/usr/bin/env python3
import json
import sys
import csv
import os
import datetime

# I don't like this either but it's better than breaking the disgusting dataview
latest_metadata_path = os.path.join(
    os.getenv("ARTIFACTS_ROOT"), "elan/latest/majora.metadata.tsv"
)

latest_pag_lookup_path = os.path.join(
    os.getenv("ARTIFACTS_ROOT"), "elan/latest/majora.pag_lookup.tsv"
)

with open(latest_metadata_path, "rt") as metadata_fh:
    reader = csv.DictReader(metadata_fh, delimiter="\t")

    anon_id_lookup = {
        x["central_sample_id"]: x["anonymous_sample_id"]
        for x in reader
        if x["anonymous_sample_id"]
    }

with open(latest_pag_lookup_path, "rt") as pag_lookup_fh:
    reader = csv.DictReader(pag_lookup_fh, delimiter="\t")

    published_date_lookup = {x["pag_name"]: x["published_date"] for x in reader}

JSON_MANIFEST = open(sys.argv[1])
SERVICES = [x.lower().replace("-", "_") for x in sys.argv[2].split(",")]

header = ["central_sample_id", "run_name", "sequencing_org_code"]
for service in SERVICES:
    header.append(service + ".accession")
    header.append(service + ".secondary_accession")

out_csv = csv.DictWriter(sys.stdout, delimiter="\t", fieldnames=header)
out_csv.writeheader()

anon_samp_id_date = datetime.datetime(2023, 6, 20).date()

json_data = json.load(JSON_MANIFEST)
for pag in json_data:
    prefix, sample, runinfo = pag["published_name"].split("/")
    seqsite, runname = runinfo.split(":")

    try:
        published_date = datetime.datetime.strptime(
            published_date_lookup[pag["published_name"]], "%Y-%m-%d"
        ).date()

    except KeyError:
        print(
            f"No published date for {pag['published_name']}, skipping", file=sys.stderr
        )
        continue

    if published_date >= anon_samp_id_date:
        sample = anon_id_lookup[sample]

    row = {
        "central_sample_id": sample,
        "run_name": runname,
        "sequencing_org_code": seqsite,
    }
    for service, accessions in pag["accessions"].items():
        service_col = service.lower().replace("-", "_")
        row[service_col + ".accession"] = accessions.get("accession", "")
        row[service_col + ".secondary_accession"] = accessions.get(
            "secondary_accession", ""
        )
    out_csv.writerow(row)
