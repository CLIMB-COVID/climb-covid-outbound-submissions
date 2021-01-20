#!/usr/bin/bash
source ~/.ocarina
set -euo pipefail
DATESTAMP=`date '+%Y%m%d'`
ocarina --env get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name GISAID --task-wait --task-wait-attempts 30 --odelimiter , \
    --ffield-true owner_org_gisaid_opted \
    --ofield published_name pag_name 'XXX' \
    --ofield owner_org_gisaid_user submitter 'XXX' \
    --ofield consensus.current_path climb_fn 'XXX' \
    --ofield - fn $DATESTAMP.gisaid.fa \
    --ofield '~hCoV-19/{adm1_trans}/{central_sample_id}/2020' covv_virus_name 'XXX' \
    --ofield - covv_type betacoronavirus \
    --ofield - covv_passage Original \
    --ofield collection_date covv_collection_date '2020' \
    --ofield '~Europe / {adm0} / {adm1_trans}' covv_location 'XXX' \
    --ofield - covv_add_location ' ' \
    --ofield - covv_host Human \
    --ofield - covv_add_host_info ' ' \
    --ofield - covv_gender '' \
    --ofield - covv_patient_age '' \
    --ofield - covv_patient_status '' \
    --ofield - covv_specimen '' \
    --ofield - covv_outbreak '' \
    --ofield - covv_last_vaccinated '' \
    --ofield - covv_treatment '' \
    --ofield sequencing.platform covv_seq_technology 'XXX' \
    --ofield - covv_assembly_method '' \
    --ofield - covv_coverage '' \
    --ofield owner_org_gisaid_lab_name covv_orig_lab 'XXX' \
    --ofield owner_org_gisaid_lab_addr covv_orig_lab_addr 'XXX' \
    --ofield central_sample_id covv_provider_sample_id '' \
    --ofield - covv_subm_lab 'COVID-19 Genomics UK (COG-UK) Consortium' \
    --ofield - covv_subm_lab_addr 'United Kingdom' \
    --ofield central_sample_id covv_subm_sample_id 'XXX' \
    --ofield owner_org_gisaid_lab_list covv_authors 'XXX' 2> err | csvsort -c 'covv_subm_sample_id' > $DATESTAMP.csv

csvcut -c climb_fn,covv_virus_name $DATESTAMP.csv | csvformat -T | sed 1d > $DATESTAMP.ls
echo "Unique FASTA inputs" `cut -f1 $DATESTAMP.ls | sort | uniq | wc -l`

remove_ls_dups_for_now.py $DATESTAMP.ls $DATESTAMP.undup.ls $DATESTAMP.csv $DATESTAMP.undup.csv 2> $DATESTAMP.undup.log

rm -f $DATESTAMP.gisaid.fa

cat $DATESTAMP.undup.ls | while read fn header;
do
    elan_rehead.py $fn $header >> $DATESTAMP.gisaid.fa;
    echo $? $fn $header;
done

echo "Unique sequences output to FASTA" `grep '^>' $DATESTAMP.gisaid.fa | sort | uniq | wc -l`

csvcut -C pag_name,climb_fn $DATESTAMP.undup.csv > $DATESTAMP.gisaid.csv
echo "Unique samples in GISAID metadata" `csvcut -c covv_subm_sample_id $DATESTAMP.gisaid.csv | sed 1d | wc -l`

gzip $DATESTAMP.gisaid.fa

cut -f1 -d',' $DATESTAMP.gisaid.csv | sort | uniq -c | grep -v 'submitter'
