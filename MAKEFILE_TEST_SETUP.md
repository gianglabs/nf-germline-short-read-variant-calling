# Makefile Test Targets Setup

## Changes Made

### 1. Updated Assets Structure
```
assets/
├── input/                    (NEW ORGANIZED DIRECTORY)
│   ├── fastq/               (FASTQ test files)
│   │   ├── HG002_subset_R1.fastq.gz
│   │   └── HG002_subset_R2.fastq.gz
│   └── cram/                (CRAM test files)
│       ├── sample1.cram
│       └── sample1.cram.crai
├── genome/                  (Reference genome)
├── samplesheet.csv          (Default: FASTQ single sample)
├── samplesheet_fastq.csv
├── samplesheet_fastq_multi.csv
├── samplesheet_cram.csv
└── samplesheet_cram_multi.csv
```

### 2. Updated Samplesheet Paths
All samplesheets now use correct organized paths:
- FASTQ files: `assets/input/fastq/HG002_subset_*.fastq.gz`
- CRAM files: `assets/input/cram/sample1.cram*`

### 3. Enhanced Makefile
Added convenient test targets:

```makefile
make help                  # Show available targets
make test-fastq           # FASTQ single sample (full pipeline)
make test-cram            # CRAM single sample (skip alignment)
make test-cram-multi      # CRAM multiple samples
make test-cram-multisv    # CRAM with multi-caller SV (manta,delly)
make test-e2e             # Default e2e test
make lint                 # Run Nextflow linting
make clean                # Clean work directory
```

### 4. Added Nextflow Profiles
All profiles in `nextflow.config`:

```
-profile test              # Default: FASTQ single sample
-profile test_fastq        # FASTQ single sample
-profile test_fastq_multi  # FASTQ multiple samples
-profile test_cram         # CRAM single sample
-profile test_cram_multi   # CRAM multiple samples
```

## Usage Examples

### Quick Test (FASTQ - full pipeline)
```bash
make test-fastq
# or
make test-e2e
```

### CRAM Input Tests
```bash
# Single sample
make test-cram

# Multiple samples
make test-cram-multi

# Multi-caller SV (manta + delly)
make test-cram-multisv
```

### Manual Nextflow Execution
```bash
# Using profiles
nextflow run main.nf -profile docker,test_cram -resume

# Or with full parameters
nextflow run main.nf \
  --input assets/samplesheet_cram.csv \
  --sv_caller "manta,delly" \
  -profile docker,test \
  -resume
```

### Help
```bash
make help
```

## Test Coverage

| Test | Input Type | Samples | Features | Command |
|------|-----------|---------|----------|---------|
| FASTQ | FASTQ | 1 | Full pipeline (align + variant) | `make test-fastq` |
| CRAM | CRAM | 1 | Skip alignment, auto-convert | `make test-cram` |
| CRAM-Multi | CRAM | 2+ | Parallel processing | `make test-cram-multi` |
| CRAM-MultiSV | CRAM | 1 | Multiple SV callers | `make test-cram-multisv` |
| E2E | FASTQ | 1 | Default test | `make test-e2e` |

## Key Configuration Points

- **Resource Limits**: All test profiles limited to 4 CPUs, 15GB memory, 2h timeout
- **Index Generation**: CRAM tests use `--index_bwa2_reference false` to skip unnecessary BWA indexing
- **SV Caller Default**: `manta` (overridable with `--sv_caller` parameter)
- **Variant Caller Default**: `deepvariant` (overridable with `--variant_caller` parameter)
- **Annotation**: Enabled by default (disable with `--skip_annotation`)

## File Changes

### Modified Files
- `Makefile` - Added test targets
- `nextflow.config` - Added `test` profile, updated samplesheet paths
- `assets/samplesheet*.csv` - Updated all paths to use organized structure

### Generated Files (Test Runs)
- `assets/samplesheet*.csv` - Regenerated with correct paths
- `results/` - Pipeline output directory (created after runs)
- `work/` - Nextflow work directory (created during runs)

## Quick Verification

```bash
# List available targets
make help

# Test Makefile syntax
make --dry-run test-cram

# Test one target
make test-cram-multi 2>&1 | head -50
```
