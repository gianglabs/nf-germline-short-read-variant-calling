# Nextflow Germline Short-Read Variant Calling Pipeline Architecture

This document describes the complete architecture and workflow of the Nextflow germline variant calling pipeline.

## Visual Diagram

See the accompanying diagram: **`nf-germline-pipeline.png`**

The diagram shows the complete pipeline with 6 major sections:

### Section 1: Input
- Samplesheet CSV format (sample, lane, fastq_1, fastq_2)
- Paired-end Illumina reads (gzip-compressed)
- Per-lane organization for multi-lane sample support

### Section 2: Alignment & QC (FASTP → SAMTOOLS)
Sequential processing of each lane:
1. **FASTP v1.1.0** - Quality filtering (Q≥20), min length 50bp, adapter trimming
2. **BWA-MEM2** - Paired-end alignment with per-lane read groups
3. **SAMTOOLS SORT** - Coordinate sorting and BAI indexing
4. **SAMTOOLS MERGE** - Multi-lane BAM merging per sample

### Section 3: Preprocessing (Optional - Default: SKIPPED)
Controlled by `params.skip_preprocessing` (default: true)

**If enabled, choose between two paths:**
- **GATK path**: MarkDuplicates → BQSR BaseRecalibrator → ApplyBQSR
- **Sambamba path**: Faster, lighter MarkDuplicates (no BQSR)

### Section 4: Variant Calling (3-Way Branching - Default: DeepVariant)
Choose via `params.variant_caller`:

**Path A: GATK HaplotypeCaller** (`variant_caller="gatk"`)
- Outputs GVCF format
- Genotype GVCFs in subsequent step
- Separate SNP vs INDEL filtering
- Merge filtered variants

**Path B: FreeBayes** (`variant_caller="freebayes"`)
- Single-sample direct VCF output
- No GVCF format
- Proof-of-concept path

**Path C: DeepVariant ⭐ (DEFAULT)** (`variant_caller="deepvariant"`)
- Deep learning-based variant calling (WGS mode)
- Produces both VCF and gVCF outputs
- Clinical-grade accuracy (FDA-recognized)
- Parallel sharding by number of available CPUs

### Section 5: Annotation & Normalization
Sequential annotation pipeline (always runs):

1. **BCFtools Normalize**
   - Decompose multi-allelic records
   - Left-align indels
   - Ensures consistent variant representation

2. **SnpEff v5.4.0c**
   - Gene impact annotations
   - Generate CSV statistics and HTML reports
   - Use canonical transcripts only

3. **Ensembl VEP v115**
   - Transcript-level annotations
   - Advanced functional impact predictions
   - Per-gene analysis
   - HTML summary report

### Section 6: QC & Outputs
Quality control and final outputs:

1. **BCFtools Stats**
   - Variant counts (SNPs, INDELs, SVs)
   - SNP/INDEL ratio statistics
   - Depth and quality statistics

2. **Bedtools GenomeCov**
   - Per-base coverage calculation
   - BedGraph format (compatible with genome browsers)

## Output Files

All results are organized under `results/germline_variant_calling:*/`

**Main VCF Output:**
- `sample.vcf.gz` - Final VEP-annotated VCF
- `sample.vcf.gz.tbi` - VCF index (Tabix)

**QC/Metrics Files:**
- `sample_variant_stats.txt` - Variant statistics
- `sample_coverage.bedgraph` - Coverage track
- `sample.html` - SnpEff/VEP HTML reports
- `sample.csv` - SnpEff annotation statistics

**Pipeline Reports:**
- `pipeline_info/execution_timeline_*.html`
- `pipeline_info/execution_report_*.html`
- `pipeline_info/execution_trace_*.txt`

## Key Parameters

### Required Parameters
- `--input` - Path to samplesheet CSV
- `--outdir` - Output directory (default: `./results`)

### Variant Caller Selection
- `--variant_caller` - Choose: `gatk`, `freebayes`, or `deepvariant` (default: `deepvariant`)

### Preprocessing Control
- `--skip_preprocessing` - Skip deduplication/BQSR (default: true)
- If false, choose preprocessor:
  - `--preprocessor gatk` (default) - Full GATK pipeline with BQSR
  - `--preprocessor sambamba` - Faster, lighter deduplication only

### Reference Data
- `--genome` - Reference genome ID: `test` or `GRCh38` (default: `test`)
  - `test`: Uses chr22 for quick testing
  - `GRCh38`: Full human genome

### Compute Resources
- `--max_cpus` - Max CPU cores
- `--max_memory` - Max memory (e.g., `64.GB`)
- `--max_time` - Max execution time per task

## Tool Versions

| Tool | Version | Purpose |
|------|---------|---------|
| FASTP | 1.1.0 | Quality filtering and adapter trimming |
| BWA-MEM2 | latest | Read alignment |
| Samtools | 1.17-1.18 | BAM manipulation (sort, merge, index) |
| GATK | 4.4.0-4.6.1.0 | Variant calling and filtering |
| DeepVariant | 1.9.0 | Deep learning variant calling |
| FreeBayes | 1.3.10 | Bayesian variant calling |
| BCFtools | 1.17-1.21 | VCF manipulation and statistics |
| SnpEff | 5.4.0c | Functional annotation |
| Ensembl VEP | 115 | Advanced functional annotation |
| Bedtools | 2.31.0 | Coverage analysis |
| Sambamba | 1.0.1 | Fast duplicate marking |

## Running the Pipeline

### Quick Test (chr22 only)
```bash
pixi run nextflow run main.nf -profile docker,test -resume
```

### Full Run with Custom Samples
```bash
nextflow run main.nf \
  --input samples.csv \
  --genome GRCh38 \
  --variant_caller deepvariant \
  --skip_preprocessing true \
  --outdir ./results \
  -profile docker
```

### With GATK and BQSR Preprocessing
```bash
nextflow run main.nf \
  --input samples.csv \
  --variant_caller gatk \
  --skip_preprocessing false \
  --preprocessor gatk \
  -profile singularity
```

## Execution Profiles

- `docker` - Use Docker containers (default)
- `singularity` - Use Singularity containers
- `test` - Use test data (chr22 subset)
- `standard` - Standard execution (local machine)

## Editing the Diagram

The diagram is provided in two formats:

1. **PNG** (`nf-germline-pipeline.png`) - For documentation and viewing
2. **Excalidraw JSON** (`nf-germline-pipeline.excalidraw`) - For editing

To edit the diagram:
1. Open https://excalidraw.com
2. Click "Open" → "Open Existing Drawing"
3. Upload or paste the `.excalidraw` JSON file
4. Make your edits
5. Export as PNG for documentation

The diagram follows these visual conventions:
- **Blue rectangles**: Processing steps
- **Light blue**: Alternative paths
- **Purple**: Default choice (DeepVariant)
- **Yellow diamonds**: Decision points
- **Orange oval**: Start
- **Green oval**: End/Output

## References

- [Nextflow Documentation](https://www.nextflow.io/docs/latest/index.html)
- [GATK Documentation](https://gatk.broadinstitute.org/hc/en-us)
- [DeepVariant](https://github.com/google/deepvariant)
- [Ensembl VEP](https://www.ensembl.org/info/docs/tools/vep/index.html)
- [SnpEff](http://snpEff.sourceforge.net/)
