#!/usr/bin/env nextflow

process TEST_MULTIPART_MODULE {
    /*
        HACKED FROM DEB'S SAMPLE_QC MODULE FOR TESTING PURPOSES ONLY!!!
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
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-sample-qc:0.1.0'
    cpus 1
    memory '1GB'
    tag "${climb_id}"
    publishDir "$params.outdir/test_multipart_module", mode: "copy"

    input:
    val climb_id
    path qc_dir
    val server

    output:
    path "${climb_id}.multimodule-part1.analysis_fields.json", emit: analysis_json_1
    path "${climb_id}.multimodule-part2.analysis_fields.json", emit: analysis_json_2
    // Using tuple more elegant here but uglier in workflow code: lots of [0] [1] etc. Also cleaner to use different emits for different JSONs to keep downstream processes distinct?
    // tuple (path "${climb_id}.multimodule-part1.analysis_fields.json", path "${climb_id}.multimodule-part2.analysis_fields.json") emit: analysis_json
    path "${climb_id}.mm-part1-output.txt", emit: upload_files_1, optional: true
    tuple (path "${climb_id}.mm-part2-output1.txt"), (path "${climb_id}.mm-part2-output2.txt"), emit: upload_files_2, optional: true
    path "${climb_id}_qc_metrics_log.txt", emit: logs

    script:
    """
    qc_sample -i $climb_id -o . -s $server --store-onyx
    echo "about to copy debs output"
    cp ${climb_id}_qc_metrics_analysis_fields.json  ${climb_id}.QC.analysis_fields.json
    sed -r {'s/ukhsa-classifier-qc-metrics/test-multipart-module-part1/g;'} ${climb_id}.QC.analysis_fields.json > ${climb_id}.multimodule-part1.analysis_fields.json
    sed -r {'s/part1/part2/g;'} ${climb_id}.multimodule-part1.analysis_fields.json > ${climb_id}.multimodule-part2.analysis_fields.json
    echo "some blurb" > ${climb_id}.mm-part1-output.txt
    echo "some more blurb" > ${climb_id}.mm-part2-output1.txt
    echo "even more blurb" > ${climb_id}.mm-part2-output2.txt
    """
}
