source ~/.ocarina
DATESTAMP=`date '+%Y%m%d'`
ocarina --env get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name GISAID --task-wait --odelimiter , \
    --ffield-true owner_org_gisaid_opted \
    --ofield owner_org_gisaid_user submitter 'XXX' \
    --ofield consensus.current_path climb_fn 'XXX' \
    --ofield - fn $DATESTAMP.gisaid.fa \
    --ofield '~hCoV-19/{adm1_trans}/{central_sample_id}/2020' covv_virus_name 'XXX' \
    --ofield - covv_type betacoronavirus \
    --ofield - covv_passage Original \
    --ofield collection_date covv_collection_date '2020' \
    --ofield '~{adm0} / {adm1_trans}' covv_location 'XXX' \
    --ofield - covv_add_location ' ' \
    --ofield - covv_host Human \
    --ofield - covv_add_host_info ' ' \
    --ofield - covv_gender unknown \
    --ofield - covv_patient_age unknown \
    --ofield - covv_patient_status unknown \
    --ofield - covv_specimen unknown \
    --ofield - covv_outbreak unknown \
    --ofield - covv_last_vaccinated unknown \
    --ofield - covv_treatment unknown \
    --ofield sequencing.platform covv_seq_technology 'XXX' \
    --ofield - covv_assembly_method unknown \
    --ofield - covv_coverage unknown \
    --ofield owner_org_gisaid_lab_name covv_orig_lab 'XXX' \
    --ofield owner_org_gisaid_lab_addr covv_orig_lab_addr 'XXX' \
    --ofield central_sample_id covv_provider_sample_id unknown \
    --ofield - covv_subm_lab 'COVID-19 Genomics UK (COG-UK) Consortium' \
    --ofield - covv_subm_lab_addr 'United Kingdom' \
    --ofield central_sample_id covv_subm_sample_id 'XXX' \
    --ofield owner_org_gisaid_lab_list covv_authors 'XXX' 2> err | csvsort -c 'covv_subm_sample_id' > $DATESTAMP.csv

csvcut -c climb_fn,covv_virus_name $DATESTAMP.csv | csvformat -T | sed 1d > $DATESTAMP.ls
echo "Unique FASTA inputs" `cut -f1 $DATESTAMP.ls | sort | uniq | wc -l`

remove_ls_dups_for_now.py $DATESTAMP.ls $DATESTAMP.undup.ls $DATESTAMP.csv $DATESTAMP.undup.csv

rm -f $DATESTAMP.gisaid.fa

cat $DATESTAMP.undup.ls | while read fn header;
do
    elan_rehead.py $fn $header >> $DATESTAMP.gisaid.fa;
    echo $? $fn $header;
done

echo "Unique sequences output to FASTA" `grep '^>' $DATESTAMP.gisaid.fa | sort | uniq | wc -l`

csvcut -C climb_fn $DATESTAMP.undup.csv > $DATESTAMP.gisaid.csv
echo "Unique samples in GISAID metadata" `csvcut -c covv_subm_sample_id $DATESTAMP.gisaid.csv | sed 1d | wc -l`

gzip $DATESTAMP.gisaid.fa

cut -f1 -d',' $1.DATESTAMP.gisaid.csv | sort | uniq -c | grep -v 'submitter'
