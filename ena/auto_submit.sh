eval "$(conda shell.bash hook)"
conda activate samstudio8
source ~/.ocarina

DATESTAMP=`date '+%Y%m%d'`

mkdir $COG_OUTBOUND_DIR/ena/$DATESTAMP
cd $COG_OUTBOUND_DIR/ena/$DATESTAMP

ocarina-get-ena.sh
bind_ena_table_to_meta.py ena.csv $COG_PUBLISHED_DIR/majora.latest.metadata.tsv > ena.nf.csv

cd $ELAN_SOFTWARE_DIR
nextflow run dehuman.nf -c elan.config --manifest $COG_OUTBOUND_DIR/ena/$DATESTAMP/ena.nf.csv --datestamp $DATESTAMP --study PRJEB37886 --publish $ELAN_DIR --ascpbin $ASCP_BIN > $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.stdout
mv .nextflow.log $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.log
