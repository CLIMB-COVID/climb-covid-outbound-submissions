#!/usr/bin/bash
source /cephfs/covid/software/eagle-owl/scripts/hootstrap.sh
source "$EAGLEOWL_CONF/common.sh"
source "$EAGLEOWL_CONF/ocarina/service_outbound.sh"

BEFORE_DATESTAMP=$1
set -euo pipefail
ocarina --env --oauth get pag --test-name 'cog-uk-elan-minimal-qc' --pass --private --service-name ENA-ASSEMBLY --task-wait --task-wait-attempts 60 --odelimiter , --mode 'ena-assembly' --published-before $BEFORE_DATESTAMP \
    --ffield-true owner_org_ena_assembly_opted \
    --ofield credit_code credit_code 'XXX' \
    --ofield collection_date collection_date '' \
    --ofield published_date published_date 'XXX' \
    --ofield received_date received_date '' \
    --ofield - adm0 'United Kingdom' \
    --ofield adm1_trans adm1 'XXX' \
    --ofield credit_lab_name center_name 'XXX' \
    --ofield credit_lab_addr address 'XXX' \
    --ofield credit_lab_list authors 'XXX' \
    --ofield '~{instrument_make} {instrument_model}' platform 'XXX' \
    --ofield central_sample_id central_sample_id 'XXX' \
    --ofield central_sample_id biosample_id 'XXX' \
    --ofield anonymous_sample_id anonymous_sample_id '' \
    --ofield published_name published_name 'XXX' \
    --ofield published_uuid published_uuid 'XXX' \
    --ofield consensus.current_path climb_fn 'XXX' \
    --ofield consensus.pipe_name assembler 'unknown' \
    --ofield consensus.pipe_version assembler_version '' \
    --ofield alignment.mean_cov mean_cov 'unknown' \
    --ofield qc.cog_uk_elan_minimal_qc cog_basic_qc 'XXX' \
    --ofield qc.cog_uk_high_quality_public cog_high_qc 'XXX' \
    --ofield accession.ena-sample.primary_accession ena_sample_id '' \
    --ofield accession.ena-run.primary_accession ena_run_id '' > ena-assembly.csv 2> err