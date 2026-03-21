#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
    STRUCTURAL VARIANT CALLING SUBWORKFLOW
========================================================================================
    Structural Variant Calling with multiple tools
========================================================================================
*/

// Include modules
include { MANTA } from '../../../../modules/local/manta/main'
include { TIDDIT } from '../../../../modules/local/tiddit/main'
include { DELLY } from '../../../../modules/local/delly/main'
include { LUMPY } from '../../../../modules/local/lumpy/main'
include { CNVNATOR } from '../../../../modules/local/cnvnator/main'
include { SAMTOOLS_VIEW } from '../../../../modules/local/samtools/view/main'

workflow VARIANT_CALLING_SV {
    take:
    sv_caller // value: SV calling tool (e.g. "manta", "tiddit", "delly", etc.)
    bam // channel: [ val(meta), path(bam) ] or [ val(meta), path(cram) ]
    bai // channel: [ val(meta), path(bai) ] or [ val(meta), path(crai) ]
    ref_fasta // value: path(fasta)
    ref_fai // value: path(fai)

    main:
    ch_versions = channel.empty()
    ch_out_vcf = channel.empty()
    ch_out_vcf_tbi = channel.empty()

    // Detect if input is CRAM or BAM and convert if necessary
    bam_input = bam.branch {
        cram: it[1].toString().endsWith('.cram')
        bam: true
    }

    // Convert CRAM to BAM if needed
    SAMTOOLS_VIEW(
        bam_input.cram.join(bai),
        ref_fasta
    )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions)

    // Merge converted BAM with original BAM files
    bam_ready = bam_input.bam.join(bai).mix(SAMTOOLS_VIEW.out.bam.join(SAMTOOLS_VIEW.out.bai))

    if (sv_caller.split(",").contains("manta")) {
        MANTA(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(MANTA.out.versions)
        ch_out_vcf = MANTA.out.vcf
        ch_out_vcf_tbi = MANTA.out.vcf_tbi
    }
    if (sv_caller.split(",").contains("tiddit")) {
        TIDDIT(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(TIDDIT.out.versions)
        ch_out_vcf = TIDDIT.out.vcf
    }
    if (sv_caller.split(",").contains("delly")) {
        DELLY(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(DELLY.out.versions)
        ch_out_vcf = DELLY.out.bcf
        ch_out_vcf_tbi = DELLY.out.bcf_csi
    }
    if (sv_caller.split(",").contains("lumpy")) {
        LUMPY(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(LUMPY.out.versions)
        ch_out_vcf = LUMPY.out.vcf
    }
    if (sv_caller.split(",").contains("cnvnator")) {
        CNVNATOR(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(CNVNATOR.out.versions)
        ch_out_vcf = CNVNATOR.out.cnv  // CNVnator outputs .cnv.txt, not VCF
    }
    if (!sv_caller.split(",").any { it.trim() in ["manta", "tiddit", "delly", "lumpy", "cnvnator"] }) {
        error "Unsupported SV caller: ${sv_caller}. Supported callers: manta, tiddit, delly, lumpy, cnvnator"
    }

    emit:
    // VCF Channel - independent outputs
    vcf = ch_out_vcf          // channel: [ val(meta), path(vcf.gz) ]
    vcf_tbi = ch_out_vcf_tbi  // channel: [ val(meta), path(vcf.gz.tbi) ] 
    versions = ch_versions
}
