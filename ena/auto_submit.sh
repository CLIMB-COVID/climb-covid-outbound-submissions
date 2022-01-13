#!/usr/bin/bash
source ~/.bootstrap.sh

source "$EAGLEOWL_CONF/webin.env" # adds PATH and WEBIN vars
source "$EAGLEOWL_CONF/paths.env"
source "$EAGLEOWL_CONF/slack.env"
source "$EAGLEOWL_CONF/envs.env"
source "$EAGLEOWL_CONF/service_outbound.env"

eval "$(conda shell.bash hook)"
conda activate $CONDA_OUTBOUND

DATESTAMP=$1

mkdir -p $COG_OUTBOUND_DIR/ena/$DATESTAMP
cd $COG_OUTBOUND_DIR/ena/$DATESTAMP

if [ ! -f "ena.nf.csv" ]; then
    ocarina-get-ena.sh
    bind_ena_table_to_meta.py ena.csv $COG_PUBLISHED_DIR/majora.latest.metadata.tsv > ena.nf.csv
fi

cd $ELAN_SOFTWARE_DIR/bam

# DEHUMANIZE
PHASE1_OK_FLAG="$COG_OUTBOUND_DIR/ena/$DATESTAMP/dh1.ok.flag"
PHASE1_LOG="$COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.stdout"

if [ ! -f "$PHASE1_OK_FLAG" ]; then
    RESUME_FLAG=""

    if [ -f "$PHASE1_LOG" ]; then
        # If the log exists, resume
        RESUME_FLAG="-resume"
        MSG='{"text":"*COG-UK ENA pipeline* Using -resume to re-raise PHASE1 DH without trashing everything. Delete today'\''s log to force a full restart."}'
        curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    fi
    $NEXTFLOW_BIN run dehuman.nf -c $ELAN_SOFTWARE_DIR/elan.config --manifest $COG_OUTBOUND_DIR/ena/$DATESTAMP/ena.nf.csv --datestamp $DATESTAMP --study PRJEB37886 --publish $ELAN_DIR $RESUME_FLAG > $PHASE1_LOG
    ret=$?
    if [ $ret -ne 0 ]; then
        lines=`tail -n 25 $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.stdout`
    else
        touch $PHASE1_OK_FLAG
        lines=`awk -vRS= 'END{print}' $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.stdout`
    fi
    mv .nextflow.log $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.log

    MSG='{"text":"*COG-UK ENA dehumanizing pipeline (phase 1) finished...*
    ...with exit status '"$ret"'
    '"\`\`\`${lines}\`\`\`"'"
    }'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    if [ $ret -ne 0 ]; then
        exit $ret;
    fi
else
    MSG='{"text":"*COG-UK ENA pipeline* Cowardly skipping dehumanisation as the OK flag already exists for today"}'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
fi

# PUBLISH
PHASE2_OK_FLAG="$COG_OUTBOUND_DIR/ena/$DATESTAMP/dh2.ok.flag"
PHASE2_LOG="$COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.post.stdout"

if [ ! -f "$PHASE2_OK_FLAG" ]; then
    RESUME_FLAG=""

    if [ -f "$PHASE2_LOG" ]; then
        # If the log exists, resume
        RESUME_FLAG="-resume"
        MSG='{"text":"*COG-UK ENA pipeline* Using -resume to re-raise PHASE2 ENA submission without trashing everything. Delete today'\''s log to force a full restart."}'
        curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    fi
    $NEXTFLOW_BIN run dehuman-post.nf -c $ELAN_SOFTWARE_DIR/elan.config --manifest $ELAN_DIR/staging/dh/$DATESTAMP/ascp.files.ls --datestamp $DATESTAMP --study PRJEB37886 --publish $ELAN_DIR --ascpbin $ASCP_BIN $RESUME_FLAG > $PHASE2_LOG
    ret=$?
    if [ $ret -ne 0 ]; then
        lines=`tail -n 25 $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.post.stdout`
    else
        lines=`awk -vRS= 'END{print}' $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow.post.stdout`
        touch $PHASE2_OK_FLAG
    fi
    mv .nextflow.log $COG_OUTBOUND_DIR/ena/$DATESTAMP/nextflow-post.log
    MSG='{"text":"*COG-UK ENA publishing pipeline (phase 2) finished...*
    ...with exit status '"$ret"'
    '"\`\`\`${lines}\`\`\`"'"
    }'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    if [ $ret -ne 0 ]; then
        exit $ret;
    fi
else
    MSG='{"text":"*COG-UK ENA pipeline* Cowardly skipping submission the OK flag already exists for today"}'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
fi
