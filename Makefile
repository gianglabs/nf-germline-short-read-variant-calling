.PHONY: test-fastq test-cram test-cram-multi test-cram-multisv test-e2e clean lint help pixi test-cram-sv-manta test-cram-sv-delly test-cram-sv-tiddit test-cram-sv-lumpy test-cram-sv-cnvnator test-cram-sv-manta-delly test-cram-sv-manta-lumpy test-cram-sv-all

${HOME}/.pixi/bin/pixi:
	curl -sSL https://pixi.sh/install.sh | sh

# Help target
help:
	@echo "Available test targets:"
	@echo ""
	@echo "FASTQ and standard CRAM tests:"
	@echo "  make test-fastq                   - Test FASTQ input (full pipeline: align + variant call)"
	@echo "  make test-cram                    - Test CRAM input (single sample, skip alignment)"
	@echo "  make test-cram-multi              - Test CRAM input (multiple samples)"
	@echo "  make test-cram-multisv            - Test CRAM input (multiple SV callers: manta,delly)"
	@echo ""
	@echo "SV-only tests (skip small variant calling with --skip_variant_calling):"
	@echo "  make test-cram-sv-manta           - Test CRAM with Manta only"
	@echo "  make test-cram-sv-delly           - Test CRAM with Delly only"
	@echo "  make test-cram-sv-tiddit          - Test CRAM with TIDDIT only"
	@echo "  make test-cram-sv-lumpy           - Test CRAM with LUMPY only"
	@echo "  make test-cram-sv-cnvnator        - Test CRAM with CNVnator only"
	@echo ""
	@echo "Multi-caller SV tests (skip small variants):"
	@echo "  make test-cram-sv-manta-delly     - Manta + Delly"
	@echo "  make test-cram-sv-manta-lumpy     - Manta + LUMPY"
	@echo "  make test-cram-sv-all             - All SV callers (manta,delly,tiddit,lumpy,cnvnator)"
	@echo ""
	@echo "Other targets:"
	@echo "  make test-fastq-snapshot          - Run nf-test snapshot tests (FASTQ)"
	@echo "  make test-fastq-update-snapshot   - Update nf-test snapshots (FASTQ)"
	@echo "  make lint                         - Run Nextflow linting"
	@echo "  make clean                        - Clean work directory"

# FASTQ input test - full pipeline with alignment
test-fastq: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_fastq.csv \
		-profile docker,test_fastq \
		-resume

# nf-test snapshot tests
test-fastq-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
		--verbose \
		--profile docker,test_fastq

# Update nf-test snapshots
test-fastq-update-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test \
		tests/default.nf.test \
		--verbose \
		--update-snapshot \
		--profile docker,test_fastq

# CRAM input test - single sample
test-cram: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

# CRAM input test - multiple samples
test-cram-multi: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram_multi.csv \
		-profile docker,test \
		--index_bwa2_reference false \
		-resume

# CRAM input test - multiple SV callers
test-cram-multisv: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller "manta,delly" \
		-profile docker,test \
		--index_bwa2_reference false \
		-resume

# SV-only tests (skip small variant calling)
test-cram-sv-manta: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller manta \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

test-cram-sv-delly: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller delly \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

test-cram-sv-tiddit: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller tiddit \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

test-cram-sv-lumpy: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller lumpy \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

test-cram-sv-cnvnator: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller cnvnator \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

# Multi-caller SV tests
test-cram-sv-manta-delly: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller "manta,delly" \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

test-cram-sv-manta-lumpy: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller "manta,lumpy" \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

test-cram-sv-all: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		--sv_caller "manta,delly,tiddit,lumpy,cnvnator" \
		--skip_variant_calling \
		-profile docker,test_cram \
		--index_bwa2_reference false \
		-resume

# Lint
lint: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow lint . -format

# Clean
clean:
	rm -rf work results .nextflow* *.log