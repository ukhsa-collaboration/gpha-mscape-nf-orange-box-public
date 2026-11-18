#!/usr/bin/env nextflow
include { FASTQ_READ_STATS        } from "../modules/unclassified_qc.nf"
include { CREATE_READQC_ONYX_JSON } from "../modules/unclassified_qc.nf"

workflow UNCLASSIFIED_QC_ANALYSIS {

    take:
    ch_meta
    server
    outdir

    main:

    ch_fastqs = ch_meta.map { meta ->
        def reads = [ch_meta.unclassified_reads_1, ch_meta.unclassified_reads_2]
            .findAll { it }
            .collect { file(it) }
        tuple(ch_meta, reads)
    }

    stats_ch = FASTQ_READ_STATS(ch_fastqs, outdir).readQC

    normalized_readQC_complete = stats_ch.map { ch_meta, readQC_file, stats_files ->
        def stats_list = stats_files instanceof List ? stats_files : [stats_files]
        tuple(ch_meta, readQC_file.text, stats_list)
    }

    CREATE_READQC_ONYX_JSON(normalized_readQC_complete, server, outdir)

    emit:
    analysis_json = CREATE_READQC_ONYX_JSON.out.stats_summary
    upload_files = CREATE_READQC_ONYX_JSON.out.upload_files
}
