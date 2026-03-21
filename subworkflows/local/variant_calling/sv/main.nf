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

workflow VARIANT_CALLING_SV {
    take:
    sv_caller // value: SV calling tool (e.g. "manta", "tiddit", "delly", etc.)
    bam // channel: [ val(meta), path(bam) ]
    bai // channel: [ val(meta), path(bai) ]
    ref_fasta // value: path(fasta)
    ref_fai // value: path(fai)
    ref_dict // value: path(dict)

    main:
    ch_versions = channel.empty()
    ch_out_vcf = channel.empty()
    ch_out_vcf_tbi = channel.empty()

    if (sv_caller.split(",").contains("manta")) {
        MANTA(
            bam.join(bai),
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(MANTA.out.versions)
        ch_out_vcf = MANTA.out.vcf
        ch_out_vcf_tbi = MANTA.out.vcf_tbi
    }
    else if (sv_caller.split(",").contains("tiddit")) {
        TIDDIT(
            bam.join(bai),
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(TIDDIT.out.versions)
        ch_out_vcf = TIDDIT.out.vcf
    }
    else if (sv_caller.split(",").contains("delly")) {
        DELLY(
            bam.join(bai),
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(DELLY.out.versions)
        ch_out_vcf = DELLY.out.bcf
        ch_out_vcf_tbi = DELLY.out.bcf_csi
    }
    else if (sv_caller.split(",").contains("lumpy")) {
        LUMPY(
            bam.join(bai),
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(LUMPY.out.versions)
        ch_out_vcf = LUMPY.out.vcf
    }
    else if (sv_caller.split(",").contains("cnvnator")) {
        CNVNATOR(
            bam.join(bai),
            ref_fasta,
            ref_fai,
        )
        ch_versions = ch_versions.mix(CNVNATOR.out.versions)
        ch_out_vcf = CNVNATOR.out.cnv  // CNVnator outputs .cnv.txt, not VCF
    }
    else {
        error "Unsupported SV caller: ${sv_caller}. Supported callers: manta, tiddit, delly, lumpy, cnvnator"
    }

    emit:
    // VCF Channel - independent outputs
    vcf = ch_out_vcf          // channel: [ val(meta), path(vcf.gz) ]
    vcf_tbi = ch_out_vcf_tbi  // channel: [ val(meta), path(vcf.gz.tbi) ] 
    versions = ch_versions
}
