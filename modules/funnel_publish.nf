#!/usr/bin/env nextflow

process PUBLISH_ONYX {
    /*
        Process:
	    - Publishes an Onyx record
        Inputs:
            - Requires climb_id, analysis_id_file (containing analysis_id) and server {synthscape, mscape}
              N.b. Will be run when all modules have successfully completed their Onyx/S3 transfers.

        Outputs:
            - None, bar a log file.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:0.3.1'
    cpus 1
    memory '1GB'
    tag "Funnelling ${climb_id} Orange Box analyses: Publish to Onyx"
    publishDir "$params.outdir/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val climb_id
    val server
    path "${climb_id}.QC.analysis_id"

    output:
    path "${climb_id}.Orange_Box_Onyx_publish_log.txt", emit: publish_logs

    script:
    """
    echo '# # # # # starting funnel publish step'
    orange_box_publish.py    --climb_id $climb_id  --server $server  \
    --analysis_id_files ${climb_id}.QC.analysis_id
    # next lines to simulate completion of process so can test whole pipeline
    #echo 'blahpub' >> ${climb_id}.Orange_Box_Onyx_publish_log.txt
    #echo '# # # # # finished funnel publish step'
    """
}
