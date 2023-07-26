#!/usr/bin/env python3
import sys
import csv
import datetime
import os

new_fields = [
    "assemblyname",
    "program",
]

with open(
    f"{os.getenv('ARTIFACTS_ROOT')}/elan/latest/majora.metadata.matched.tsv", "rt"
) as metadata_fh:
    reader = csv.DictReader(metadata_fh, delimiter="\t")

    if "meta.webin.failed" in reader.fieldnames:
        webin_failed = set(
            row["central_sample_id"]
            for row in reader
            if row["meta.webin.failed"] == "TRUE"
        )
    else:
        webin_failed = set()

select = csv.DictReader(open(sys.argv[1]), delimiter=",")

out = csv.DictWriter(sys.stdout, select.fieldnames + new_fields, delimiter="\t")
out.writeheader()

# Struct {"central_sample_id": {"published_date": published_date, "row": row}}
to_submit = {}

anon_samp_id_date = datetime.datetime(2023, 6, 30).date()

for row in select:
    if row["central_sample_id"] in webin_failed:
        continue

    if not row["collection_date"]:
        row["collection_date"] = row["received_date"]

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

    # Assembler must be set for submission
    # if len(row["assembler"]) == 0 or row["assembler"].lower() == "unknown":
    #     sys.stderr.write("[NOTE][NO-ASM] %s\n" % row["published_name"])
    #     continue

    # ERS and ERR must be set to allow proper linkage in ENA
    # if len(row["ena_sample_id"]) == 0 or row["ena_sample_id"].lower() == "unknown":
    #     sys.stderr.write("[NOTE][NO-ERS] %s\n" % row["published_name"])
    #     continue

    # if len(row["ena_run_id"]) == 0 or row["ena_run_id"].lower() == "unknown":
    #     sys.stderr.write("[NOTE][NO-ERR] %s\n" % row["published_name"])
    #     continue

    # Assign the magic identifier
    row["assemblyname"] = "COG-UK.%s#%s" % (
        row["central_sample_id"],
        row["published_uuid"].split("-")[0],
    )

    row["address"] = row["address"].replace("'", "")
    row["center_name"] = row["center_name"].replace("'", "")
    row["authors"] = row["authors"].replace("'", "")

    # Program name and version
    if len(row["assembler_version"]) == 0 or row["assembler_version"] == "0":
        version = ""
    else:
        version = row["assembler_version"]

    if len(row["assembler"]) == 0 or row["assembler"] == "0":
        assembler = "Unknown"
    else:
        assembler = row["assembler"]

    row["program"] = "%s %s" % (assembler, version)

    # Needs to be at the very end so that all the modifications to row are done
    if to_submit.get(row["central_sample_id"]):
        if (
            datetime.datetime.strptime(row["published_date"], "%Y-%m-%d").date()
            > datetime.datetime.strptime(
                to_submit[row["central_sample_id"]]["published_date"], "%Y-%m-%d"
            ).date()
        ):
            to_submit[row["central_sample_id"]] = {
                "published_date": row["published_date"],
                "row": row,
            }
    else:
        to_submit[row["central_sample_id"]] = {
            "published_date": row["published_date"],
            "row": row,
        }

for id, info in to_submit.items():
    out.writerow(info["row"])
