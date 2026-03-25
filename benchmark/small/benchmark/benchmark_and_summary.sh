#!/bin/bash
# Benchmark script for HG002 with DeepVariant, FreeBayes, HaplotypeCaller, Manta, Strelka (relative paths)
set -euo pipefail


### INPUTS ###
REF_DIR="../../references"
SAMPLE="HG002"
BED="$REF_DIR/${SAMPLE}_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"
TRUTH="$REF_DIR/${SAMPLE}_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
SDF="$REF_DIR/grch38.sdf"
export HGREF="$REF_DIR/Homo_sapiens_assembly38.fasta"
THREADS=16

### SAREK 3.7.1 ###
RESULT_SDIR="sarek"
mkdir -p "$RESULT_SDIR"

TOOLS=(deepvariant freebayes haplotypecaller strelka)
VCF_DIR="../variant_calling/sarek"
VCF_DEEPVARIANT="$VCF_DIR/deepvariant/HG002/HG002.deepvariant.vcf.gz"
VCF_FREEBAYES="$VCF_DIR/freebayes/HG002/HG002.freebayes.vcf.gz"
VCF_HAPLOTYPECALLER="$VCF_DIR/haplotypecaller/HG002/HG002.haplotypecaller.vcf.gz"
VCF_STRELKA="$VCF_DIR/strelka/HG002/HG002.strelka.variants.vcf.gz"

# Path map
declare -A VCF_PATHS=(
  [deepvariant]="$VCF_DEEPVARIANT"
  [freebayes]="$VCF_FREEBAYES"
  [haplotypecaller]="$VCF_HAPLOTYPECALLER"
  [strelka]="$VCF_STRELKA"
)

for TOOL in "${TOOLS[@]}"; do
  TOOLDIR="$RESULT_SDIR/$TOOL"
  mkdir -p "$TOOLDIR"
  VCF="${VCF_PATHS[$TOOL]}"
  LOG="$TOOLDIR/${SAMPLE}_${TOOL}.log"
  SUMMARY="$TOOLDIR/${SAMPLE}_${TOOL}.summary.csv"
  FORMATTED="$TOOLDIR/${SAMPLE}_${TOOL}.formatted.summary.csv"
  OUTPUT="$TOOLDIR/${SAMPLE}_${TOOL}"

  # If the tool output folder already exists with summary file, continue from AWK formatting (line 55)
  if [[ -f "${OUTPUT}.summary.csv" ]]; then
    echo "Output for $TOOL already exists, formatting summary."
    awk -v d="${TOOL}_${SAMPLE}" -F',' 'FNR==1{a="run"} FNR>1{a=d} {print $0",\t"a}' "${OUTPUT}.summary.csv" > "$FORMATTED"
    echo "Completed $TOOL (using existing output)"
    continue
  fi

  if [[ ! -f "$VCF" ]]; then
    echo "VCF file not found for $TOOL: $VCF" >&2
    continue
  fi

  echo "Benchmarking $TOOL for $SAMPLE ..."
  hap.py "$TRUTH" "$VCF" \
    -o "$OUTPUT" \
    -V --engine=vcfeval --threads "$THREADS" --engine-vcfeval-template "$SDF" \
    -f "$BED" \
    --logfile "$LOG" \
    --scratch-prefix .

  if [[ -f "${OUTPUT}.summary.csv" ]]; then
    awk -v d="${TOOL}_${SAMPLE}" -F',' 'FNR==1{a="run"} FNR>1{a=d} {print $0",\t"a}' "${OUTPUT}.summary.csv" > "$FORMATTED"
  else
    echo "Warning: ${OUTPUT}.summary.csv not found for $TOOL" >&2
  fi

  echo "Completed $TOOL"
done

MERGED="$RESULT_SDIR/snpindels_merged_${SAMPLE}_benchmark.csv"
echo "Merging summaries to $MERGED ..."
awk '(NR == 1) || (FNR > 1)' "$RESULT_SDIR"/*/*.formatted.summary.csv > "$MERGED"
echo "All done. Results for $SAMPLE in $MERGED"


### THIS PIPELINE 0.8.0 ### 
RESULTS_DIR="nf-germline-short-read-variant-calling"
TOOLS=(freebayes deepvariant)
VCF_DIR="../variant_calling/nf-germline-short-read-variant-calling"
VCF_FREEBAYES="$VCF_DIR/freebayes/HG002.vcf.gz"
VCF_DEEPVARIANT="$VCF_DIR/deepvariant/HG002.vcf.gz"

# Create output files
mkdir -p "$RESULTS_DIR"

# Path map
declare -A VCF_PATHS=(
  [freebayes]="$VCF_FREEBAYES"
  [deepvariant]="$VCF_DEEPVARIANT"
)
pwd
for TOOL in "${TOOLS[@]}"; do
  TOOLDIR="$RESULTS_DIR/$TOOL"
  mkdir -p "$TOOLDIR"
  VCF="${VCF_PATHS[$TOOL]}"
  LOG="$TOOLDIR/${SAMPLE}_${TOOL}.log"
  SUMMARY="$TOOLDIR/${SAMPLE}_${TOOL}.summary.csv"
  FORMATTED="$TOOLDIR/${SAMPLE}_${TOOL}.formatted.summary.csv"
  OUTPUT="$TOOLDIR/${SAMPLE}_${TOOL}"

  # If the tool output folder already exists with summary file, continue from AWK formatting (line 55)
  if [[ -f "${OUTPUT}.summary.csv" ]]; then
    echo "Output for $TOOL already exists, formatting summary."
    awk -v d="${TOOL}_${SAMPLE}" -F',' 'FNR==1{a="run"} FNR>1{a=d} {print $0",\t"a}' "${OUTPUT}.summary.csv" > "$FORMATTED"
    echo "Completed $TOOL (using existing output)"
    continue
  fi

  if [[ ! -f "$VCF" ]]; then
    echo "VCF file not found for $TOOL: $VCF" >&2
    continue
  fi

  echo "Benchmarking $TOOL for $SAMPLE ..."
  hap.py "$TRUTH" "$VCF" \
    -o "$OUTPUT" \
    -V --engine=vcfeval --threads "$THREADS" --engine-vcfeval-template "$SDF" \
    -f "$BED" \
    --logfile "$LOG" \
    --scratch-prefix .

  if [[ -f "${OUTPUT}.summary.csv" ]]; then
    awk -v d="${TOOL}_${SAMPLE}" -F',' 'FNR==1{a="run"} FNR>1{a=d} {print $0",\t"a}' "${OUTPUT}.summary.csv" > "$FORMATTED"
  else
    echo "Warning: ${OUTPUT}.summary.csv not found for $TOOL" >&2
  fi

  echo "Completed $TOOL"
done

MERGED="$RESULTS_DIR/snpindels_merged_${SAMPLE}_benchmark.csv"
echo "Merging summaries to $MERGED ..."
awk '(NR == 1) || (FNR > 1)' "$RESULTS_DIR"/*/*.formatted.summary.csv > "$MERGED"
echo "All done. Results for $SAMPLE in $MERGED"