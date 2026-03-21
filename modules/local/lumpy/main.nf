process LUMPY {
    tag "$meta.id"
    label 'process_high'
    container "docker.io/kfdrc/lumpy:latest"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    path(fai)

    output:
    tuple val(meta), path("${meta.id}.vcf")     , emit: vcf
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Extract discordant and split reads
    samtools view -b -F 1294 ${bam} > ${prefix}.discordants.bam
    samtools view -h ${bam} | /lumpy-sv/scripts/extractSplitReads_BwaMem -i stdin | samtools view -Sb - > ${prefix}.splitters.bam

    # Run LUMPY Express
    lumpyexpress \\
        -B ${bam} \\
        -S ${prefix}.splitters.bam \\
        -D ${prefix}.discordants.bam \\
        -o ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lumpy: \$(lumpy --version 2>&1 | grep -oP 'lumpy version \\K[0-9.]+' || echo "0.3.1")
    END_VERSIONS
    """
}
