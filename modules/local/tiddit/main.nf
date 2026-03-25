process TIDDIT {
    tag "$meta.id"
    label 'process_high'
    container "quay.io/biocontainers/tiddit:3.9.4--py311h93dcfea_0"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    path(fai)

    output:
    tuple val(meta), path("${meta.id}.tiddit.vcf")          , emit: vcf
    tuple val(meta), path("${meta.id}.ploidy.tab")   , emit: ploidy, optional: true
    tuple val(meta), path("${meta.id}.signals.tab")  , emit: signals, optional: true
    path "versions.yml"                              , emit: versions


    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    tiddit --sv \\
        --bam ${bam} \\
        --ref ${fasta} \\
        -o ${prefix}.tiddit \\
        --threads ${task.cpus} \\
        --skip_assembly

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiddit: \$(tiddit --version 2>&1 | grep -o 'TIDDIT-\\K[0-9.]+' || echo "3.9.4")
    END_VERSIONS
    """
}
