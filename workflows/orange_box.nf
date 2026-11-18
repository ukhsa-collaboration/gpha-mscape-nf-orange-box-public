
include { QC_SAMPLE    }              from "../modules/qc_metrics.nf"
include { CLASPAR      }              from "../modules/claspar.nf"
include { ONYX_UPLOADS }              from "../subworkflows/onyx_uploads.nf"
include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX {

    take:
    climb_id
    out_dir
    server
    bucket
    profiles_json
    taxaplease

    main:
    // Run analyses
    // Run on All samples subworkflow
    QC_SAMPLE(climb_id, out_dir, server)
    CLASPAR(climb_id, server, profiles_json, taxaplease)
    UNCLASSIFIED_QC_ANALYSIS(samplesheet, server, outdir)

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
            CLASPAR.out.upload_files_sylph,
            UNCLASSIFIED_QC_ANALYSIS.out.analysis_json,
            UNCLASSIFIED_QC_ANALYSIS.out.upload_files
        )
    }





    PORTAL(
        climb_id,
        QC_ANALYSIS.out.analysis_json,
        UNCLASSIFIED_QC_ANALYSIS.out.analysis_json,
        CLASPAR_ANALYSIS.out.analysis_json_viralign,
        CLASPAR_ANALYSIS.out.analysis_json_kraken,
        CLASPAR_ANALYSIS.out.analysis_json_sylph
    )

    QC_FUNNEL(
        climb_id,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        QC_ANALYSIS.out.analysis_json,
        QC_ANALYSIS.out.upload_files
    )

    CLASPAR_FUNNEL(
        climb_id,
        server,
        bucket,
        PORTAL.out.ready_to_go,

        CLASPAR_ANALYSIS.out.analysis_json_viralign,
        CLASPAR_ANALYSIS.out.upload_files_viralign,

        CLASPAR_ANALYSIS.out.analysis_json_kraken,
        CLASPAR_ANALYSIS.out.upload_files_kraken,

        CLASPAR_ANALYSIS.out.analysis_json_sylph,
        CLASPAR_ANALYSIS.out.upload_files_sylph
    )

    UNCLASSIFIED_QC_FUNNEL(
        climb_id,
        server,
        bucket,
        PORTAL.out.ready_to_go,
        UNCLASSIFIED_QC_ANALYSIS.out.analysis_json,
        UNCLASSIFIED_QC_ANALYSIS.out.upload_files
    )

    PUBLISH_ONYX(
        climb_id,
        server,
        QC_FUNNEL.out.analysis_id_file,
        UNCLASSIFIED_QC_FUNNEL.out.analysis_id_file,
        CLASPAR_FUNNEL.out.viralign_analysis_id,
        CLASPAR_FUNNEL.out.kraken_analysis_id,
        CLASPAR_FUNNEL.out.sylph_analysis_id
    )

    emit:

    analysis_id_file =
        QC_FUNNEL.out.analysis_id_file

    funnel_logs =
        QC_FUNNEL.out.funnel_logs
            .mix(CLASPAR_FUNNEL.out.funnel_logs)
            .mix(UNCLASSIFIED_QC_FUNNEL.out.funnel_logs)
            .mix(PUBLISH_ONYX.out.publish_logs)
}
