process DELLY {
    tag "$meta.id"
    label 'process_high'
    container "quay.io/biocontainers/delly:1.7.2--h4d20210_0"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    path(fai)

    output:
    tuple val(meta), path("${meta.id}.delly.vcf")     , emit: vcf
    path "versions.yml"                         , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Run Delly
    delly call \\
        -g ${fasta} \\
        ${bam} > ${prefix}.delly.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$(delly --version 2>&1 | head -n1 | sed 's/^Delly version: v//')
    END_VERSIONS
    """
}
