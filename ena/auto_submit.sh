#!/usr/bin/bash
source ~/.path
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
ret=$?
if [ $ret -ne 0 ]; then
    lines=`tail -n 25 $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.stdout`
else
    lines=`awk -vRS= 'END{print}' $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.stdout`
fi

MSG='{"text":"*COG-UK ENA publishing pipeline finished...*
...with exit status '"$ret"'
'"\`\`\`${lines}\`\`\`"'"
}'
curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK

mv .nextflow.log $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.log
