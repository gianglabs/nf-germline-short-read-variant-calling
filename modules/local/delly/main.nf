process DELLY {
    tag "$meta.id"
    label 'process_high'
    container "docker.io/dellytools/delly:v1.3.1"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    path(fai)

    output:
    tuple val(meta), path("${meta.id}.bcf")     , emit: bcf
    tuple val(meta), path("${meta.id}.bcf.csi") , emit: bcf_csi
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Run Delly
    delly call \\
        -g ${fasta} \\
        -o ${prefix}.bcf \\
        ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        delly: \$(delly --version 2>&1 | head -n1 | sed 's/^Delly version: v//')
    END_VERSIONS
    """
}
