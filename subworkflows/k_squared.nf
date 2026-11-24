#!/usr/bin/env nextflow

include { KRAKEN } from "../modules/k-squared.nf"
include { SUMMARISE_KRAKEN } from "../modules/k-squared.nf"

workflow K_SQUARED {

    take:
    sample_ch
    scan_name
    kraken_db

    main:
    // Create channel for input to kraken process, handles
    // paired or single end reads as input.
    ch_reads = sample_ch
        .map { meta ->
            r1 = meta.human_filtered_reads_1
            r2 = meta.human_filtered_reads_2
            single_end = r2.toString()=='' ? true : false
            meta = [climb_id: meta.climb_id, single_end: single_end]
            r2.toString()=='' ? [meta, [r1]] : [meta, [r1, r2]]
         }
    KRAKEN(ch_reads, scan_name, kraken_db)
    SUMMARISE_KRAKEN(KRAKEN.out.kraken_files, scan_name)

    emit:
    results = SUMMARISE_KRAKEN.out.results
}
