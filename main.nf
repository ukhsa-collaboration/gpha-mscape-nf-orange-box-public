#!/usr/bin/env nextflow

include { ORANGE_BOX   } from "./workflows/orange_box_analyses"
include { ONYX_UPLOADS } from "./workflows/onyx_uploads"


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

    sample_ch.view

    ORANGE_BOX(sample_ch, params.outdir, params.server, params.bucket, params.profiles_json, params.taxaplease_db)

    if (params.skip_onyx_upload) {
        log.info "skip_onyx_upload is set: Analysis results will not be written to Onyx or uploaded to S3."
    }
    else {
        ONYX_UPLOADS(
            sample_ch,
            server,
            bucket,
            QC_SAMPLE.out.analysis_json,
            QC_SAMPLE.out.upload_files,
            CLASPAR.out.analysis_json_viralign,
            CLASPAR.out.upload_files_viralign,
            CLASPAR.out.analysis_json_kraken,
            CLASPAR.out.upload_files_kraken,
            CLASPAR.out.analysis_json_sylph,
            CLASPAR.out.upload_files_sylph,
            UNCLASSIFIED_QC_ANALYSIS.out.analysis_json,
            UNCLASSIFIED_QC_ANALYSIS.out.upload_files
        )
    }
}
