#!/usr/bin/env python3
import sys
import csv

# Take all cog_ids which have gisaid accessions and put them in a set
with open(sys.argv[1], "r") as accessions_tsv:
    reader = csv.DictReader(accessions_tsv, delimiter="\t")
    submitted_cog_ids = set(
        line["central_sample_id"] for line in reader if line["gisaid.accession"]
    )

# Iterate through the gisaid manifest CSV and
with open(sys.argv[2], "r") as gisaid_covv_csv:
    reader = csv.DictReader(gisaid_covv_csv, delimiter=",")
    writer = csv.DictWriter(sys.stdout, fieldnames=reader.fieldnames, delimiter=",")
    writer.writeheader()
    for line in reader:
        if line["central_sample_id"] in submitted_cog_ids:
            print(
                f"[NOTE] {line['covv_virus_name']} skipped as an artifact for this biosample has been uploaded previously",
                file=sys.stderr,
            )
            continue
        else:
            writer.writerow(line)

