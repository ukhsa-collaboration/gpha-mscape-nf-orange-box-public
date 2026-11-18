#!/usr/bin/env nextflow

process FIRST_ONYX_WRITE {
    /*
        Process:
        - Pushes Orange box analysis results to Onyx and S3 to prepare for publishing an Onyx record
        Inputs:
            - Requires climb_id, nickname of Orange Box module (e.g. QC), outputs from Orange Box modules and
              of *all* Orange Box modules.

        Outputs:
            - Analysis_id files for each module in the form ${climb_id}.${orange_box_module}.analysis_id.  The subesquent
              publish step will then use these with skeleton OnyxAnalysis helper objects to publish each analysis.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:0.6.7'
    cpus 1
    memory '1GB'
    tag "Funnelling ${climb_id} Orange Box analyses: FirstWriteToOnyx"
    publishDir "$params.outdir/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val climb_id
    val orange_box_module
    path "${climb_id}.${orange_box_module}.analysis_fields.json"
    val server
    val bucket

    output:
    path "${climb_id}.${orange_box_module}.temp.analysis_id", emit: temp_analysis_id_file
    path "${climb_id}.${orange_box_module}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    echo '# # # # # starting funnel task: FirstWriteToOnyx'
    onyx_analysis write \
    --climbid $climb_id \
    --output . \
    --server $server \
    --prod \
    --input-json ${climb_id}.${orange_box_module}.analysis_fields.json \
    --orange-box-version ${workflow.manifest.version}
    mv ${climb_id}.onyx_analysis.write.analysis_id.txt ${climb_id}.${orange_box_module}.temp.analysis_id
    mv ${climb_id}.onyx_analysis.write.log.txt ${climb_id}.${orange_box_module}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt
    echo '# # # # # finished funnel task: FirstWriteToOnyx'
    """
}


process S3_UPLOAD {
    /*
        Process:
	    - Pushes Orange box analysis results to Onyx and S3 to prepare for publishing an Onyx record
        Inputs:
            - Requires climb_id, nickname of Orange Box module (e.g. QC), and outputs from Orange Box modules.
              N.b. Will be run on successful completion of all modules.

        Outputs:
            - Analysis_id files for each module in the form ${climb_id}.${orange_box_module}.analysis_id.  The subesquent
              publish step will then use these with skeleton OnyxAnalysis helper objects to publish each analysis.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:0.6.7'
    cpus 1
    memory '1GB'
    tag "Funnelling ${climb_id} Orange Box analyses: S3Upload"
    publishDir "$params.outdir/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val climb_id
    val orange_box_module
    val server
    val bucket
    path "${climb_id}.${orange_box_module}.temp.analysis_id"
    path upload_files
    // qc-specific...  path "${climb_id}_qc_results.json"

    output:
    path "${climb_id}.${orange_box_module}.s3_location.json", emit: s3_location_json
    path "${climb_id}.${orange_box_module}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    echo '# # # # # starting funnel task: S3Upload'

    echo '# # # # # parsing upload_files channel into CSV argument'
    COMMA_SEP_S3_FILES=`echo $upload_files | sed -r {'s/\s+/,/g'}`

    echo '# # # # #   --input-files' \$COMMA_SEP_S3_FILES

    onyx_analysis s3_upload \
        --climbid $climb_id \
        --output . \
        --server $server \
        --prod \
        --bucket $bucket \
        --analysis-id ${climb_id}.${orange_box_module}.temp.analysis_id \
        --input-files \$COMMA_SEP_S3_FILES

    mv \
    ${climb_id}.onyx_analysis.s3_upload.analysis_fields.json \
    ${climb_id}.${orange_box_module}.s3_location.json
    mv \
    ${climb_id}.onyx_analysis.s3_upload.log.txt \
    ${climb_id}.${orange_box_module}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt

    echo '# # # # # finished funnel task: S3Upload'
    """
}


process FINAL_ONYX_UPDATE {
    /*
        Process:
	    - Pushes Orange box analysis results to Onyx and S3 to prepare for publishing an Onyx record
        Inputs:
            - Requires climb_id, nickname of Orange Box module (e.g. QC), and outputs from Orange Box modules.
              N.b. Will be run on successful completion of all modules.

        Outputs:
            - Analysis_id files for each module in the form ${climb_id}.${orange_box_module}.analysis_id.  The subesquent
              publish step will then use these with skeleton OnyxAnalysis helper objects to publish each analysis.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:0.6.7'
    cpus 1
    memory '1GB'
    tag "Funnelling ${climb_id} Orange Box analyses: FinalOnyxUpdate"
    publishDir "$params.outdir/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val climb_id
    val orange_box_module
    path "${climb_id}_qc_results.json"
    val server
    val bucket
    path "${climb_id}.${orange_box_module}.temp.analysis_id"
    path "${climb_id}.${orange_box_module}.s3_location.json"

    output:
    path "${climb_id}.${orange_box_module}.analysis_id", emit: analysis_id_file
    path "${climb_id}.${orange_box_module}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    echo '# # # # # starting funnel task: FinalOnyxUpdate'
    onyx_analysis update \
    --climbid $climb_id \
    --output . \
    --server $server \
    --prod \
    --analysis-id ${climb_id}.${orange_box_module}.temp.analysis_id \
    --input-json ${climb_id}.${orange_box_module}.s3_location.json
    mv \
    ${climb_id}.onyx_analysis.update.analysis_id.txt ${climb_id}.${orange_box_module}.analysis_id
    mv \
   ${climb_id}.onyx_analysis.update.log.txt ${climb_id}.${orange_box_module}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt
    echo '# # # # # finished funnel task: FinalOnyxUpdate'
    """
}


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
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:0.6.7'
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

    // claspar inputs
    path "${climb_id}.CLASPAR_VA.analysis_id"
    path "${climb_id}.CLASPAR_KRAKEN.analysis_id"
    path "${climb_id}.CLASPAR_SYLPH.analysis_id"

    output:
    path "${climb_id}.Orange_Box_Onyx_publish_log.txt", emit: publish_logs

   script:
    """
    echo '# # # # # starting funnel publish step'

    for ANALYSIS_ID_FILE in \
        ${climb_id}.QC.analysis_id \
        ${climb_id}.CLASPAR_VA.analysis_id \
        ${climb_id}.CLASPAR_KRAKEN.analysis_id \
        ${climb_id}.CLASPAR_SYLPH.analysis_id
    do
        echo "Publishing \$ANALYSIS_ID_FILE"

        onyx_analysis publish \
            --climbid $climb_id \
            --output . \
            --server $server \
            --prod \
            --analysis-id \$ANALYSIS_ID_FILE
    done
    mv ${climb_id}.onyx_analysis.publish.log.txt ${climb_id}.Orange_Box_Onyx_publish_log.txt

    echo '# # # # # finished funnel publish step'
"""
}
