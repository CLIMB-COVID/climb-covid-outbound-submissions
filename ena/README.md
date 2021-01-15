# ENA Outbound

#### Housekeeping

    conda activate samstudio8
    source ~/.ocarina

#### Mark Majora with previous accessions

Accessions are automatically added to Majora.

#### Submit BAMs and register SAMPLE and RUN accessions

    ocarina-get-ena.sh
    bind_ena_table_to_meta.py ena.csv $COG_PUBLISHED_DIR/majora.latest.metadata.tsv > ena.nf.csv
    nextflow run dehuman.nf -c elan.config --manifest ena.nf.csv --datestamp YYYYMMDD --study PRJEB37886 --publish $ELAN_DIR --ascpbin $ASCP_BIN

#### Submit FASTA and register ANALYSIS (assembly) accessions

    ocarina-get-ena-assembly.sh
    metadata_to_erz_csv.py ena-assembly.csv > ena-assembly.nf.tsv
