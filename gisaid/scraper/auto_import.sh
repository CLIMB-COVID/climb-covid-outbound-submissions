#!/usr/bin/bash

eval "$(conda shell.bash hook)"
conda activate samstudio8
source ~/.ocarina
set -euo pipefail

DATESTAMP=`date '+%Y-%m-%d'`

cd $COG_OUTBOUND_DIR/gisaid/latest

json_to_majora.py $GISAID_LIST $COG_PUBLISHED_DIR/majora.latest.metadata.tsv $COG_OUTBOUND_DIR/gisaid/latest/undup.csv > publish.$DATESTAMP.ocarina.sh
bash publish.$DATESTAMP.ocarina.sh > publish.$DATESTAMP.ocarina.sh.log 2> /dev/null

SUBMISSIONS=`grep -c '^0' publish.$DATESTAMP.ocarina.sh.log`

MSG='{"text":"
*COG-UK outbound-distribution GISAID accession report*
'$SUBMISSIONS' new accessions imported to Majora today"}'

curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK

echo $DATESTAMP > /cephfs/covid/software/sam/flags/gisaid.last
