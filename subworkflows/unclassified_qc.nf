#!/usr/bin/env nextflow
include { FASTQ_READ_STATS        } from "../modules/unclassified_qc.nf"
include { CREATE_READQC_ONYX_JSON } from "../modules/unclassified_qc.nf"

workflow UNCLASSIFIED_QC_ANALYSIS {

    take:
    ch_meta
    server
    outdir

    main:

    ch_meta
        .map { row ->
            def climb_id = row.climb_id
            def fastq1 = row.unclassified_reads_1
            def fastq2 = row.containsKey('unclassified_reads_2') ? row.unclassified_reads_2 : null

            if (fastq2) {
                tuple(climb_id, [fastq1, fastq2])
            } else {
                tuple(climb_id, [fastq1])
            }
        }

    stats_ch = FASTQ_READ_STATS(ch_fastqs, outdir).readQC

    normalized_readQC_complete = stats_ch
        .map { climb_id, readQC_file, stats_files ->
            def stats_list = (stats_files instanceof List) ? stats_files : [stats_files]
            def qc_text = readQC_file.text
            tuple(climb_id, qc_text, stats_list)
        }

    CREATE_READQC_ONYX_JSON(
        normalized_readQC_complete,
        server,
        outdir
    )

    emit:
    analysis_json = CREATE_READQC_ONYX_JSON.out.stats_summary
    upload_files = CREATE_READQC_ONYX_JSON.out.upload_files
}
