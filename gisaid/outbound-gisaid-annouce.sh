source ~/.ocarina
DATESTAMP=`date '+%Y%m%d'`

AUTHORS=`cut -f1 -d',' $COG_OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.gisaid.csv | sort | uniq -c | grep -v 'submitter'`
SUBMISSIONS=`wc -l $COG_OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.gisaid.csv | cut -f1 -d' '`
SUBMISSIONS=$((SUBMISSIONS-1))

MSG='{"text":"<!channel>
*COG-UK outbound-distribution GISAID report*
'$SUBMISSIONS' new submissions today
***
*Submissions by GISAID username*
'"\`\`\`${AUTHORS}\`\`\`"'
"}'

curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK

python $ELAN_SOFTWARE_DIR/bin/control/mails/send_mail.py -s "COGUK GISAID $DATESTAMP" -t $GISAID_MAIL -t $MAJE_MAINTAINER --body-start "Hi ${GISAID_NAME}" -a $COG_OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.gisaid.fa.gz -a $COG_OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.gisaid.csv -b $ELAN_SOFTWARE_DIR/bin/control/mails/gisaid.txt --reply-to $MAJE_MAINTAINER -f 'Sam Nicholls | Majora COG-UK'
