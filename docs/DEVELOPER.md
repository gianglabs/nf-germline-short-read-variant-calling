# Developer Quick Start

This guide helps developers quickly get started contributing to the pipeline.

## Prerequisites

- Nextflow >= 23.10.0
- Docker or Singularity
- Git
- nf-test (for testing)

## Setup Your Development Environment

```bash
# Clone the repository
git clone https://github.com/nttg8100/nf-germline-short-read-variant-calling.git
cd nf-germline-short-read-variant-calling

# Create a feature branch
git checkout -b feature/your-feature-name

# Install dependencies (if using pixi)
pixi install
```

## Common Development Tasks

### Running the pipeline locally

```bash
# With test data
nf-test test --profile test,docker

# With your own data
nextflow run main.nf -profile docker \
    --input samplesheet.csv \
    --outdir results/
```

### Running specific tests

```bash
# Run main workflow test
nf-test test tests/workflows/main.nf.test --profile test,docker

# Run a specific process test
nf-test test tests/modules/nf-core/bwamem2/mem/main.nf.test --profile test,docker
```

### Debugging

Enable debug mode to see more output:

```bash
nf-test test --profile debug,test,docker --verbose

# Or with Nextflow directly
nextflow run main.nf -profile docker \
    --input samplesheet.csv \
    -resume \
    -debug
```

### Linting

Check if code follows nf-core standards:

```bash
# If you have nf-core tools installed
nf-core pipelines lint .
```

## File Structure Quick Reference

```
.
├── main.nf                    # Pipeline entry point
├── workflows/
│   └── main.nf               # Main workflow logic
├── subworkflows/              # Reusable workflow components
│   └── local/                # Local subworkflows
│       ├── alignment/
│       ├── variant_calling/
│       └── ...
├── modules/                   # Individual processes
│   └── nf-core/              # nf-core modules (auto-managed)
├── conf/                      # Configuration files
│   ├── base.config           # Process resource requirements
│   ├── modules.config        # Module parameters
│   └── igenomes.config       # Reference genomes
├── docs/                      # Documentation
├── tests/                     # Test cases
└── nextflow_schema.json      # Parameter schema
```

## Editing Configuration

### Adding a new parameter

1. Add to `nextflow.config`:
```groovy
params {
    my_param = 'default_value'
}
```

2. Update `nextflow_schema.json`:
```json
{
    "my_param": {
        "type": "string",
        "description": "What this parameter does",
        "default": "default_value"
    }
}
```

### Modifying process resources

Edit `conf/base.config`:

```groovy
process {
    withLabel: process_high {
        cpus   = 16
        memory = 64.GB
        time   = 24.h
    }
}
```

## Creating a new process

1. Create file `modules/local/my_process.nf`:

```groovy
process MY_PROCESS {
    label 'process_single'
    
    input:
    tuple val(sample_id), file(input_file)
    
    output:
    tuple val(sample_id), file("${sample_id}.processed")
    
    script:
    """
    my_tool ${input_file} --output ${sample_id}.processed
    """
}
```

2. Include in workflow `workflows/main.nf`:

```groovy
include { MY_PROCESS } from '../modules/local/my_process'

workflow {
    MY_PROCESS(ch_my_input)
}
```

3. Add test in `tests/modules/local/my_process/main.nf.test`

## Useful Nextflow commands

```bash
# Run with resume (use cached results)
nextflow run main.nf -resume

# Clear work directory (remove cached results)
rm -rf work/

# View pipeline DAG (directed acyclic graph)
nextflow run main.nf -with-dag pipeline.html

# Dry run (don't execute, just show what would run)
nextflow run main.nf -profile test,docker -preview

# Run with specific executor
nextflow run main.nf -executor local   # Local machine
nextflow run main.nf -executor slurm   # SLURM cluster
```

## Debugging tips

### View process working directory

```bash
# After a run fails, check the work directory
ls work/
# Find the task directory and inspect its contents
cd work/xx/xxxxxxxx/
# View .command.run to see what was executed
cat .command.run
```

### Add debug output to processes

```groovy
script:
"""
echo "DEBUG: Input file = ${input_file}" >&2
echo "DEBUG: Sample ID = ${sample_id}" >&2
my_tool ${input_file}
"""
```

### Check Nextflow configuration

```bash
nextflow config
# Or dump config to file
nextflow config > config_dump.txt
```

## Pull Request Guidelines

Before submitting a PR:

1. **Branch naming**: Use descriptive names
   - `feature/add-new-caller`
   - `bugfix/fix-memory-issue`
   - `docs/update-readme`

2. **Commit messages**: Be clear and descriptive
   ```
   feat: add support for GATK 4.4
   fix: resolve memory overflow in variant calling
   docs: update installation instructions
   ```

3. **PR description**: Include
   - What does this PR do?
   - Why is it needed?
   - Any breaking changes?
   - Related issues

4. **Testing**: Ensure tests pass locally
   ```bash
   nf-test test --profile test,docker
   ```

5. **Documentation**: Update relevant docs

## Common Issues & Solutions

### Issue: "Command not found: nextflow"

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
export PATH=$PATH:$PWD
```

### Issue: "Docker daemon not running"

```bash
# Start Docker daemon (varies by OS)
# On macOS
open -a Docker

# On Linux
sudo systemctl start docker
```

### Issue: Test data not found

```bash
# Download test data
./test_data/download_hg002.sh
# Or
make test-download
```

## Getting Help

- Check existing [GitHub issues](https://github.com/nttg8100/nf-germline-short-read-variant-calling/issues)
- Read the [full CONTRIBUTING.md](.github/CONTRIBUTING.md)
- Review [documentation](../docs/)
- Check [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html)

---

Happy coding! 🚀
