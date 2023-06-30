#!/usr/bin/bash
source /cephfs/covid/software/eagle-owl/scripts/hootstrap.sh
source "$EAGLEOWL_CONF/common.sh"
source "$EAGLEOWL_CONF/ocarina/service_outbound.sh"
PATH="$PATH:$OUTBOUND_SOFTWARE_DIR/accessions"

eval "$(conda shell.bash hook)"
conda activate $CONDA_OUTBOUND

set -euo pipefail

DATESTAMP=`date '+%Y-%m-%d'`

cd $EAGLEOWL/data/outbound-submissions/accessions/

# Retire the disgusting old dataview
# ocarina --env --oauth get dataview --mdv COG2 -o cog2.mdv.json --task-wait --task-wait-attempts 100
if [ ! -f "$DATESTAMP.accessions.csv" ]; then
    ocarina --env --oauth get pag --test-name 'cog-uk-elan-minimal-qc' --pass --task-wait --task-wait-attempts 120 --odelimiter , \
        --ofield central_sample_id central_sample_id 'XXX' \
        --ofield anonymous_sample_id anonymous_sample_id '' \
        --ofield published_date published_date 'XXX' \
        --ofield accession.gisaid.primary_accession gisaid.accession '' \
        --ofield accession.gisaid.secondary_accession gisaid.secondary_accession '' \
        --ofield accession.ena-sample.primary_accession ena_sample.accession '' \
        --ofield accession.ena-sample.secondary_accession ena_sample.secondary_accession '' \
        --ofield accession.ena-run.primary_accession ena_run.accession '' \
        --ofield accession.ena-run.secondary_accession ena_run.secondary_accession '' \
        --ofield accession.ena-assembly.primary_accession ena_assembly.accession '' \
        --ofield accession.ena-assembly.secondary_accession ena_assembly.secondary_accession '' > $DATESTAMP.accessions.csv 2> err

$OUTBOUND_SOFTWARE_DIR/accessions/accessions_export_parser.py $DATESTAMP.accessions.csv $ARTIFACTS_ROOT/accessions/$DATESTAMP.accessions.tsv 2> $EAGLEOWL_LOGS/accessions/$DATESTAMP.log

# $OUTBOUND_SOFTWARE_DIR/accessions/accessions_json_to_tsv.py cog2.mdv.json 'GISAID,ENA-SAMPLE,ENA-RUN,ENA-ASSEMBLY' > $DATESTAMP.accessions.tsv 2> $EAGLEOWL_LOGS/accessions/$DATESTAMP.log

cp $ARTIFACTS_ROOT/accessions/$DATESTAMP.accessions.tsv $ARTIFACTS_ROOT/accessions/latest.accessions.tsv
chmod 644 $ARTIFACTS_ROOT/accessions/latest.accessions.tsv

# Dump to s3
s3cmd --config $EAGLEOWL_CONF/outbound/s3cfg put --acl-public $ARTIFACTS_ROOT/accessions/latest.accessions.tsv s3://cog-uk/accessions/latest.tsv
