#!/usr/bin/env nextflow

include { ORANGE_BOX_ANALYSES } from "./workflows/orange_box_analyses"
include { ONYX_UPLOAD         } from "./workflows/onyx_upload"


workflow {
    if (!params.samplesheet){
        error "Please specify a --samplesheet"
    }
    if (params.onyx_upload && !params.bucket){
        error "Please specify a --bucket when running with --onyx_upload"
    }

    // One item per samplesheet row; the whole row is the meta map (meta.climb_id etc.)
    sample_ch = channel.fromPath(params.samplesheet)
        .splitCsv(header: true, quote: '"')

    // Analyses
    ORANGE_BOX_ANALYSES(sample_ch)

    // Onyx uploads
    if (params.onyx_upload){
        // Make sure all analyses are complete before doing anything with Onyx
        ch_gated = ORANGE_BOX_ANALYSES.out.results
        .collect(flat: false)   // waits until every analysis task in the run has finished
        .flatMap { it }         // re-emits each tuple(meta, analysis_name, json, files)
        ONYX_UPLOAD(ch_gated)
    }
}
