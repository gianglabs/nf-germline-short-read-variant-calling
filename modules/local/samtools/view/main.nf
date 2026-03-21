process SAMTOOLS_VIEW {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/samtools:1.17--hd87286a_2'

    input:
    tuple val(meta), path(input_file), path(input_index)
    path(ref_fasta)

    output:
    tuple val(meta), path("${prefix}.bam"), emit: bam
    tuple val(meta), path("${prefix}.bam.bai"), emit: bai
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    
    // Check if input is CRAM or BAM
    def input_format = input_file.toString().endsWith('.cram') ? 'CRAM' : 'BAM'

    """
    # Convert CRAM to BAM with coordinate sorting and indexing
    samtools view \\
        -b \\
        -h \\
        -@ ${task.cpus} \\
        -T ${ref_fasta} \\
        ${args} \\
        -o ${prefix}.bam \\
        ${input_file}
    
    # Index the BAM file
    samtools index \\
        -@ ${task.cpus} \\
        ${prefix}.bam \\
        ${prefix}.bam.bai

    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
