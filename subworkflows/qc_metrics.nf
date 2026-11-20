#!/usr/bin/env nextflow

include { QC_SAMPLE } from "../modules/qc_metrics.nf"

workflow QC_METRICS {
    // Workflow to retrieve sample QC metrics
    take:
        sample_ch // meta map
    main:
        QC_SAMPLE(sample_ch)
    emit:
        // upload_files is optional in QC_SAMPLE, so a sample without a
        // _qc_results.json drops out here and is not uploaded for QC.
        results = QC_SAMPLE.out.analysis_json.join(QC_SAMPLE.out.upload_files)   // tuple(meta, json, files)
        logs    = QC_SAMPLE.out.logs
}
