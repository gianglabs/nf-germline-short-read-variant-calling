.PHONY: test-fastq test-cram test-cram-multi test-cram-multisv test-e2e clean lint help pixi

${HOME}/.pixi/bin/pixi:
	curl -sSL https://pixi.sh/install.sh | sh

# Help target
help:
	@echo "Available test targets:"
	@echo "  make test-fastq         - Test FASTQ input (full pipeline: align + variant call)"
	@echo "  make test-cram          - Test CRAM input (single sample, skip alignment)"
	@echo "  make test-cram-multi    - Test CRAM input (multiple samples)"
	@echo "  make test-cram-multisv  - Test CRAM input (multiple SV callers: manta,delly)"
	@echo "  make test-e2e           - Standard e2e test (default: FASTQ)"
	@echo "  make test-e2e-snapshot  - Run nf-test snapshot tests"
	@echo "  make lint               - Run Nextflow linting"
	@echo "  make clean              - Clean work directory"

# FASTQ input test - full pipeline with alignment
test-fastq: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet.csv \
		-profile docker,test \
		-resume

# CRAM input test - single sample
test-cram: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf \
		--input assets/samplesheet_cram.csv \
		-profile docker,test \
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

# Standard e2e test
test-e2e: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow run main.nf -profile docker,test -resume

# nf-test snapshot tests
test-e2e-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test --verbose --profile test,docker

# Update nf-test snapshots
test-e2e-update-snapshot: ${HOME}/.pixi/bin/pixi
	export NXF_FILE_ROOT=${PWD}; ${HOME}/.pixi/bin/pixi run nf-test test tests/default.nf.test --verbose --update-snapshot --profile test,docker

# Lint
lint: ${HOME}/.pixi/bin/pixi
	${HOME}/.pixi/bin/pixi run nextflow lint . -format

# Clean
clean:
	rm -rf work results .nextflow* *.log