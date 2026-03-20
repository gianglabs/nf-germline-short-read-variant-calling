process BCFTOOLS_NORM {
    tag "$meta.id"
    label 'process_medium'
    container 'quay.io/biocontainers/bcftools:1.23--h3a4d415_0'

    input:
    tuple val(meta), path(vcf), path(tbi)
    path(fasta)

    output:
    tuple val(meta), path("${meta.id}.vcf.gz"), emit: vcf
    tuple val(meta), path("${meta.id}.vcf.gz.tbi"), emit: tbi
    path "versions.yml"               , emit: versions

    script:
    """
    bcftools norm \\
        --fasta-ref ${fasta} \\
        --output ${meta.id}.vcf.gz \\
        --output-type z \\
        --threads $task.cpus \\
        ${vcf}
    tabix -p vcf ${meta.id}.vcf.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}