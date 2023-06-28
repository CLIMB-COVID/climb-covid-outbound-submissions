#!/usr/bin/env python3
import sys
import csv
import datetime

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

    anon_samp_id_date = datetime.datetime(2023, 6, 30).date()

    for line in reader:
        if line["central_sample_id"] in submitted_cog_ids:
            print(
                f"[NOTE] {line['covv_virus_name']} skipped as an artifact for this biosample has been uploaded previously",
                file=sys.stderr,
            )
            continue

        if (
            datetime.datetime.strptime(line["published_date"], "%Y-%m-%d").date()
            >= anon_samp_id_date
        ):
            if not line["anonymous_sample_id"]:
                print(
                    f"[NOTE] {line['covv_virus_name']} skipped as it does not appear to have an anonymous_sample_id despite being ingested on/after 2023-06-30",
                    file=sys.stderr,
                )
                continue
            line["covv_virus_name"] = line["anonymous_sample_id"]
            line["central_sample_id"] = line["anonymous_sample_id"]

        else:
            writer.writerow(line)
