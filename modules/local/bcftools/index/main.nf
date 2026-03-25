process TABIX_INDEX_VCF {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/bcftools:1.23--h3a4d415_0'

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    tuple val(meta), path("*.vcf.gz.tbi"), emit: vcf_tbi
    path ("versions.yml"), emit: versions

    script:
    """
    # echo here
    for vcf_file in ${vcf}; do
        if [ -f "\$vcf_file" ]; then
            echo "Sorting, compressing and indexing \$vcf_file"
            bcftools sort -o "\${vcf_file%.vcf}.sorted.vcf" "\$vcf_file"
            bgzip -f "\${vcf_file%.vcf}.sorted.vcf"
            tabix -p vcf "\${vcf_file%.vcf}.sorted.vcf.gz"
        fi
    done

    # Generate versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -1 | cut -d' ' -f2)
        bgzip: \$(bgzip -h 2>&1 | head -1 | cut -d' ' -f3)
        tabix: \$(tabix -h 2>&1 | grep Version | cut -d' ' -f2)
    END_VERSIONS

    """
}
