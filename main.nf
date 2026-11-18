#!/usr/bin/env nextflow

include { ORANGE_BOX } from "./workflows/orange_box"


workflow {
    if (params.samplesheet){
        samplesheet_ch = channel.fromPath(params.samplesheet)
    }
    else{
        exit(1, "Please specify a --samplesheet")
    }
    if (!params.skip_onyx_upload && !params.bucket){
        exit(1, "Please specify a --bucket, or pass --skip_onyx_upload to run without Onyx/S3 uploads")
    }

    samplesheet_ch.view()
    //  split samplesheet CSV into channels
    samples = samplesheet_ch.splitCsv(header: true, quote: '\"')
        .map { row ->
            def climb_id = row.climb_id
            return climb_id
        }
        .set { ch_climbids }

    ch_meta = samplesheet.map { row -> row }   // whole row is the meta map
    ch_climb_id = ch_meta.map { meta -> meta.climb_id }

    ch_meta.view()
    ch_climb_id.view()

    ORANGE_BOX(ch_climb_id, ch_meta, params.outdir, params.server, params.bucket, params.profiles_json, params.taxaplease_db)
}
