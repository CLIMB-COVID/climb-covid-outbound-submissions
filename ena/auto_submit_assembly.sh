#!/usr/bin/bash
source ~/.bootstrap.sh

source "$EAGLEOWL_CONF/webin.env" # adds to PATH and WEBIN vars
source "$EAGLEOWL_CONF/paths.env"
source "$EAGLEOWL_CONF/slack.env"
source "$EAGLEOWL_CONF/envs.env"
source "$EAGLEOWL_CONF/service_outbound.env"

eval "$(conda shell.bash hook)"
conda activate $CONDA_OUTBOUND

DATESTAMP=$1
WEBIN_JAR="$WEBIN_DIR/webin-cli-4.2.1.jar"

mkdir -p $COG_OUTBOUND_DIR/ena-a/$DATESTAMP
OUTDIR=$COG_OUTBOUND_DIR/ena-a/$DATESTAMP
cd $OUTDIR

if [ ! -f "erz.nf.csv" ]; then
    ocarina-get-ena-assembly.sh
    metadata_to_erz_csv.py ena-assembly.csv > erz.nf.csv 2> make_csv.log
fi

# Send
PHASE1_OK_FLAG="$OUTDIR/enaa.ok.flag"
PHASE1_LOG="$OUTDIR/nextflow.stdout"

$NEXTFLOW_BIN pull samstudio8/elan-ena-nextflow # always use latest stable

if [ ! -f "$PHASE1_OK_FLAG" ]; then
    RESUME_FLAG=""

    if [ -f "$PHASE1_LOG" ]; then
        # If the log exists, resume
        RESUME_FLAG="-resume"
        MSG='{"text":"*COG-UK ENA-A consensus pipeline* Using -resume to re-raise without trashing everything. Delete today'\''s log to force a full restart."}'
        curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    fi
    $NEXTFLOW_BIN run samstudio8/elan-ena-nextflow -c $ELAN_SOFTWARE_DIR/elan.ena_a.config -r stable --study $COG_ENA_STUDY --manifest erz.nf.csv --webin_jar $WEBIN_JAR --out $OUTDIR/accessions.ls --ascp --description 'COG_ACCESSION:${-> row.published_name}; COG_BASIC_QC:${-> row.cog_basic_qc}; COG_HIGH_QC:${-> row.cog_high_qc}; COG_NOTE:Sample metadata and QC flags may have been updated since deposition in public databases. COG-UK recommends users refer to data.covid19.climb.ac.uk for latest metadata and QC tables before conducting analysis.' $RESUME_FLAG > $PHASE1_LOG
    ret=$?
    if [ $ret -ne 0 ]; then
        lines=`tail -n 25 $PHASE1_LOG`
    else
        touch $PHASE1_OK_FLAG
        lines=`awk -vRS= 'END{print}' $PHASE1_LOG`
    fi
    mv .nextflow.log $OUTDIR/nextflow.log

    MSG='{"text":"*COG-UK ENA-A consensus pipeline finished...*
    ...with exit status '"$ret"'
    '"\`\`\`${lines}\`\`\`"'"
    }'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    if [ $ret -ne 0 ]; then
        exit $ret;
    fi
else
    MSG='{"text":"*COG-UK ENA pipeline* Cowardly skipping ENA-A as the OK flag already exists for today"}'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
fi

# PUBLISH
ena_accession_to_majora.py --accessions $OUTDIR/accessions.ls 2> $OUTDIR/majora_accessions.err
ret=$?
if [ $ret -ne 0 ]; then
    lines=`tail -n 25 $OUTDIR/majora_accessions.err | sed 's,",,g'`
    MSG='{"text":"*COG-UK ENA-A consensus pipeline finished...*
    ...with exit status '"$ret"'
    '"\`\`\`${lines}\`\`\`"'"
    }'
    curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK
    exit $ret
fi

MSG='{"text":"*COG-UK ENA-A consensus pipeline* Accessions added successfully."}'
curl -X POST -H 'Content-type: application/json' --data "$MSG" $SLACK_MGMT_HOOK

# Tell everyone what a good job we did
outbound-enaconsensus-announce.sh $DATESTAMP
