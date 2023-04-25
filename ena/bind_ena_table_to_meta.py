#!/usr/bin/python
import csv
import sys

# usage: python bind_ena_table_to_meta.py <ocarina_csv> <majora_tsv>
# this script is needed until we get run-level info on published artifact groups in ocarina
# i dont like this so dont @ me

select_set = set([])
select_dat = {}

new_fields = [
    "run_name",
    "library_strategy",
    "library_source",
    "library_selection",
    "library_primers",
    "library_protocol",
    "instrument_make",
    "instrument_model",
    "library_seq_kit",
    "library_seq_protocol",
]

select = csv.DictReader(open(sys.argv[1]), delimiter=',')
for row in select:
    cog = row["published_name"].split('/')[1]
    run = row["published_name"].split(':')[1]
    compound_k = "%s-%s" % (cog, run)
    select_set.add(compound_k)

def rm_none(s):
    if not s or s == "None":
        return None
    return s

manifest = csv.DictReader(open(sys.argv[2]), delimiter='\t')
for row in manifest:
    compound_k = "%s-%s" % (row["central_sample_id"], row["run_name"])
    select_dat[compound_k] = { fn: rm_none(row[fn]) for fn in new_fields }
    if not select_dat[compound_k]["library_primers"]:
        select_dat[compound_k]["library_primers"] = rm_none(row["meta.artic.primers"])
    if not select_dat[compound_k]["library_protocol"]:
        select_dat[compound_k]["library_protocol"] = rm_none(row["meta.artic.protocol"])

    if select_dat[compound_k]["library_primers"]:
        if select_dat[compound_k]["library_primers"][0] == "V":
            select_dat[compound_k]["library_primers"] = select_dat[compound_k]["library_primers"][1:]

select = csv.DictReader(open(sys.argv[1]), delimiter=',')
out = csv.DictWriter(sys.stdout, select.fieldnames + new_fields, delimiter='\t')
out.writeheader()
for row in select:
    if not row["collection_date"]:
        row["collection_date"] = row["received_date"]
        
    # ERS must already exist in ENA
    if len(row["ena_sample_id"]) == 0 or row["ena_sample_id"].lower() == "unknown":
        sys.stderr.write("[NOTE][NO-ERS] %s\n" % row["published_name"])
        continue  
      
    cog = row["published_name"].split('/')[1]
    run = row["published_name"].split(':')[1]

    if row["min_ct_value"] == "0.0":
        row["min_ct_value"] = None
    if row["max_ct_value"] == "0.0":
        row["max_ct_value"] = None

    compound_k = "%s-%s" % (cog, run)

    try:
        row.update(select_dat[compound_k])
    except KeyError:
        continue # ship

    out.writerow(row)
