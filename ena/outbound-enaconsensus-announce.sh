source /cephfs/covid/software/eagle-owl/scripts/hootstrap.sh
source "$EAGLEOWL_CONF/common.sh"
source "$EAGLEOWL_CONF/slack.sh"
PATH="$PATH:$OUTBOUND_SOFTWARE_DIR/ena"

DATESTAMP=$1
OUTDIR=$OUTBOUND_DIR/ena-a/$DATESTAMP

SLACK_HOOK=$SLACK_OUTBOUND_HOOK
if  [ ! -z "$OUTBOUND_TEST" ]; then
    SLACK_HOOK=$SLACK_TEST_HOOK
    OUTDIR=$EAGLEOWL/scratch/ena_test/ena-a/$DATESTAMP
fi

cd $OUTDIR

AUTHORS=`tail -n+2 accessions.ls | cut -f1 -d' ' | cut -f3 -d'/' | cut -f1 -d':' | sort | uniq -c | sort -n`
SUBMISSIONS=`wc -l accessions.ls | cut -f1 -d' '`
SUBMISSIONS=$((SUBMISSIONS-1))

MSG='{"text":"<!channel>
*COG-UK outbound-distribution ENA consensus report*
'$SUBMISSIONS' new submissions today
***
*Submissions by sequencing site code*
'"\`\`\`${AUTHORS}\`\`\`"'
See https://docs.covid19.climb.ac.uk/ena_consensus for more details 
"}'

curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_HOOK

