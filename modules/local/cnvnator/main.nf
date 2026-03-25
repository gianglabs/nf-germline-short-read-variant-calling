process CNVNATOR {
    tag "$meta.id"
    label 'process_high'
    container "quay.io/biocontainers/cnvnator:0.4.1--py313h9efa6d7_12"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    path(fai)
    val(genome)

    output:
    tuple val(meta), path("${meta.id}.cnvnator.vcf"    )     , emit: vcf
    tuple val(meta), path("${meta.id}.root")        , emit: root
    path "versions.yml"                             , emit: versions

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

    # Convert to vcf
    cnvnator2VCF.pl -prefix sample_id -reference ${genome} ${prefix}.cnv.txt . > ${meta.id}.temp.cnvnator.vcf


    # Fix missing the contig information
    CHROMS=\$(grep -v "^#" ${meta.id}.temp.cnvnator.vcf | cut -f1 | sort -u)
    {
    while IFS= read -r line; do
        if [[ "\$line" == "#CHROM"* ]]; then
            # Insert human chromosome contig lines before #CHROM
            for chr in \$CHROMS; do
                echo "##contig=<ID=\$chr>"
            done
            echo "\$line"
        else
            echo "\$line"
        fi
        done < "${meta.id}.temp.cnvnator.vcf"
    } >  ${meta.id}.cnvnator.vcf


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cnvnator: \$(cnvnator -version 2>&1 | grep -oP 'CNVnator \\K[0-9.]+' || echo "unknown")
    END_VERSIONS
    """
}
