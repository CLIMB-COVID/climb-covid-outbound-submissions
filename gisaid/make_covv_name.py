#!/usr/bin/python
import csv
import sys
from datetime import datetime

CSV_FN = sys.argv[1]

csv_fh = open(CSV_FN)
gisaid_csv = csv.DictReader(csv_fh)


out_csv = csv.DictWriter(sys.stdout, gisaid_csv.fieldnames)
out_csv.writeheader()
for row in gisaid_csv:

    collected_or_received_year = None
    collection_date_or_year = None

    # Get the collection year to suffix the virus name
    if row.get("collection_date") and len(row["collection_date"]) > 0:
        try:
            collected_or_received_year = datetime.strptime(row["collection_date"], "%Y-%m-%d").year
            collection_date_or_year = row["collection_date"]
        except ValueError:
            collected_or_received_year = None

    # Try received year instead
    if not collected_or_received_year:
        if row.get("received_date") and len(row["received_date"]) > 0:
            try:
                collected_or_received_year = datetime.strptime(row["received_date"], "%Y-%m-%d").year
            except ValueError:
                collected_or_received_year = None

    if not collection_date_or_year:
        collection_date_or_year = collected_or_received_year

    #TODO Future we can perhaps use this opportunity to generate alternative names for when there are multiple submissions
    row["covv_virus_name"] = "hCoV-19/%s/%s/%d" % (row["adm1_trans"].replace('_', ' '), row["central_sample_id"], collected_or_received_year)
    row["covv_collection_date"] = collection_date_or_year


    # Fix the platform name as requested by GISAID curators
    row["covv_seq_technology"] = row["covv_seq_technology"].replace('_', ' ').title()

    # Remove underscore from location as requested by GISAID curators
    row["covv_location"] = row["covv_location"].replace('_', ' ')


    out_csv.writerow(row)
