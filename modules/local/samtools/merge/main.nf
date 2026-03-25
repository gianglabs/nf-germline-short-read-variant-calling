process SAMTOOLS_MERGE {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/samtools:1.18--h50ea8bc_1'

    input:
    tuple val(meta), path(bams)
    path ref_fasta

    output:
    tuple val(meta), path("*_merged.bam"), emit: bam
    tuple val(meta), path("*_merged.bam.bai"), emit: bai
    tuple val(meta), path("*_merged.cram"), emit: cram
    tuple val(meta), path("*_merged.cram.crai"), emit: crai
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Strategy: Output BOTH BAM (for processing) and CRAM (for storage)
    // This gives best of both worlds:
    //   - BAM continues to downstream processing (fast, compatible)
    //   - CRAM saved for long-term storage (45% space savings)

    if (bams instanceof List && bams.size() > 1) {
        """
        # Merge multiple BAM files to BAM for continued processing
        samtools merge \\
            -@ ${task.cpus} \\
            ${args} \\
            ${prefix}_merged.bam \\
            ${bams.join(' ')}
        
        # Index the merged BAM
        samtools index \\
            -@ ${task.cpus} \\
            ${prefix}_merged.bam
        
        # Also create CRAM version for storage
        samtools view \\
            -@ ${task.cpus} \\
            -T ${ref_fasta} \\
            -C \\
            -o ${prefix}_merged.cram \\
            ${prefix}_merged.bam
        
        # Index the CRAM
        samtools index \\
            -@ ${task.cpus} \\
            ${prefix}_merged.cram
        
        # Create versions file
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -1 | sed 's/samtools //')
        END_VERSIONS
        """
    }
    else {
        """ 
        # Single BAM: create symlink for BAM output
        ln -s ${bams[0]} ${prefix}_merged.bam
        
        # Index the BAM
        samtools index \\
            -@ ${task.cpus} \\
            ${prefix}_merged.bam
        
        # Convert to CRAM for storage
        samtools view \\
            -@ ${task.cpus} \\
            -T ${ref_fasta} \\
            -C \\
            -o ${prefix}_merged.cram \\
            ${bams[0]}
        
        # Index the CRAM
        samtools index \\
            -@ ${task.cpus} \\
            ${prefix}_merged.cram
        
        # Create versions file
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -1 | sed 's/samtools //')
        END_VERSIONS
        """
    }
}
