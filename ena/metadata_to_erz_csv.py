#!/usr/bin/env python3
import sys
import csv

new_fields = [
    "assemblyname",
    "program",
]

select = csv.DictReader(open(sys.argv[1]), delimiter=",")

out = csv.DictWriter(sys.stdout, select.fieldnames + new_fields, delimiter="\t")
out.writeheader()

for row in select:
    if not row["collection_date"]:
        row["collection_date"] = row["received_date"]

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
    out.writerow(row)
