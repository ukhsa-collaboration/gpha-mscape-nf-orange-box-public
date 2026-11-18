#!/usr/bin/env nextflow

include { ORANGE_BOX } from "./workflows/orange_box"


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

    ORANGE_BOX(sample_ch, params.server, params.bucket, params.profiles_json, params.taxaplease_db)
}
