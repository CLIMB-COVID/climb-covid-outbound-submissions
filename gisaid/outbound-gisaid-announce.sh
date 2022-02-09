source /cephfs/covid/software/eagle-owl/scripts/hootstrap.sh
source "$EAGLEOWL_CONF/common.sh"
source "$EAGLEOWL_CONF/slack.sh"
PATH="$PATH:$OUTBOUND_SOFTWARE_DIR/gisaid"

set -euo pipefail

DATESTAMP=$1

AUTHORS=`cut -f1 -d',' $OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.gisaid.csv | sort | uniq -c | grep -v 'submitter'`
SUBMISSIONS=`wc -l $OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.gisaid.csv | cut -f1 -d' '`
SUBMISSIONS=$((SUBMISSIONS-1))

MSG='{"text":"<!channel>
*COG-UK outbound-distribution GISAID report*
'$SUBMISSIONS' new submissions today
***
*Submissions by GISAID username*
'"\`\`\`${AUTHORS}\`\`\`"'
"}'

curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_OUTBOUND_HOOK

