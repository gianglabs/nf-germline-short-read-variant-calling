# Contributing Guidelines

Hi there! Many thanks for taking an interest in improving **nf-germline-short-read-variant-calling**.

We try to manage the required tasks using GitHub issues, and we welcome all contributions!

> [!NOTE]
> If you need help using or modifying this pipeline, please open an issue on GitHub or check the [documentation](docs/).

## Contribution workflow

If you'd like to contribute code, please follow this workflow:

1. **Check for existing issues** - Search the [GitHub issues](https://github.com/nttg8100/nf-germline-short-read-variant-calling/issues) to avoid duplicating work. If there isn't one already, please create one so others know you're working on it.

2. **Fork the repository** - [Fork](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) the repository to your GitHub account.

3. **Create a feature branch** - Create a branch from `main` for your changes:
   ```bash
   git checkout -b feature/my-feature
   # or for bug fixes:
   git checkout -b bugfix/issue-description
   ```

4. **Make your changes** - Follow the [Pipeline contribution conventions](#pipeline-contribution-conventions) below.

5. **Test your changes** - Run tests locally to ensure your changes work (see [Testing](#testing) section).

6. **Update documentation** - Add or update relevant documentation if needed.

7. **Commit and push** - Use clear, descriptive commit messages:
   ```bash
   git add .
   git commit -m "feat: add new variant caller support" # or "fix:", "docs:", etc.
   git push origin feature/my-feature
   ```

8. **Submit a Pull Request** - Open a PR against the `main` branch with a clear description of your changes.

If you're new to git and GitHub, check out [GitHub's documentation](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests).

## Testing

### Local Testing

Test your changes locally before submitting a pull request:

```bash
# Run all tests with debug output
nf-test test --profile debug,test,docker --verbose

# Run a specific test
nf-test test tests/workflows/main.nf.test --profile test,docker
```

### Continuous Integration

When you create a pull request, GitHub Actions will automatically run tests. Pull requests are typically reviewed when these tests pass, but we can help fix issues before then.

Tests verify:
- **Code linting** - nf-core standards compliance
- **Workflow execution** - Pipeline runs successfully with test data
- **Output validation** - Generated outputs meet expected format

## Pipeline contribution conventions

To maintain code quality and readability, please follow these standards when contributing:

### Adding a new step/process

1. Define the input channel from the expected previous process
2. Write the process block following Nextflow best practices
3. Define the output channel
4. Add any new parameters to `nextflow.config` with sensible defaults
5. Update `nextflow_schema.json` with help text for new parameters
6. Add validation for all new parameters
7. Test locally to ensure the code works
8. Add a test case in the `tests/` directory if applicable
9. Update documentation if the new step affects output or usage

### Parameter conventions

- Parameters should be defined in the `params` scope in `nextflow.config`
- Use descriptive names in snake_case: `skip_variant_calling`, `small_variant_caller`, etc.
- Always provide default values
- Add help text in `nextflow_schema.json` describing what the parameter does

Example:
```groovy
// In nextflow.config
params {
    my_new_parameter = 'default_value'
}

// In nextflow_schema.json
{
    "my_new_parameter": {
        "type": "string",
        "description": "Description of what this parameter does",
        "default": "default_value"
    }
}
```

### Process resource requirements

Define sensible resource requirements in `conf/base.config` using labels:

```groovy
// In conf/base.config
process {
    withLabel: process_single {
        cpus   = 1
        memory = 2.GB
        time   = 1.h
    }
    withLabel: process_medium {
        cpus   = 4
        memory = 8.GB
        time   = 4.h
    }
}

// In your process
process MY_PROCESS {
    label 'process_medium'
    
    script:
    """
    my_tool --threads ${task.cpus} --memory ${task.memory.toMega()}M input.txt
    """
}
```

### Channel naming conventions

Use consistent naming for clarity:

```groovy
// Input channels
ch_input_fastq
ch_input_bam

// Intermediate channels
ch_fastqc_for_multiqc
ch_alignment_for_preprocessing

// Output channels
ch_variant_calling_vcf
ch_final_annotated_vcf
```

### Code style

- Use 4-space indentation
- Keep lines under 120 characters where possible
- Add comments for complex logic
- Use descriptive variable names

Example:
```groovy
process ALIGN_READS {
    input:
    tuple val(sample_id), file(fastq_r1), file(fastq_r2)
    file reference_genome
    
    output:
    tuple val(sample_id), file("${sample_id}.bam")
    
    script:
    """
    bwa mem -t ${task.cpus} \\
        ${reference_genome} \\
        ${fastq_r1} ${fastq_r2} | \\
        samtools sort -@ ${task.cpus} -o ${sample_id}.bam
    """
}
```

### Adding a new variant caller

If you're adding a new variant calling tool:

1. Create a new subworkflow in `subworkflows/local/variant_calling/`
2. Follow the existing pattern (e.g., `variant_calling/small/main.nf`)
3. Add the new caller to the parameter selection logic in `workflows/main.nf`
4. Update `nextflow_schema.json` with the new tool option
5. Add test cases with the new caller
6. Document output files and performance metrics in `docs/output.md`

### Adding a new workflow input mode

If you're adding support for a new input type (e.g., UBAM):

1. Update `workflows/main.nf` channel creation logic
2. Add validation for the new input type
3. Update the samplesheet documentation in `Readme.md`
4. Add test cases for the new input mode
5. Update `docs/architecture.md` with the new flow

### Documentation updates

When making changes that affect users:

1. Update `Readme.md` with new features or parameters
2. Update `docs/architecture.md` if workflow logic changes
3. Update `docs/output.md` if output files change
4. Add examples in documentation for new features

## Code review checklist

Before submitting your PR, please verify:

- [ ] Code follows pipeline naming conventions
- [ ] New parameters have defaults in `nextflow.config`
- [ ] New parameters are documented in `nextflow_schema.json`
- [ ] Tests pass locally: `nf-test test --profile test,docker`
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear and descriptive
- [ ] No debug code or comments left in
- [ ] No hardcoded paths or tool versions (use params)

## Reporting bugs

If you find a bug:

1. Check if it's already reported in [GitHub issues](https://github.com/nttg8100/nf-germline-short-read-variant-calling/issues)
2. Create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment (OS, Nextflow version, container runtime)
   - Any relevant logs or error messages

## Feature requests

Have a great idea? We'd love to hear it!

1. Check if a similar feature is already requested
2. Create an issue describing:
   - The feature you'd like to see
   - Why it would be useful
   - Any implementation ideas you have
3. We'll discuss and prioritize together

## Version management

This pipeline follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes to input/output or workflow logic
- **MINOR**: New features, new variant callers, new tools
- **PATCH**: Bug fixes, documentation updates

## Getting help

- **Questions about usage** - Open an issue with the `question` label
- **Technical issues** - Open an issue with detailed error information
- **Feature discussion** - Open an issue with the `enhancement` label
- **Documentation** - Check [docs/](../docs/) directory

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

---

Thank you for contributing! Your efforts help make this pipeline better for everyone.
