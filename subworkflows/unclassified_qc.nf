#!/usr/bin/env nextflow
include { FASTQ_READ_STATS        } from "../modules/unclassified_qc.nf"
include { CREATE_READQC_ONYX_JSON } from "../modules/unclassified_qc.nf"

workflow UNCLASSIFIED_QC_ANALYSIS {

    take:
    ch_meta // one samplesheet row per item, used as the meta map
    server

    main:

    // meta -> tuple(meta, [read1, read2?]); rows with no unclassified reads are dropped
    ch_reads = ch_meta
        .map { meta ->
            def reads = [meta.unclassified_reads_1, meta.unclassified_reads_2]
                .findAll { it }
                .collect { file(it) }
            tuple(meta, reads)
        }
        .filter { meta, reads -> reads }

    FASTQ_READ_STATS(ch_reads)

    ch_readqc = FASTQ_READ_STATS.out.readQC
        .map { meta, readQC_file, stats_files ->
            def stats_list = (stats_files instanceof List) ? stats_files : [stats_files]
            tuple(meta, readQC_file.text.trim(), stats_list)
        }

    CREATE_READQC_ONYX_JSON(ch_readqc, server)

    emit:
    analysis_json = CREATE_READQC_ONYX_JSON.out.stats_summary
    upload_files = CREATE_READQC_ONYX_JSON.out.upload_files
}
