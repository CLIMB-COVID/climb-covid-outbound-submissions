ocarina --env get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name ENA-RUN --task-wait --task-wait-attempts 60 --odelimiter , \
    --ffield-true owner_org_ena_opted \
    --ofield '~COG-UK/{central_sample_id}' ena_sample_name 'XXX' \
    --ofield central_sample_id central_sample_id 'XXX' \
    --ofield submission_org_credit_name sample_center_name 'XXX' \
    --ofield submission_org_code sample_center_code 'XXX' \
    --ofield collection_date collection_date '2020' \
    --ofield received_date received_date '' \
    --ofield - adm0 'United Kingdom' \
    --ofield adm1_trans adm1 'XXX' \
    --ofield published_name published_name 'XXX' \
    --ofield alignment.current_path climb_fn 'XXX' \
    --ofield credit_lab_name run_center_name 'XXX' \
    --ofield accession.gisaid.secondary_accession virus_identifier 'not provided' \
    --ofield min_ct min_ct_value '' \
    --ofield max_ct max_ct_value '' > ena.csv 2> err

