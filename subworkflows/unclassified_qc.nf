#!/usr/bin/env nextflow
include { FASTQ_READ_STATS        } from "../modules/unclassified_qc.nf"
include { CREATE_READQC_ONYX_JSON } from "../modules/unclassified_qc.nf"

workflow UNCLASSIFIED_QC_ANALYSIS {

    take:
    ch_meta // one samplesheet row per item, used as the meta map
    server

    main:

    ch_reads = ch_meta
        .map { ch_meta ->
            def reads = [ch_meta.unclassified_reads_1, ch_meta.unclassified_reads_2]
                .findAll { it }
                .collect { file(it) }
            tuple(ch_meta, reads)
        }
        .filter { ch_meta, reads -> reads }

    ch_reads.view()

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
