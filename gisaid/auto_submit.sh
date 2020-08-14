eval "$(conda shell.bash hook)"
conda activate samstudio8
source ~/.ocarina
set -euo pipefail

DATESTAMP=`date '+%Y%m%d'`

mkdir $COG_OUTBOUND_DIR/gisaid/$DATESTAMP
cd $COG_OUTBOUND_DIR/gisaid/$DATESTAMP

ocarina-get-gisaid.sh

gisaid_submitted_to_majora.py $COG_OUTBOUND_DIR/gisaid/$DATESTAMP/$DATESTAMP.undup.csv > submitted.ocarina.sh
bash submitted.ocarina.sh > submitted.ocarina.sh.log 2> /dev/null

outbound-gisaid-announce.sh $DATESTAMP

mv $DATESTAMP.undup.csv undup.csv
ln -fn -s $COG_OUTBOUND_DIR/gisaid/$DATESTAMP $COG_OUTBOUND_DIR/gisaid/latest
