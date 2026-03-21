process CNVNATOR {
    tag "$meta.id"
    label 'process_high'
    container "docker.io/szarate/cnvnator:v0.4.1"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    path(fai)

    output:
    tuple val(meta), path("${meta.id}.cnv.txt")     , emit: cnv
    tuple val(meta), path("${meta.id}.root")        , emit: root
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bin_size = task.ext.bin_size ?: 1000
    """
    # Extract read mapping
    cnvnator -root ${prefix}.root -tree ${bam}

    # Generate histogram
    cnvnator -root ${prefix}.root -his ${bin_size} -fasta ${fasta}

    # Calculate statistics
    cnvnator -root ${prefix}.root -stat ${bin_size}

    # Partition
    cnvnator -root ${prefix}.root -partition ${bin_size}

    # Call CNVs
    cnvnator -root ${prefix}.root -call ${bin_size} > ${prefix}.cnv.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cnvnator: \$(cnvnator -version 2>&1 | grep -oP 'CNVnator \\K[0-9.]+' || echo "unknown")
    END_VERSIONS
    """
}
