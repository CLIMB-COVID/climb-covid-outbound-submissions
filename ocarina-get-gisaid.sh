#ocarina --env get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name GISAID
ocarina --env get pag --test-name 'cog-uk-high-quality-public' --task-id $1 --odelimiter , \
    --ffield-true owner_org_gisaid_opted \
    --ofield owner_org_gisaid_user submitter 'XXX' \
    --ofield consensus.current_path climb_fn 'XXX' \
    --ofield - fn $1.gisaid.fa \
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
    --ofield owner_org_gisaid_lab_list covv_authors 'XXX' 2> err | csvsort -c 'covv_subm_sample_id' > $1.csv

csvcut -c climb_fn,covv_virus_name $1.csv | csvformat -T | sed 1d > $1.ls
echo "Unique FASTA inputs" `cut -f1 $1.ls | sort | uniq | wc -l`

python remove_ls_dups_for_now.py $1.ls $1.undup.ls $1.csv $1.undup.csv

rm $1.gisaid.fa

cat $1.undup.ls | while read fn header;
do
    ../elan/bin/elan_rehead.py $fn $header >> $1.gisaid.fa;
    echo $? $fn $header;
done

echo "Unique sequences output to FASTA" `grep '^>' $1.gisaid.fa | sort | uniq | wc -l`

csvcut -C climb_fn $1.undup.csv > $1.gisaid.csv
echo "Unique samples in GISAID metadata" `csvcut -c covv_subm_sample_id $1.gisaid.csv | sed 1d | wc -l`

gzip $1.gisaid.fa
