source ~/.ocarina
DATESTAMP=`date '+%Y%m%d'`

AUTHORS=`cut -f1 -d',' $DATESTAMP.gisaid.csv | sort | uniq -c | grep -v 'submitter'`
SUBMISSIONS=`wc -l $DATESTAMP.gisaid.csv | cut -f1 -d' '`
SUBMISSIONS=$((SUBMISSIONS-1))

MSG='{"text":"<!channel>
*COG-UK outbound-distribution GISAID report*
'$SUBMISSIONS' new submissions today
***
*Submissions by GISAID username*
'"\`\`\`${AUTHORS}\`\`\`"'
"}'

echo $MSG

curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK
