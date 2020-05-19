#ocarina --env get pag --test-name 'cog-uk-high-quality-public' --pass --private --service-name ENA-RUN

ocarina --env get pag --test-name 'cog-uk-high-quality-public' --task-id $1 --odelimiter , \
    --ffield-true owner_org_ena_opted \
    --ofield '~COG-UK/{central_sample_id}' ena_sample_name 'XXX' \
    --ofield central_sample_id central_sample_id 'XXX' \
    --ofield submission_org_lab_or_name sample_center_name 'XXX' \
    --ofield submission_org_code sample_center_code 'XXX' \
    --ofield collection_date collection_date '2020' \
    --ofield - adm0 'United Kingdom' \
    --ofield adm1_trans adm1 'XXX' \
    --ofield published_name published_name 'XXX' \
    --ofield alignment.current_path climb_fn 'XXX' \
    --ofield owner_org_lab_or_name run_center_name 'XXX' > $1.ena.csv 2> err

