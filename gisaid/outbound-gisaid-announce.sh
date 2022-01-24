source ~/.bootstrap.sh

source "$EAGLEOWL_CONF/paths.env"
source "$EAGLEOWL_CONF/slack.env"
DATESTAMP=$1

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

