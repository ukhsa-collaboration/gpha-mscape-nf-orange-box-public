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
            - exit_code: Exit status for the program.
            - result_file: Path to the onyx analysis json file.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-sample-qc:latest'
    cpus 1
    memory '1GB'
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/qc_sample", mode: "copy"

    input:
    val sample_ch
    val server

    output:
    path "${sample_ch.climb_id}.QC.analysis_fields.json", emit: analysis_json
    path "${sample_ch.climb_id}_qc_results.json", emit: upload_files, optional: true
    path "${sample_ch.climb_id}_qc_metrics_log.txt", emit: logs

    script:
    """
    qc_sample -i $sample_ch.climb_id -o . -s $server --store-onyx
    cp ${sample_ch.climb_id}_qc_metrics_analysis_fields.json  ${sample_ch.climb_id}.QC.analysis_fields.json
    """
}
