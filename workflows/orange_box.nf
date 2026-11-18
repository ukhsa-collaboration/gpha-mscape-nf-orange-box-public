#!/usr/bin/env nextflow

include { QC_SAMPLE }              from "../modules/qc_metrics.nf"
include { CLASPAR }                from "../modules/claspar.nf"



workflow ORANGE_BOX {

    take:
    climb_id
    out_dir
    server
    bucket
    profiles_json
    taxaplease

    main:
    // Run anlayses
    // Run on All samples subworkflow
    QC_SAMPLE(climb_id, out_dir, server)
    CLASPAR(climb_id, server, profiles_json, taxaplease)

    if (params.skip_onyx_upload) {
        log.info "skip_onyx_upload is set: QC and ClasPar results will not be written to Onyx or uploaded to S3."
    }
    else {
        ONYX_UPLOADS(
            climb_id,
            server,
            bucket,
            QC_SAMPLE.out.analysis_json,
            QC_SAMPLE.out.upload_files,
            CLASPAR.out.analysis_json_viralign,
            CLASPAR.out.upload_files_viralign,
            CLASPAR.out.analysis_json_kraken,
            CLASPAR.out.upload_files_kraken,
            CLASPAR.out.analysis_json_sylph,
            CLASPAR.out.upload_files_sylph
        )
    }

}
