#!/usr/bin/bash

eval "$(conda shell.bash hook)"
conda activate samstudio8
source ~/.ocarina
set -euo pipefail

DATESTAMP=`date '+%Y-%m-%d'`

cd $COG_OUTBOUND_DIR/accessions
ocarina --env --oauth get dataview --mdv COG2 -o cog2.mdv.json --task-wait --task-wait-attempts 30

accessions_json_to_tsv.py cog2.mdv.json 'GISAID,ENA-SAMPLE,ENA-RUN' > $DATESTAMP.accessions.tsv

cp $DATESTAMP.accessions.tsv $COG_PUBLISHED_DIR/latest.accessions.tsv
chmod 644 $COG_PUBLISHED_DIR/latest.accessions.tsv

MSG="{'text':'
*COG-UK accession table published* to \`$COG_PUBLISHED_DIR/latest.accessions.tsv\`'}"

#curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK
curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_TEST_HOOK

