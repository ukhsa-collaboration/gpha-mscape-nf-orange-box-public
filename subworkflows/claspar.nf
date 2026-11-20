#!/usr/bin/env nextflow

include { CLASPAR } from "../modules/claspar.nf"

workflow CLASPAR_ANALYSIS {
    // Workflow to retrieve sample QC metrics
    take:
        sample_ch

    main:
        CLASPAR(sample_ch)

    emit:
        // Each emit is tuple(meta, analysis_json, upload_files)
        viralign = CLASPAR.out.viralign
        kraken   = CLASPAR.out.kraken
            .map { meta, json, genera, species -> tuple(meta, json, [genera, species]) }
        sylph    = CLASPAR.out.sylph
}
