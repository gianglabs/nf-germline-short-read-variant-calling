# Storage Comparison: FASTQ vs BAM vs CRAM

## Executive Summary

This document provides real-world storage measurements for genomic data formats at different pipeline stages, helping you make informed decisions about data retention and archival strategies.

**Key Finding**: CRAM format provides **45% storage savings** compared to BAM, while FASTQ files (raw reads) are surprisingly larger than aligned data.

---

## Quick Comparison Table

### Test Dataset (chr22, 2 samples)

| File Type            | Format         | Size per Sample | Relative Size | Use Case      |
| -------------------- | -------------- | --------------- | ------------- | ------------- |
| **Raw reads**        | FASTQ.GZ       | 74 MB           | 100%          | Initial input |
| **Aligned reads**    | BAM (unsorted) | 74 MB           | 100%          | Temporary     |
| **Sorted alignment** | BAM            | 51 MB           | **69%**       | Processing    |
| **Final alignment**  | CRAM           | 28 MB           | **38%** ✅    | Archival      |

**Storage Reduction**: FASTQ (74 MB) → CRAM (28 MB) = **62% savings**

---

## Detailed Storage Analysis

### 1. FASTQ Files (Raw Sequencing Data)

**Description**: Unaligned sequencing reads with quality scores

**Test Data Measurements**:

```
Sample 1:
├── sample1_R1.fastq.gz: 37 MB
└── sample1_R2.fastq.gz: 37 MB
Total: 74 MB

Sample 2:
├── sample2_R1.fastq.gz: 37 MB
└── sample2_R2.fastq.gz: 37 MB
Total: 74 MB
```

**Characteristics**:

- ✅ **Advantages**:
  - Raw data preservation
  - Can realign with different tools/references
  - No information loss
- ❌ **Disadvantages**:
  - Larger than aligned data (for targeted regions)
  - Contains unmapped reads
  - No genomic coordinates
  - Requires re-alignment for analysis

**Storage Cost**: **Highest** (but necessary for raw data backup)

---

### 2. BAM Files (Aligned Reads)

**Description**: Binary format of aligned reads with coordinates

#### a. Unsorted BAM (Immediately after BWA-MEM2)

**Test Data Measurements**:

```
sample1_aligned.bam: 74 MB
sample2_aligned.bam: 74 MB
```

**Characteristics**:

- Same size as FASTQ (no compression benefit yet)
- Reads in random order
- Temporary file (automatically sorted)

#### b. Sorted BAM (After SAMTOOLS_SORT)

**Test Data Measurements**:

```
sample1_sorted.bam: 51 MB  (31% reduction from unsorted)
sample2_sorted.bam: 51 MB
```

**Characteristics**:

- ✅ **Advantages**:
  - Coordinate-sorted for efficient access
  - Indexed for random access (`.bai` file)
  - Compatible with all downstream tools
  - Fast I/O performance
- ❌ **Disadvantages**:
  - Larger than CRAM (45% more space)
  - Stores full read sequences (no reference compression)

**Storage Cost**: **Medium** (31% smaller than FASTQ)

---

### 3. CRAM Files (Reference-Compressed Alignment)

**Description**: Reference-based compressed alignment format

**Test Data Measurements**:

```
sample1_merged.cram: 28 MB  (45% reduction from BAM)
sample2_merged.cram: 28 MB
```

**Characteristics**:

- ✅ **Advantages**:
  - **45% smaller than BAM**
  - **62% smaller than FASTQ**
  - Lossless compression
  - GA4GH standard format
  - Supported by modern tools (GATK, DeepVariant, samtools)
- ⚠️ **Considerations**:
  - Requires reference genome for viewing
  - Slightly slower decompression (~10-15%)
  - Reference must match original alignment

**Storage Cost**: **Lowest** ✅ (optimal for long-term storage)

---
