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
            - output_dir: Directory to write results to

        Outputs:
            - exit_code: Exit status for the program.
            - result_file: Path to the onyx analysis json file.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-sample-qc:0.2.1'
    cpus 1
    memory '1GB'
    tag "${climb_id}"
    publishDir "$params.outdir/qc_sample", mode: "copy"

    input:
    val climb_id
    val qc_dir
    val server

    output:
    path "${climb_id}.QC.analysis_fields.json", emit: analysis_json
    path "${climb_id}_qc_results.json", emit: upload_files, optional: true
    path "${climb_id}_qc_metrics_log.txt", emit: logs

    script:
    """
    qc_sample -i $climb_id -o . -s $server --store-onyx
    cp ${climb_id}_qc_metrics_analysis_fields.json  ${climb_id}.QC.analysis_fields.json
    """
}
