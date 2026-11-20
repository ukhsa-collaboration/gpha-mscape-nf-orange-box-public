#!/usr/bin/env nextflow
include { FASTQ_READ_STATS        } from "../modules/unclassified_qc.nf"
include { CREATE_READQC_ONYX_JSON } from "../modules/unclassified_qc.nf"

workflow UNCLASSIFIED_QC_ANALYSIS {

    take:
    sample_ch // one samplesheet row per item, used as the meta map

    main:

    ch_reads = sample_ch
        .map { meta ->
            def reads = [meta.unclassified_reads_1, meta.unclassified_reads_2]
                .findAll { r -> r }
                .collect { r -> file(r) }
            tuple(meta, reads)
         }
        .filter { _meta, reads -> reads }

    FASTQ_READ_STATS(ch_reads)

    ch_readqc = FASTQ_READ_STATS.out.readQC
        .map { meta, readQC_file, stats_files ->
            def stats_list = (stats_files instanceof List) ? stats_files : [stats_files]
            tuple(meta, readQC_file.text.trim(), stats_list)
        }

    CREATE_READQC_ONYX_JSON(ch_readqc)

    emit:
    // tuple(meta, analysis_json, [log, stats...])
    results = CREATE_READQC_ONYX_JSON.out.results
        .map { meta, json, log, stats -> tuple(meta, json, [log] + [stats].flatten()) }
}
