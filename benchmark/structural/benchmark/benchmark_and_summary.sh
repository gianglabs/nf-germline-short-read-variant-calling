#!/bin/bash

# Benchmark script for HG002 SV variants using Truvari (Sarek pipeline)
# Converts query VCFs from hg38 to hg19 to match truth set coordinates
set -euo pipefail
REF_DIR="../../references"
HGREF="$REF_DIR/human_g1k_v37_decoy.fasta"
SAMPLE="HG002"
# Truth set in hg19 (original coordinates)
SV_TRUTH="$REF_DIR/HG002_SVs_Tier1_v0.6.vcf.gz"
SV_BED="$REF_DIR/HG002_SVs_Tier1_v0.6.bed"
# Chain file for hg38 to hg19 conversion
CHAIN_FILE="$REF_DIR/hg38ToHg19.over.chain.gz"


### SAREK 3.7.1 ###
RESULTS_DIR="sarek/structural"
mkdir -p "$RESULTS_DIR"

# Define SV callers available from Sarek pipeline
TOOLS=(manta)

# VCF paths for SV callers from Sarek (hg38 coordinates)
VCF_DIR="../variant_calling/sarek"
VCF_MANTA="$VCF_DIR/manta/HG002.manta.diploid_sv.vcf.gz"

# Path map
declare -A VCF_PATHS=(
  [manta]="$VCF_MANTA"
)

for TOOL in "${TOOLS[@]}"; do
  TOOLDIR="$RESULTS_DIR/$TOOL"
  mkdir -p "$TOOLDIR"
  VCF_HG38="${VCF_PATHS[$TOOL]}"
  VCF_HG19="$TOOLDIR/${SAMPLE}_${TOOL}_hg19.vcf.gz"
  LOG="$TOOLDIR/${SAMPLE}_${TOOL}.log"
  OUTPUT="$TOOLDIR/${SAMPLE}_${TOOL}"
  TRUVARI_OUTPUT="$OUTPUT.truvari"
  SUMMARY="$TOOLDIR/${SAMPLE}_${TOOL}.summary.txt"
  CONVERSION_LOG="$TOOLDIR/${SAMPLE}_${TOOL}_conversion.log"

  ##### Convert VCF from hg38 to hg19 using CrossMap
  echo "Converting $TOOL VCF from hg38 to hg19..."
  # Normalize the VCF before conversion to ensure consistent representation of variants
  bcftools norm -m -any -o "$TOOLDIR/${SAMPLE}_${TOOL}_hg38_normalized.vcf" "$VCF_HG38"

  CrossMap vcf \
    "$CHAIN_FILE" \
    "$TOOLDIR/${SAMPLE}_${TOOL}_hg38_normalized.vcf" \
    "$HGREF" \
    "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_raw.vcf" \
    > "$CONVERSION_LOG" 2>&1 || {
    echo "Warning: CrossMap conversion failed for $TOOL. Check log: $CONVERSION_LOG" >&2
    continue
  }

  ##### Remove chr, sort and index the converted VCF
  # Remove chr prefix from the VCF (for consistency with truth set)
  echo "Processing chromosomes in $TOOL VCF..."
  # Remove 'chr' prefix if present, otherwise add it (to ensure consistency with truth set)
  sed -e 's/chr//g' "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_raw.vcf" > "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_nochr.vcf"
  # Sort the VCF
  echo "Sorting $TOOL VCF..." 
  bcftools sort -o $TOOLDIR/${SAMPLE}_${TOOL}_hg19.vcf "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_nochr.vcf"


  # Index the final VCF
  bgzip -f $TOOLDIR/${SAMPLE}_${TOOL}_hg19.vcf
  tabix -p vcf "$VCF_HG19"

  # Clean up intermediate files
  rm -f "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_raw.vcf" "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_nochr.vcf"

  #### Benchmarking with Truvari
  # Run Truvari benchmark using pixi environment
  # Note: Truvari may need reference validation, but we use -f to provide the reference
  echo "Benchmarking $TOOL for $SAMPLE (SV variants) ..."
  truvari bench \
    -b "$SV_TRUTH" \
    -c "$VCF_HG19" \
    -o "$TRUVARI_OUTPUT" \
    -f "$HGREF" \
    --includebed "$SV_BED" \
    > "$LOG" 2>&1 || {
    echo "Warning: Truvari benchmarking failed for $TOOL. Check log: $LOG" >&2
    # Don't exit on failure, just continue with next tool
  }

done
echo "All SV benchmarking complete. Results in $RESULTS_DIR"


### THIS PIPELINE 0.8.0 ###
RESULTS_DIR="nf-germline-short-read-variant-calling"
mkdir -p "$RESULTS_DIR"

# Define SV callers available from Sarek pipeline
TOOLS=(cnvnator delly manta smoove tiddit)

# VCF paths for SV callers from Sarek (hg38 coordinates)
VCF_DIR="../variant_calling/nf-germline-short-read-variant-calling"
VCF_CNVNATOR="$VCF_DIR/cnvnator/HG002.cnvnator.sorted.vcf.gz"
VCF_DELLY="$VCF_DIR/delly/HG002.delly.sorted.vcf.gz"
VCF_MANTA="$VCF_DIR/manta/HG002.manta.vcf.gz.sorted.vcf.gz"
VCF_SMOOVE="$VCF_DIR/smoove/HG002-smoove.vcf.gz.sorted.vcf.gz"
VCF_TIDDIT="$VCF_DIR/tiddit/HG002.tiddit.sorted.vcf.gz"


# Path map
declare -A VCF_PATHS=(
  [cnvnator]="$VCF_CNVNATOR"
  [delly]="$VCF_DELLY"
  [manta]="$VCF_MANTA"
  [smoove]="$VCF_SMOOVE"
  [tiddit]="$VCF_TIDDIT"
)

for TOOL in "${TOOLS[@]}"; do
  TOOLDIR="$RESULTS_DIR/$TOOL"
  mkdir -p "$TOOLDIR"
  VCF_HG38="${VCF_PATHS[$TOOL]}"
  VCF_HG19="$TOOLDIR/${SAMPLE}_${TOOL}_hg19.vcf.gz"
  LOG="$TOOLDIR/${SAMPLE}_${TOOL}.log"
  OUTPUT="$TOOLDIR/${SAMPLE}_${TOOL}"
  TRUVARI_OUTPUT="$OUTPUT.truvari"
  SUMMARY="$TOOLDIR/${SAMPLE}_${TOOL}.summary.txt"
  CONVERSION_LOG="$TOOLDIR/${SAMPLE}_${TOOL}_conversion.log"

  ##### Convert VCF from hg38 to hg19 using CrossMap
  echo "Converting $TOOL VCF from hg38 to hg19..."
  # Normalize the VCF before conversion to ensure consistent representation of variants
  bcftools norm -m -any -o "$TOOLDIR/${SAMPLE}_${TOOL}_hg38_normalized.vcf" "$VCF_HG38"

  CrossMap vcf \
    "$CHAIN_FILE" \
    "$TOOLDIR/${SAMPLE}_${TOOL}_hg38_normalized.vcf" \
    "$HGREF" \
    "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_raw.vcf" \
    > "$CONVERSION_LOG" 2>&1 || {
    echo "Warning: CrossMap conversion failed for $TOOL. Check log: $CONVERSION_LOG" >&2
    continue
  }

  ##### Remove chr, sort and index the converted VCF
  # Remove chr prefix from the VCF (for consistency with truth set)
  echo "Processing chromosomes in $TOOL VCF..."
  # Remove 'chr' prefix if present, otherwise add it (to ensure consistency with truth set)
  sed -e 's/chr//g' "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_raw.vcf" > "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_nochr.vcf"
  # Sort the VCF
  echo "Sorting $TOOL VCF..." 
  bcftools sort -o $TOOLDIR/${SAMPLE}_${TOOL}_hg19.vcf "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_nochr.vcf"


  # Index the final VCF
  bgzip -f $TOOLDIR/${SAMPLE}_${TOOL}_hg19.vcf
  tabix -p vcf "$VCF_HG19"

  # Clean up intermediate files
  rm -f "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_raw.vcf" "$TOOLDIR/${SAMPLE}_${TOOL}_hg19_nochr.vcf"

  #### Benchmarking with Truvari
  # Run Truvari benchmark using pixi environment
  # Note: Truvari may need reference validation, but we use -f to provide the reference
  echo "Benchmarking $TOOL for $SAMPLE (SV variants) ..."
  truvari bench \
    -b "$SV_TRUTH" \
    -c "$VCF_HG19" \
    -o "$TRUVARI_OUTPUT" \
    -f "$HGREF" \
    --includebed "$SV_BED" \
    > "$LOG" 2>&1 || {
    echo "Warning: Truvari benchmarking failed for $TOOL. Check log: $LOG" >&2
    # Don't exit on failure, just continue with next tool
  }

done
echo "All SV benchmarking complete. Results in $RESULTS_DIR"
