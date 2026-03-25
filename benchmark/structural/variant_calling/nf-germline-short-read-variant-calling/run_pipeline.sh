# cloning repo
git clone https://github.com/nttg8100/nf-germline-short-read-variant-calling.git -b 0.8.0

# Call using multiple structural variant caller, cram files are reused from previous small variant calling alignment files
nextflow run nf-germline-short-read-variant-calling \
    --input assets/HG002.csv \
    --outdir HG002 \
    -profile docker \
    --structural_variant_caller="manta,tiddit,delly,cnvnator,smoove" \
    -resume