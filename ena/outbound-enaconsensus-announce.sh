source ~/.ocarina

DATESTAMP=$1
OUTDIR=$COG_OUTBOUND_DIR/ena-a/$DATESTAMP
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
"}'

curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK

