process SURVIVOR_MERGE {
    tag "$meta.id"
    label 'process_low'
    container 'quay.io/biocontainers/survivor:1.0.7--h9a82719_1'

    input:
    tuple val(meta), path(vcf_files)

    output:
    tuple val(meta), path("*.survivor.vcf")   , emit: vcf
    path("versions.yml")             , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # requires vcf file
    if ([ -f *.vcf.gz ]) 2>/dev/null; then
        gunzip -f *.vcf.gz
    fi

    find . -name "*.vcf" -type f > vcf_files.txt
    find . -name "*.vcf" -type l >> vcf_files.txt

    SURVIVOR merge \\
        vcf_files.txt \\
        0.2 \\
        1 \\
        0 \\
        0 \\
        0 \\
        0 \\
        ${prefix}.survivor.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        SURVIVOR: \$(SURVIVOR 2>&1 | grep 'Version' | sed 's/Version: //' || echo "0.3.1")
    END_VERSIONS
    """
}