#!/usr/bin/bash
source ~/.path
eval "$(conda shell.bash hook)"
conda activate samstudio8
source ~/.ocarina
set -euo pipefail

DATESTAMP=`date '+%Y%m%d'`

mkdir $COG_OUTBOUND_DIR/gisaid/$DATESTAMP
cd $COG_OUTBOUND_DIR/gisaid/$DATESTAMP

ocarina-get-gisaid.sh

# Send to GISAID through new API
gisaid_uploader -a $GISAID_AUTH CoV authenticate --cid $GISAID_REAL_CID --user $GISAID_USER --pass $GISAID_PASS
gisaid_uploader -a $GISAID_AUTH -l submission.json CoV upload --fasta $DATESTAMP.gisaid.fa --csv $DATESTAMP.gisaid.csv --failedout $DATESTAMP.gisaid.failed.csv

# Convert the GISAID response to accessions (and errors)
submission_to_accession.py --mode json submission.json $DATESTAMP.covv.csv > submit_accession.log

# Tell everyone what a good job we did
outbound-gisaid-announce.sh $DATESTAMP

mv $DATESTAMP.undup.csv undup.csv
ln -fn -s $COG_OUTBOUND_DIR/gisaid/$DATESTAMP $COG_OUTBOUND_DIR/gisaid/latest
