
include { QC_SAMPLE    }              from "../modules/qc_metrics.nf"
include { CLASPAR      }              from "../modules/claspar.nf"
include { ONYX_UPLOADS }              from "../subworkflows/onyx_uploads.nf"
include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX {

    take:
    sample_ch
    server
    bucket
    profiles_json
    taxaplease

    main:
    // Run analyses
    // Run on All samples subworkflow
    QC_SAMPLE(sample_ch, server)
    CLASPAR(sample_ch, server, profiles_json, taxaplease)
    UNCLASSIFIED_QC_ANALYSIS(sample_ch, server)

    if (params.skip_onyx_upload) {
        log.info "skip_onyx_upload is set: QC and ClasPar results will not be written to Onyx or uploaded to S3."
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
