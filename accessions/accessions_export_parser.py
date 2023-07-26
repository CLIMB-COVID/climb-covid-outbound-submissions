#!/usr/bin/env python3
import csv
import sys
import datetime

with open(sys.argv[1], "rt") as accession_fh, open(sys.argv[2], "wt") as out_fh:
    reader = csv.DictReader(accession_fh, delimiter=",")

    anon_samp_id_date = datetime.datetime(2023, 6, 30).date()

    writer = csv.DictWriter(
        out_fh,
        delimiter="\t",
        fieldnames=[
            "central_sample_id",
            "run_name",
            "gisaid.accession",
            "gisaid.secondary_accession",
            "ena_sample.accession",
            "ena_sample.secondary_accession",
            "ena_run.accession",
            "ena_run.secondary_accession",
            "ena_assembly.accession",
            "ena_assembly.secondary_accession",
        ],
    )

    writer.writeheader()

    for row in reader:
        if (
            datetime.datetime.strptime(row["published_date"], "%Y-%m-%d").date()
            >= anon_samp_id_date
        ):
            if not row["anonymous_sample_id"]:
                print(
                    f"[NOTE] {row['central_sample_id']} skipped as it does not appear to have an anonymous_sample_id despite being ingested on/after 2023-06-30",
                    file=sys.stderr,
                )
                continue

            row["central_sample_id"] = row["anonymous_sample_id"]

        writer.writerow(
            {
                "central_sample_id": row["central_sample_id"],
                "run_name": row["run_name"],
                "gisaid.accession": row["gisaid.accession"],
                "gisaid.secondary_accession": row["gisaid.secondary_accession"],
                "ena_sample.accession": row["ena_sample.accession"],
                "ena_sample.secondary_accession": row["ena_sample.secondary_accession"],
                "ena_run.accession": row["ena_run.accession"],
                "ena_run.secondary_accession": row["ena_run.secondary_accession"],
                "ena_assembly.accession": row["ena_assembly.accession"],
                "ena_assembly.secondary_accession": row[
                    "ena_assembly.secondary_accession"
                ],
            }
        )
