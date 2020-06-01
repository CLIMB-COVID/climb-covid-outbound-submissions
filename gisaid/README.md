# GISAID Outbound

#### Housekeeping

    conda activate samstudio8
    source ~/.ocarina

#### Mark Majora with new accessions

Download the GISAID accessions from EpiCoV by setting `Location=Europe / United Kingdom` and the `Submission date` to the previous week.
Select `Sequencing technology metadata` to get a TSV.

    gisaid_to_majora.py <gisaid.tsv> <majora.metadata.tsv> > publish.ocarina.sh
    bash publish.ocarina.sh > publish.ocarina.sh.log 2> /dev/null

#### Process new accessions

    ocarina-get-gisaid.sh
