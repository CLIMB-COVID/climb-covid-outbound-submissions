source ~/.ocarina
DATESTAMP=`date '+%Y%m%d'`
ocarina --env get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name GISAID --task-wait --odelimiter , \
    --ofield owner_org_gisaid_user submitter 'XXX' \
    --ofield consensus.current_path climb_fn 'XXX' \
    --ofield '~hCoV-19/{adm1_trans}/{central_sample_id}/2020' covv_virus_name 'XXX' \
    --ofield collection_date covv_collection_date '2020' \
    --ofield '~{adm0} / {adm1_trans}' covv_location 'XXX' \
    --ofield sequencing.platform covv_seq_technology 'XXX' \
    --ofield owner_org_gisaid_lab_name covv_orig_lab 'XXX' \
    --ofield owner_org_gisaid_lab_addr covv_orig_lab_addr 'XXX' \
    --ofield central_sample_id covv_provider_sample_id unknown \
    --ofield central_sample_id covv_subm_sample_id 'XXX' \
    --ofield owner_org_gisaid_lab_list covv_authors 'XXX' 2> err | csvsort -c 'covv_subm_sample_id' > $DATESTAMP.eligible.csv

csvcut -c climb_fn,covv_virus_name $DATESTAMP.eligible.csv | csvformat -T | sed 1d > $DATESTAMP.eligible.ls
echo "Unique FASTA inputs" `cut -f1 $DATESTAMP.eligible.ls | sort | uniq | wc -l`

