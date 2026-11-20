#!/usr/bin/env nextflow

include { ORANGE_BOX_ANALYSES   } from "./workflows/orange_box_analyses"
include { ONYX_UPLOAD } from "./workflows/onyx_upload"


workflow {
    if (params.samplesheet){
        samplesheet_ch = channel.fromPath(params.samplesheet)
        sample_ch = samplesheet_ch.splitCsv(header: true, quote: '\"')
            .map { row -> row }   // whole row is the meta map
    }
    else{
        exit(1, "Please specify a --samplesheet")
    }
    if (!params.skip_onyx_upload && !params.bucket){
        exit(1, "Please specify a --bucket, or pass --skip_onyx_upload to run without Onyx/S3 uploads")
    }

    sample_ch.view()

    ORANGE_BOX_ANALYSES(sample_ch)
    if (params.onyx_upload) {
            ch_results = Channel.empty().mix(
                sample_ch,
                ORANGE_BOX_ANALYSES.out.qc_metrics_analysis_json,
                ORANGE_BOX_ANALYSES.out.qc_metrics_upload_files,
                // ANALYSIS.out.kraken,
                // ANALYSIS.out.viralign,
                // ANALYSIS.out.sylph,
                // ANALYSIS.out.unclassified
            )
            ONYX_UPLOAD(ch_results)
        }
}
