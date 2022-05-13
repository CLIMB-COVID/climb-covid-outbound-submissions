#!/usr/bin/env python3
import sys

with open(sys.argv[1], "r") as accessions_tsv:
    submitted_cog_ids = set(
        line.rstrip().split("\t")[0]
        for line in accessions_tsv
        if len(line.split("\t")[3]) > 0
    )

with open(sys.argv[2], "r") as undup_manifest_ls:
    for line in undup_manifest_ls:
        gisaid_name = line.split("\t")[1]
        cog_id = gisaid_name.split("/")[2]
        if cog_id in submitted_cog_ids:
            print(
                f"[NOTE] {gisaid_name} skipped as an artifact for this biosample has been uploaded previously",
                file=sys.stderr,
            )
            continue
        else:
            print(line, file=sys.stdout)
