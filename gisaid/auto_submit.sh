#!/usr/bin/bash
source /cephfs/covid/software/eagle-owl/scripts/hootstrap.sh
source "$EAGLEOWL_CONF/common.sh"
source "$EAGLEOWL_CONF/slack.sh"
source "$EAGLEOWL_CONF/outbound/gisaid.sh"
source "$EAGLEOWL_CONF/ocarina/service_outbound.sh"
PATH="$PATH:$OUTBOUND_SOFTWARE_DIR/gisaid"

eval "$(conda shell.bash hook)"
conda activate $CONDA_OUTBOUND

set -euo pipefail

DATESTAMP=$DATE # date sent from mqtt with --payload-passthrough
BEFORE_DATESTAMP=`date -d "$DATESTAMP -2 days" '+%Y-%m-%d'`
echo $DATESTAMP $BEFORE_DATESTAMP

OUTDIR=$OUTBOUND_DIR/gisaid/$DATESTAMP
mkdir -p $OUTDIR
cd $OUTDIR

if [ ! -f "$DATESTAMP.gisaid.csv" ]; then
    ocarina-get-gisaid.sh $DATESTAMP $BEFORE_DATESTAMP
    echo "Ocarina-get-gisaid finished successfully"
else
    echo "ocarina already done"
fi

#Exit early with 0 status if there is no work to do
N_UPLOADS=$(wc -l $DATESTAMP.gisaid.csv | awk '{print $1 - 1}')
if (( $N_UPLOADS < 1 )); then
    echo "Nothing to upload, exiting early"
    exit 0
fi

# Send to GISAID through new API
# Resubmitting everything isn't ideal as it just wastes a bunch of time using gisaid_uploader which is pretty slow (as it transfers each genome one by one and signs all the requests)
# but it's easier than having to post-process the GISAID CSV to remove the successful candidates (and determine whether the failed ones should be resent)
gisaidret=0
if [ ! -f "submission.json" ]; then
    gisaid_uploader -a $EAGLEOWL_TOKENS/GISAID_AUTH CoV authenticate --cid $GISAID_REAL_CID --user $GISAID_USER --pass $GISAID_PASS
    
    set +e
    # Allow for failure to make sure that submissions are submitted in the case of partial failure
    gisaid_uploader -a $EAGLEOWL_TOKENS/GISAID_AUTH -l submission.json -L submission.bk.json CoV upload --fasta $DATESTAMP.gisaid.fa --csv $DATESTAMP.gisaid.csv --failedout $DATESTAMP.gisaid.failed.csv
    gisaidret=$?
    set -e
    
    echo "gisaid uploader finished successfully"
else
    echo "gisaid already done"
fi

if [ -f "submission.json" ]; then
    if [ ! -f "submit_accession.log" ]; then
        # Convert the GISAID response to accessions if we haven't already done so
        set +e
        submission_to_accession.py --response-mode json --response submission.json --csv $DATESTAMP.undup.csv --accessions-table $ARTIFACTS_ROOT/accessions/latest.accessions.tsv > submit_accession.log
        subret=$?
        set -e
        echo "submit_accession done"
    else
        subret=0 # submit_accession.log still exists so we're probably good (we move it if its bad)
        echo "majora already done"
    fi
else
    subret=66 #EX_NOINPUT
fi


# Rename the existing data with some random garbage extension to keep them around but not in the way
set +o pipefail
EXT=`tr -dc a-z </dev/urandom | head -c 3`
set -u pipefail

# Always force accession resubmission on next round if it failed
if [ $subret -ne 0 ]; then
    mv submit_accession.log submit_accession.log.$EXT
fi

if [ $gisaidret -ne 0 ]; then
    if [ $subret -eq 0 ]; then
        # Only rename the submission files if the accession submission was OK
        mv submission.json submission.json.$EXT # try submitting again
        mv submission.bk.json submission.bk.json.$EXT # currently works with hacked gisaid_uploader
    fi
fi

# Sound the alarm
if [ $gisaidret -ne 0 ] || [ $subret -ne 0 ]; then
    MSG='{"text":"<!channel> *COG-UK GISAID submission pipeline failed*
    ...with exit status '"$gisaidret"'
    ...submissions exit status '"$subret"'
    ...submission saved to '"$OUTDIR"' with special ext '"$EXT"'"
    }'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK

    exit $(( gisaidret > subret ? gisaidret : subret ))
fi


tail -n2 submit_accession.log

if [ ! -f "announce.ok" ]; then
    # Tell everyone what a good job we did
    outbound-gisaid-announce.sh $DATESTAMP
    mv $DATESTAMP.undup.csv undup.csv
    ln -fn -s $OUTBOUND_DIR/gisaid/$DATESTAMP $OUTBOUND_DIR/gisaid/latest
    touch announce.ok
fi


MSG='{"text":"*COG-UK GISAID submission pipeline finished*"}'
curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK

