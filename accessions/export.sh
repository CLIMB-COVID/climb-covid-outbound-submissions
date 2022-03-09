#!/usr/bin/bash
source /cephfs/covid/software/eagle-owl/scripts/hootstrap.sh
source "$EAGLEOWL_CONF/common.sh"
source "$EAGLEOWL_CONF/ocarina/service_outbound.sh"
PATH="$PATH:$OUTBOUND_SOFTWARE_DIR/accessions"

eval "$(conda shell.bash hook)"
conda activate $CONDA_OUTBOUND

set -euo pipefail

DATESTAMP=`date '+%Y-%m-%d'`

cd $ARTIFACTS_ROOT/accessions
ocarina --env --oauth get dataview --mdv COG2 -o cog2.mdv.json --task-wait --task-wait-attempts 100

$OUTBOUND_SOFTWARE_DIR/accessions/accessions_json_to_tsv.py cog2.mdv.json 'GISAID,ENA-SAMPLE,ENA-RUN,ENA-ASSEMBLY' > $DATESTAMP.accessions.tsv

cp $DATESTAMP.accessions.tsv $ARTIFACTS_ROOT/accessions/latest.accessions.tsv
chmod 644 $ARTIFACTS_ROOT/accessions/latest.accessions.tsv

# Dump to s3
s3cmd --config $EAGLEOWL_CONF/outbound/s3cfg put --acl-public $ARTIFACTS_ROOT/accessions/latest.accessions.tsv s3://cog-uk/accessions/latest.tsv
