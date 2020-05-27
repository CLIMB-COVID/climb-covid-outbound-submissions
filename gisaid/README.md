# GISAID Outbound

#### Housekeeping

    conda activate samstudio8
    source ~/.ocarina

#### Mark Majora with new accessions

    ocarina-get-pre-gisaid.sh
    gisaid_to_majora.py <gisaid.csv> <majora.metadata.tsv> <eligible.ls> > publish.ocarina.sh
    bash publish.ocarina.sh > publish.ocarina.sh.log 2> /dev/null

#### Process new accessions

    ocarina-get-gisaid.sh
