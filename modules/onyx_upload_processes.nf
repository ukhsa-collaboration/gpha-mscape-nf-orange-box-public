#!/usr/bin/env nextflow
process FIRST_ONYX_WRITE {
    /*
        Process:
        - Pushes Orange box analysis results to Onyx and S3 to prepare for publishing an Onyx record
        Inputs:
            - Requires sample channel, name of analysis module (e.g. QC), outputs from Orange Box modules and
              of *all* Orange Box modules.

        Outputs:
            - Analysis_id files for each module in the form ${climb_id}.${orange_box_module}.analysis_id.  The subesquent
              publish step will then use these with skeleton OnyxAnalysis helper objects to publish each analysis.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val sample_ch
    val analysis_name
    path "${sample_ch.climb_id}.${orange_box_module}.analysis_fields.json"


    output:
    path "${sample_ch.climb_id}.${analysis_name}.temp.analysis_id", emit: temp_analysis_id_file
    path "${sample_ch.climb_id}.${analysis_name}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    onyx_analysis write \
    --climbid ${sample_ch.climb_id} \
    --output . \
    --server ${params.server} \
    --prod \
    --input-json ${sample_ch.climb_id}.${analysis_name}.analysis_fields.json \
    --orange-box-version ${workflow.manifest.version}
    mv ${sample_ch.climb_id}.onyx_analysis.write.analysis_id.txt ${sample_ch.climb_id}.${analysis_name}.temp.analysis_id
    mv ${sample_ch.climb_id}.onyx_analysis.write.log.txt ${sample_ch.climb_id}.${analysis_name}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt
    """
}


process S3_UPLOAD {
    /*
        Process:
	    - Pushes Orange box analysis results to Onyx and S3 to prepare for publishing an Onyx record
        Inputs:
            - Requires sample channel, name of anlaysis module (e.g. QC), and outputs from Orange Box modules.
              N.b. Will be run on successful completion of all modules.

        Outputs:
            - Analysis_id files for each module in the form ${climb_id}.${orange_box_module}.analysis_id.  The subesquent
              publish step will then use these with skeleton OnyxAnalysis helper objects to publish each analysis.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val sample_ch
    val analysis_name
    path "${sample_ch.climb_id}.${analysis_name}.temp.analysis_id"
    path upload_files

    output:
    path "${sample_ch.climb_id}.${analysis_name}.s3_location.json", emit: s3_location_json
    path "${sample_ch.climb_id}.${analysis_name}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """

    COMMA_SEP_S3_FILES=`echo ${upload_files} | sed -r {'s/\s+/,/g'}`


    onyx_analysis s3_upload \
        --climbid ${sample_ch.climb_id} \
        --output . \
        --server ${params.server} \
        --prod \
        --bucket ${params.bucket} \
        --analysis-id ${sample_ch.climb_id}.${analysis_name}.temp.analysis_id \
        --input-files \$COMMA_SEP_S3_FILES

    mv \
    ${sample_ch.climb_id}.onyx_analysis.s3_upload.analysis_fields.json \
    ${sample_ch.climb_id}.${analysis_name}.s3_location.json
    mv \
    ${sample_ch.climb_id}.onyx_analysis.s3_upload.log.txt \
    ${sample_ch.climb_id}.${analysis_name}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt

    """
}


process FINAL_ONYX_UPDATE {
    /*
        Process:
	    - Pushes Orange box analysis results to Onyx and S3 to prepare for publishing an Onyx record
        Inputs:
            - Requires sample channel, name of analysis module (e.g. QC), and outputs from Orange Box modules.
              N.b. Will be run on successful completion of all modules.

        Outputs:
            - Analysis_id files for each module in the form ${climb_id}.${orange_box_module}.analysis_id.  The subesquent
              publish step will then use these with skeleton OnyxAnalysis helper objects to publish each analysis.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val sample_ch
    val analysis_name
    path "${sample_ch.climb_id}_qc_results.json"
    path "${sample_ch.climb_id}.${analysis_name}.temp.analysis_id"
    path "${sample_ch.climb_id}.${analysis_name}.s3_location.json"

    output:
    path "${sample_ch.climb_id}.${analysis_name}.analysis_id", emit: analysis_id_file
    path "${sample_ch.climb_id}.${analysis_name}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    onyx_analysis update \
    --climbid ${sample_ch.climb_id} \
    --output . \
    --server ${params.server} \
    --prod \
    --analysis-id ${sample_ch.climb_id}.${analysis_name}.temp.analysis_id \
    --input-json ${sample_ch.climb_id}.${analysis_name}.s3_location.json
    mv \
    ${sample_ch.climb_id}.onyx_analysis.update.analysis_id.txt ${sample_ch.climb_id}.${analysis_name}.analysis_id
    mv \
   ${sample_ch.climb_id}.onyx_analysis.update.log.txt ${sample_ch.climb_id}.${analysis_name}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt
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
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    val sample_ch
    // QC Analysis inputs
    path "${sample_ch.climb_id}.QC.analysis_id"
    // claspar inputs
    path "${sample_ch.climb_id}.CLASPAR_VA.analysis_id"
    path "${sample_ch.climb_id}.CLASPAR_KRAKEN.analysis_id"
    path "${sample_ch.climb_id}.CLASPAR_SYLPH.analysis_id"
    // Unclassified QC Analysis inputs
    path "${sample_ch.climb_id}.UNCLASS_QC.analysis_id"

    output:
    path "${sample_ch.climb_id}.Orange_Box_Onyx_publish_log.txt", emit: publish_logs

    // QC Analysis inputs
    path "${sample_ch.climb_id}.UNCLASS_QC.analysis_id"

   script:
    """

    for ANALYSIS_ID_FILE in \
        ${sample_ch.climb_id}.QC.analysis_id \
        ${sample_ch.climb_id}.CLASPAR_VA.analysis_id \
        ${sample_ch.climb_id}.CLASPAR_KRAKEN.analysis_id \
        ${sample_ch.climb_id}.CLASPAR_SYLPH.analysis_id
    do

        onyx_analysis publish \
            --climbid ${sample_ch.climb_id} \
            --output . \
            --server ${params.server} \
            --prod \
            --analysis-id \$ANALYSIS_ID_FILE
    done
    mv ${sample_ch.climb_id}.onyx_analysis.publish.log.txt ${sample_ch.climb_id}.Orange_Box_Onyx_publish_log.txt

"""
}
