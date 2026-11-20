#!/usr/bin/env nextflow

include { QC_SAMPLE } from "../modules/qc_metrics.nf"

include { ONYX_UPLOAD_PROCESS } from "../subworkflows/onyx_uploads.nf"

workflow QC_METRICS {
    // Workflow to retrieve sample QC metrics
    take:
        sample_ch
    main:
        QC_SAMPLE(sample_ch)
    emit:
        analysis_json = QC_SAMPLE.out.analysis_json
        upload_files = QC_SAMPLE.out.upload_files
}

workflow QC_METRICS_ONYX_UPLOAD {

    take:
        sample_ch
        analysis_json
        upload_files

    main:
        ONYX_UPLOAD_PROCESS(
            sample_ch,
            "QC",
            analysis_json,
            upload_files
        )

    emit:
        analysis_id_file = ONYX_UPLOAD_PROCESS.out.analysis_id_file
        funnel_logs = ONYX_UPLOAD_PROCESS.out.funnel_logs
}
