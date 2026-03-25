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
include { SMOOVE } from '../../../../modules/local/smoove/main'
include { CNVNATOR } from '../../../../modules/local/cnvnator/main'
include { SURVIVOR_MERGE } from '../../../../modules/local/survivor/main'
include { SAMTOOLS_VIEW } from '../../../../modules/local/samtools/view/main'
include { TABIX_INDEX_VCF } from '../../../../modules/local/bcftools/index/main'

workflow STRUCTURAL_VARIANT_CALLING {
    take:
    sv_caller // value: SV calling tool (e.g. "manta", "tiddit", "delly", etc.)
    bam // channel: [ val(meta), path(bam) ] or [ val(meta), path(cram) ]
    bai // channel: [ val(meta), path(bai) ] or [ val(meta), path(crai) ]
    ref_fasta // value: path(fasta)
    ref_fai // value: path(fai)
    genome // value: genome type

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
        ch_out_vcf = ch_out_vcf.mix(MANTA.out.vcf)
    }
    if (sv_caller.split(",").contains("tiddit")) {
        TIDDIT(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(TIDDIT.out.versions)
        ch_out_vcf = ch_out_vcf.mix(TIDDIT.out.vcf)
    }
    if (sv_caller.split(",").contains("delly")) {
        DELLY(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(DELLY.out.versions)
        ch_out_vcf = ch_out_vcf.mix(DELLY.out.vcf)
    }
    if (sv_caller.split(",").contains("smoove")) {
        SMOOVE(
            bam_ready,
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(SMOOVE.out.versions)
        ch_out_vcf = ch_out_vcf.mix(SMOOVE.out.vcf)
    }
    if (sv_caller.split(",").contains("cnvnator")) {
        CNVNATOR(
            bam_ready,
            ref_fasta,
            ref_fai,
            genome
        )
        ch_versions = ch_versions.mix(CNVNATOR.out.versions)
        
        ch_out_vcf = ch_out_vcf.mix(CNVNATOR.out.vcf)

    }
    if (!sv_caller.split(",").any { it.trim() in ["manta", "tiddit", "delly", "smoove", "cnvnator"] }) {
        error "Unsupported SV caller: ${sv_caller}. Supported callers: manta, tiddit, delly, smoove, cnvnator"
    }

    // Group VCF files by sample ID for merge
    // TODO: configure to merge the tools smartly
    ch_vcf_grouped = ch_out_vcf.groupTuple(by: 0)
    
    SURVIVOR_MERGE(
        ch_vcf_grouped
    )
    ch_versions = ch_versions.mix(SURVIVOR_MERGE.out.versions)

    TABIX_INDEX_VCF(     
        ch_vcf_grouped
    )
    ch_versions = ch_versions.mix(TABIX_INDEX_VCF.out.versions)

    emit:
    // VCF Channel - merged and indexed outputs
    vcf = TABIX_INDEX_VCF.out.vcf          // channel: [ val(meta), path(vcf.gz) ]
    vcf_tbi = TABIX_INDEX_VCF.out.vcf_tbi  // channel: [ val(meta), path(vcf.gz.tbi) ] 
    versions = ch_versions
}
