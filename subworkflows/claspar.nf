#!/usr/bin/env nextflow

include { CLASPAR_PROCESS } from "../modules/claspar.nf"

workflow CLASPAR {
    // Workflow to retrieve sample QC metrics
    take:
        sample_ch
    emit:
        // Each emit is tuple(meta, analysis_json, upload_files)
        viralign = CLASPAR_PROCESS.out.viralign
        kraken   = CLASPAR_PROCESS.out.kraken
            .map { meta, json, genera, species -> tuple(meta, json, [genera, species]) }
        sylph    = CLASPAR_PROCESS.out.sylph
}
