#!/usr/bin/bash

source ~/.bootstrap.sh

source "$EAGLEOWL_CONF/paths.env"
source "$EAGLEOWL_CONF/envs.env"
#source "$EAGLEOWL_CONF/slack.env"
source "$EAGLEOWL_CONF/service_outbound.env"

eval "$(conda shell.bash hook)"
conda activate $CONDA_OUTBOUND

set -euo pipefail

DATESTAMP=`date '+%Y-%m-%d'`

cd $COG_OUTBOUND_DIR/accessions
ocarina --env --oauth get dataview --mdv COG2 -o cog2.mdv.json --task-wait --task-wait-attempts 60

$OUTBOUND_SOFTWARE_DIR/accessions/accessions_json_to_tsv.py cog2.mdv.json 'GISAID,ENA-SAMPLE,ENA-RUN,ENA-ASSEMBLY' > $DATESTAMP.accessions.tsv

cp $DATESTAMP.accessions.tsv $COG_PUBLISHED_DIR/latest.accessions.tsv
chmod 644 $COG_PUBLISHED_DIR/latest.accessions.tsv

MSG="{'text':'
*COG-UK accession table published* to \`$COG_PUBLISHED_DIR/latest.accessions.tsv\`'}"

# don bother telling slack anymore
#curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK

# Dump to s3
s3cmd put --acl-public $COG_PUBLISHED_DIR/latest.accessions.tsv s3://cog-uk/accessions/latest.tsv
