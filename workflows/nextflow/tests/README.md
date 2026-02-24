# Testing Documentation

This directory contains tests for the GATK variant calling pipeline using nf-test framework.

## Running Tests

### Run all tests
```bash
pixi run nf-test test
```

### Run specific test
```bash
pixi run nf-test test tests/subworkflows/local/preprocessing/main.nf.test
```

### Generate snapshots
```bash
pixi run nf-test test --update-snapshot
```

## Test Structure

- `subworkflows/local/preprocessing/main.nf.test` - Tests for preprocessing subworkflow (Steps 1-8)
- `subworkflows/local/variant_calling/main.nf.test` - Tests for variant calling subworkflow (Steps 9-13)
- `subworkflows/local/annotation/main.nf.test` - Tests for annotation subworkflow (Steps 14-16)

## Configuration

Test configuration is stored in `tests/nextflow.config` and includes:
- Resource limits (CPUs, memory, time)
- Test-specific parameters

## nf-test Documentation

For more information about nf-test, visit: https://www.nf-test.com
