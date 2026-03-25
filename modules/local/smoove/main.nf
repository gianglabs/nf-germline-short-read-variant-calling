process SMOOVE {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/biocontainers/smoove:0.2.8--h9ee0642_1'

    input:
    tuple val(meta), path(input), path(index)
    path ref_fasta
    path ref_fai

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    path ("versions.yml"), emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    smoove call \\
        --outdir . \\
        --name ${prefix} \\
        --fasta ${ref_fasta} \\
        --processes ${task.cpus} \\
        ${input}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        smoove: \$(smoove -v |& sed -n 's/smoove version: *//p'|| echo "0.2.8")
    END_VERSIONS
    """
}
