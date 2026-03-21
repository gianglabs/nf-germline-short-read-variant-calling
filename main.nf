#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { GERMLINE_VARIANT_CALLING } from './workflows/main.nf'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow {

    //
    // Create input channel from samplesheet or input parameters
    //
    // Check input mode: FASTQ or CRAM/BAM
    channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [:]
            meta.id = row.sample
            meta.sample = row.sample
            // Support both new format (with lane) and old format (without lane)
            meta.lane = row.lane ?: "L001"
            meta.read_group = "${row.sample}_${meta.lane}"
            
            // Check if input contains FASTQ files or aligned files (CRAM/BAM)
            if (row.cram && row.crai) {
                // CRAM mode: for rerunning with aligned files
                def cram = file(row.cram, checkIfExists: true)
                def crai = file(row.crai, checkIfExists: true)
                return [meta, cram, crai]
            } else if (row.bam && row.bai) {
                // BAM mode: for rerunning with aligned files
                def bam = file(row.bam, checkIfExists: true)
                def bai = file(row.bai, checkIfExists: true)
                return [meta, bam, bai]
            } else {
                // FASTQ mode: standard pipeline
                def reads = []
                reads.add(file(row.fastq_1, checkIfExists: true))
                reads.add(file(row.fastq_2, checkIfExists: true))
                return [meta, reads]
            }
        }
        .set { ch_input }


    GERMLINE_VARIANT_CALLING(
        ch_input
    )
}
