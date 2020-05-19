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
    "instrument_make",
    "instrument_model",
]

select = csv.DictReader(open(sys.argv[1]), delimiter=',')
for row in select:
    cog = row["published_name"].split('/')[1]
    run = row["published_name"].split(':')[1]
    compound_k = "%s-%s" % (cog, run)
    select_set.add(compound_k)


manifest = csv.DictReader(open(sys.argv[2]), delimiter='\t')
for row in manifest:
    compound_k = "%s-%s" % (row["central_sample_id"], row["run_name"])
    select_dat[compound_k] = {
        "run_name": row["run_name"],
        "library_strategy": row["library_strategy"],
        "library_source": row["library_source"],
        "library_selection": row["library_selection"],
        "instrument_make": row["instrument_make"],
        "instrument_model": row["instrument_model"],
    }

select = csv.DictReader(open(sys.argv[1]), delimiter=',')
out = csv.DictWriter(sys.stdout, select.fieldnames + new_fields, delimiter='\t')
out.writeheader()
for row in select:
    cog = row["published_name"].split('/')[1]
    run = row["published_name"].split(':')[1]
    compound_k = "%s-%s" % (cog, run)
    row.update(select_dat[compound_k])
    out.writerow(row)
