// Include subworkflows
include { ALIGNMENT } from '../subworkflows/local/alignment/main'
include { PREPROCESSING } from '../subworkflows/local/alignment_preprocessing/main'

// Variant calling
include { SMALL_VARIANT_CALLING } from '../subworkflows/local/variant_calling/small/main'
include { STRUCTURAL_VARIANT_CALLING } from '../subworkflows/local/variant_calling/structural/main'

// Variant annotation
include { VARIANT_ANNOTATION } from '../subworkflows/local/variant_annotation/main'

// QC
include { VARIANT_ALIGNMENT_QUALITY_CONTROL } from '../subworkflows/local/variant_alignment_quality_control/main'

// Include modules for CRAM conversion
include { SAMTOOLS_VIEW } from '../modules/local/samtools/view/main'

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

workflow GERMLINE_VARIANT_CALLING {
    take:
    input_ch // channel: 
             // [ val(meta), [ path(read1), path(read2) ] ] for FASTQ mode
             // or [ val(meta), path(bam), path(bai) ] for BAM mode
             // or [ val(meta), path(cram), path(crai) ] for CRAM mode

    main:
    ch_versions = channel.empty()

    // Automatically set reference resources from iGenomes if --igenomes_base and --genome are set
    if (params.genome && params.genomes.containsKey(params.genome)) {
        def igenome_ref = params.genomes[params.genome]
        if (igenome_ref) {
            if (igenome_ref.fasta) {
                params.reference = igenome_ref.fasta
            }
            if (igenome_ref.fasta_fai) {
                params.reference_index = igenome_ref.fasta_fai
            }
            if (igenome_ref.dict) {
                params.reference_dict = igenome_ref.dict
            }
            if (igenome_ref.index_bwa2_reference) {
                params.index_bwa2_reference = igenome_ref.index_bwa2_reference
            }
            if (igenome_ref.bwa2_index) {
                params.bwa2_index = igenome_ref.bwa2_index
            }
            if (igenome_ref.dbsnp) {
                params.dbsnp = igenome_ref.dbsnp
            }
            if (igenome_ref.dbsnp_tbi) {
                params.dbsnp_tbi = igenome_ref.dbsnp_tbi
            }
            if (igenome_ref.known_indels) {
                params.known_indels = igenome_ref.known_indels
            }
            if (igenome_ref.known_indels_tbi) {
                params.known_indels_tbi = igenome_ref.known_indels_tbi
            }
            if (igenome_ref.snpeff_cache) {
                params.snpeff_cache = igenome_ref.snpeff_cache
            }
            if (igenome_ref.vep_cache_version) {
                params.vep_cache_version = igenome_ref.vep_cache_version
            }
            if (igenome_ref.vep_genome) {
                params.vep_genome = igenome_ref.vep_genome
            }
            if (igenome_ref.vep_species) {
                params.vep_species = igenome_ref.vep_species
            }
            if (igenome_ref.vep_cache) {
                params.vep_cache = igenome_ref.vep_cache
            }
        }
    }

    log.info(
        """
    ==============================================================================================================================
    nf-germline-short-read-variant-calling:
     - Nextflow Version
     - Workflow: GATK_VARIANT_CALLING
     - Subworkflows: PREPROCESSING, VARIANT_CALLING, ANNOTATION
     - Loaded genomes set: ${params.genome ? params.genome : 'None'}
     - Reference Genome: ${params.reference}
     - dbSNP VCF: ${params.dbsnp}
     - Known Indels VCF: ${params.known_indels}
     - Input Samplesheet: ${params.input}
     - Output Directory: ${params.outdir}
     - SV Caller: ${params.sv_caller ? params.sv_caller : 'None'}
    ==============================================================================================================================
    """.stripIndent()
    )

    //
    // Prepare reference genome channels
    // Values from nextflow.config params block, override via CLI as needed
    ref_fasta = channel.fromPath(params.reference, checkIfExists: true).collect()
    ref_fai = channel.fromPath(params.reference_index, checkIfExists: true).collect()
    ref_dict = channel.fromPath(params.reference_dict, checkIfExists: true).collect()

    // Prepare known sites channels
    // Values from nextflow.config params block, override via CLI as needed
    dbsnp_vcf = channel.fromPath(params.dbsnp, checkIfExists: true).collect()
    dbsnp_tbi = channel.fromPath(params.dbsnp_tbi, checkIfExists: true).collect()
    known_indels_vcf = channel.fromPath(params.known_indels, checkIfExists: true).collect()
    known_indels_tbi = channel.fromPath(params.known_indels_tbi, checkIfExists: true).collect()

    //
    // Detect input mode and branch accordingly
    // FASTQ mode: run full pipeline (alignment + preprocessing + variant calling)
    // BAM/CRAM mode: skip alignment and optional preprocessing, go directly to variant calling
    //
    input_branched = input_ch.branch {
        fastq: it[1] instanceof List && it[1][0].toString().endsWith('.fastq.gz')
        bam: it[1].toString().endsWith('.bam')
        cram: it[1].toString().endsWith('.cram')
    }

    //
    // SUBWORKFLOW: PREPROCESSING (Steps 1-3) - FASTQ ONLY
    // Includes: FASTP, BWA-MEM2, Sorting, Merging
    //
    
    // Initialize empty channels for alignment output
    ch_alignment_bam = channel.empty()
    ch_alignment_bai = channel.empty()
    
    // Call ALIGNMENT with fastq input - empty channel will cause it to exit early
    ALIGNMENT(
        input_branched.fastq,
        ref_fasta,
        ref_fai,
        ref_dict,
        params.bwa2_index,
        params.index_bwa2_reference,
    )
    
    // Only mix versions from ALIGNMENT if it ran
    ALIGNMENT.out.versions.ifEmpty(channel.empty()).set { align_versions }
    ch_versions = ch_versions.mix(align_versions)
    
    // Get alignment output or empty if no FASTQ input
    ch_alignment_bam = ALIGNMENT.out.bam
    ch_alignment_bai = ALIGNMENT.out.bai
    
    //
    // SUBWORKFLOW: PREPROCESSING (Steps 4-8)
    // Includes: MarkDuplicates, BQSR, Metrics
    //
    if(params.preprocessor){
        PREPROCESSING(
            params.preprocessor,
            ch_alignment_bam,
            ref_fasta,
            ref_fai,
            ref_dict,
            dbsnp_vcf,
            dbsnp_tbi,
            known_indels_vcf,
            known_indels_tbi,
        )
        
        ch_versions = ch_versions.mix(PREPROCESSING.out.versions)
        ch_final_bam = PREPROCESSING.out.bam
        ch_final_bai = PREPROCESSING.out.bai
    }
    else {
        ch_final_bam = ch_alignment_bam
        ch_final_bai = ch_alignment_bai
    }

    // For BAM/CRAM mode: use input directly or convert if needed
    SAMTOOLS_VIEW(
        input_branched.cram,
        ref_fasta
    )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions)

    // Combine all BAM sources
    ch_final_bam = ch_final_bam.mix(input_branched.bam.map { meta, bam, bai -> [meta, bam] }).mix(SAMTOOLS_VIEW.out.bam)
    ch_final_bai = ch_final_bai.mix(input_branched.bam.map { meta, bam, bai -> [meta, bai] }).mix(SAMTOOLS_VIEW.out.bai)
   
    // Small Variant Calling (optional - can be skipped with --skip_variant_calling)
    if (params.small_variant_caller){
        SMALL_VARIANT_CALLING(
            params.small_variant_caller,
            ch_final_bam,
            ch_final_bai,
            ref_fasta,
            ref_fai,
            ref_dict,
            dbsnp_vcf,
            dbsnp_tbi,
        )

        ch_versions = ch_versions.mix(SMALL_VARIANT_CALLING.out.versions)
        // Initialize empty channels for small variant outputs when skipped
        ch_small_vcf = SMALL_VARIANT_CALLING.out.vcf
        ch_small_vcf_tbi = SMALL_VARIANT_CALLING.out.vcf_tbi

    } else {
        ch_small_vcf = channel.empty()
        ch_small_vcf_tbi = channel.empty()
    }

    // Structural Variant Calling (optional)
    if (params.structural_variant_caller){
        STRUCTURAL_VARIANT_CALLING(
            params.structural_variant_caller,
            ch_final_bam,
            ch_final_bai,
            ref_fasta,
            ref_fai,
            params.genome
        )
        ch_versions = ch_versions.mix(STRUCTURAL_VARIANT_CALLING.out.versions)
    }
     // Skip annotation if flag is set (only annotate if small variant calling ran)
    VARIANT_ANNOTATION(
        ch_small_vcf,
        ch_small_vcf_tbi,
        params.snpeff_cache,
        params.vep_cache,
        params.vep_cache_version,
        params.vep_genome,
        params.vep_species,
        ref_fasta
    )
    ch_versions = ch_versions.mix(VARIANT_ANNOTATION.out.versions)

     // Quality control (only run if small variant calling ran)
    VARIANT_ALIGNMENT_QUALITY_CONTROL(
             ch_small_vcf,
             ch_small_vcf_tbi,
             ch_final_bam,
             ch_final_bai,
    )
     
}
