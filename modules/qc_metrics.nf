#!/usr/bin/env nextflow

process QC_SAMPLE {
    /*
        Runs qc_sample on the input climb_id. This process takes metrics
        from onyx and compares them to threshold values and determines
        whether the sample passes or fails for the given metric. A summary
        of results is then written to a json file in s3 to enable upload to
        onyx later in the workflow.

        Inputs:
            - climb_id: Climb ID for a given sample
            - Server: server to query onyx on
        Outputs:
            - analysis_json: Path to the onyx analysis json file.
            - upload_files: Output files to be uploaded to s3
            - logs: Log file for the component


    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-sample-qc:latest'
    label "process_single"
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/qc_sample", mode: "copy"

    input:
    val sample_ch

    output:
    tuple val(sample_ch), path "${sample_ch.climb_id}.QC.analysis_fields.json", emit: analysis_json
    tuple val(sample_ch), path "${sample_ch.climb_id}_qc_results.json", emit: upload_files, optional: true
    path "${sample_ch.climb_id}_qc_metrics_log.txt", emit: logs

    script:
    """
    qc_sample -i $sample_ch.climb_id -o . -s $params.server --store-onyx
    cp ${sample_ch.climb_id}_qc_metrics_analysis_fields.json  ${sample_ch.climb_id}.QC.analysis_fields.json
    """

    stub:
    """
    echo '{}' > ${meta.climb_id}.QC.analysis_fields.json
    echo '{}' > ${meta.climb_id}_qc_results.json
    touch ${meta.climb_id}_qc_metrics_log.txt
    """
}
