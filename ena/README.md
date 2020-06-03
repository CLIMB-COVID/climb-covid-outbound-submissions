# ENA Outbound

#### Housekeeping

    conda activate samstudio8
    source ~/.ocarina

#### Mark Majora with previous accessions

Accessions are automatically added to Majora.

#### Process new accessions

    ocarina-get-ena.sh
    python bind_ena_table_to_meta.py ena.csv $COG_PUBLISHED_DIR/majora.latest.metadata.tsv > ena.nf.csv
    nextflow run dehuman.nf -c elan.config --manifest ena.nf.csv --datestamp YYYYMMDD --study PRJEB37886 --publish $ELAN_DIR --ascpbin $ASCP_BIN

