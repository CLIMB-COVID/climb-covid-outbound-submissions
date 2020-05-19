import sys
import csv

# usage: pyena_to_majora.py <pyena_output>

for line in open(sys.argv[1]):
    success, real, sample, run, bam, study_acc, sample_acc, exp_acc, run_acc = line.strip().split(' ')
    if success == '1' and real == '1':
        published_name = "%s/%s" % (sample, run)
        print("ocarina --env put publish --publish-group '%s' --service 'ENA-SAMPLE' --accession %s --public" % (published_name, sample_acc))
        print("ocarina --env put publish --publish-group '%s' --service 'ENA-RUN' --accession %s --public" % (published_name, run_acc))
