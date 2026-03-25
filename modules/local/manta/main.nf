process MANTA {
    tag "${meta.id}"
    label 'process_high'
    container "quay.io/biocontainers/manta:1.6.0--py27h9948957_6"

    input:
    tuple val(meta), path(bam), path(bai)
    path fasta
    path fai

    output:
    tuple val(meta), path("${meta.id}.manta.vcf.gz"), emit: vcf
    tuple val(meta), path("${meta.id}.manta.vcf.gz.tbi"), emit: vcf_tbi
    tuple val(meta), path("${meta.id}.candidateSV.vcf.gz"), emit: candidate_vcf, optional: true
    tuple val(meta), path("${meta.id}.candidateSV.vcf.gz.tbi"), emit: candidate_vcf_tbi, optional: true
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Configure Manta
    configManta.py \\
        --bam ${bam} \\
        --referenceFasta ${fasta} \\
        --runDir manta_run

    # Run Manta workflow
    manta_run/runWorkflow.py \\
        -j ${task.cpus} \\
        -m local

    # Rename output files
    mv manta_run/results/variants/diploidSV.vcf.gz ${prefix}.manta.vcf.gz
    mv manta_run/results/variants/diploidSV.vcf.gz.tbi ${prefix}.manta.vcf.gz.tbi
    
    mv manta_run/results/variants/candidateSV.vcf.gz ${prefix}.candidateSV.vcf.gz
    mv manta_run/results/variants/candidateSV.vcf.gz.tbi ${prefix}.candidateSV.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        manta: \$(configManta.py --version 2>&1 | grep -oP 'Manta workflow version: \\K[0-9.]+' || echo "1.6.0")
    END_VERSIONS
    """
}
