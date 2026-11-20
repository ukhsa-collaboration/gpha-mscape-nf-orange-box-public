#!/usr/bin/env nextflow
process FIRST_ONYX_WRITE {
    /*
        Process:
        - Creates the Onyx analysis record for one sample x analysis.
        Inputs:
           - tuple(meta, analysis_name, analysis_json): meta map (needs climb_id), name of the
              Orange Box analysis (e.g. QC) and its analysis_fields json.
        Outputs:
            - temp_analysis_id: tuple(meta, analysis_name, temp analysis id file)
            - funnel_logs: transfer log
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${meta.climb_id}:${analysis_name}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    tuple val(meta), val(analysis_name), path(analysis_json)

    output:
    tuple val(meta), val(analysis_name), path("${meta.climb_id}.${analysis_name}.temp.analysis_id"), emit: temp_analysis_id
    path "${meta.climb_id}.${analysis_name}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    onyx_analysis write \
        --climbid ${meta.climb_id} \
        --output . \
        --server ${params.server} \
        --prod \
        --input-json ${meta.climb_id}.${analysis_name}.analysis_fields.json \
        --orange-box-version ${workflow.manifest.version}
    mv ${meta.climb_id}.onyx_analysis.write.analysis_id.txt ${meta.climb_id}.${analysis_name}.temp.analysis_id
    mv ${meta.climb_id}.onyx_analysis.write.log.txt ${meta.climb_id}.${analysis_name}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt
    """

    stub:
    """
    touch ${meta.climb_id}.${analysis_name}.temp.analysis_id
    touch ${meta.climb_id}.${analysis_name}.FirstWriteToOnyx.Orange_Box_Onyx_S3_transfer_log.txt
    """
}


process S3_UPLOAD {
    /*
        Process:
	    - Uploads analysis to S3 and prepares publishing an Onyx record
        Inputs:
            - tuple(meta, analysis_name, temp_analysis_id, upload_files)
        Outputs:
            - s3_location_json: tuple(meta, analysis_name, s3 location json)
            - funnel_logs: transfer log
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${meta.climb_id}:${analysis_name}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    tuple val(meta), val(analysis_name), path(temp_analysis_id), path(upload_files)

    output:
    tuple val(meta), val(analysis_name), path("${meta.climb_id}.${analysis_name}.s3_location.json"), emit: s3_location_json
    path "${meta.climb_id}.${analysis_name}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    def files = [upload_files].flatten().join(',')
    """
    onyx_analysis s3_upload \\
        --climbid ${meta.climb_id} \\
        --output . \\
        --server ${params.server} \\
        --prod \\
        --bucket ${params.bucket} \\
        --analysis-id ${temp_analysis_id} \\
        --input-files ${files}

    mv ${meta.climb_id}.onyx_analysis.s3_upload.analysis_fields.json ${meta.climb_id}.${analysis_name}.s3_location.json
    mv ${meta.climb_id}.onyx_analysis.s3_upload.log.txt ${meta.climb_id}.${analysis_name}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt
    """

    stub:
    """
    echo '{}' > ${meta.climb_id}.${analysis_name}.s3_location.json
    touch ${meta.climb_id}.${analysis_name}.S3Upload.Orange_Box_Onyx_S3_transfer_log.txt
    """
}


process FINAL_ONYX_UPDATE {
    /*
        Process:
	        - Writes the S3 locations back to the Onyx analysis record.
        Inputs:
            - tuple(meta, analysis_name, temp_analysis_id, s3_location_json)
        Outputs:
            - analysis_id: tuple(meta, analysis_name, final analysis id file)
            - funnel_logs: transfer log
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${meta.climb_id}:${analysis_name}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    tuple val(meta), val(analysis_name), path(temp_analysis_id), path(s3_location_json)

    output:
    tuple val(meta), val(analysis_name), path("${meta.climb_id}.${analysis_name}.analysis_id"), emit: analysis_id
    path "${meta.climb_id}.${analysis_name}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt", emit: funnel_logs

    script:
    """
    onyx_analysis update \\
        --climbid ${meta.climb_id} \\
        --output . \\
        --server ${params.server} \\
        --prod \\
        --analysis-id ${temp_analysis_id} \\
        --input-json ${s3_location_json}
    mv ${meta.climb_id}.onyx_analysis.update.analysis_id.txt ${meta.climb_id}.${analysis_name}.analysis_id
    mv ${meta.climb_id}.onyx_analysis.update.log.txt ${meta.climb_id}.${analysis_name}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt
    """

    stub:
    """
    touch ${meta.climb_id}.${analysis_name}.analysis_id
    touch ${meta.climb_id}.${analysis_name}.FinalOnyxUpdate.Orange_Box_Onyx_S3_transfer_log.txt
    """
}


process PUBLISH_ONYX {
    /*
        Process:
        - Publishes every Onyx analysis record for one sample.
        Inputs:
            - tuple(meta, analysis_id_files): all final analysis id files for the sample.
              Only runs once every analysis has finished its Onyx/S3 transfer.
        Outputs:
            - publish_logs: log file
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label "process_single"
    tag "${meta.climb_id}"
    publishDir "${params.outdir}/funnel", mode: "copy"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5

    input:
    tuple val(meta), path(analysis_id_files)

    output:
    path "${meta.climb_id}.Orange_Box_Onyx_publish_log.txt", emit: publish_logs

    script:
    def id_files = [analysis_id_files].flatten().join(' ')
    """
    for ANALYSIS_ID_FILE in ${id_files}
    do
        onyx_analysis publish \\
            --climbid ${meta.climb_id} \\
            --output . \\
            --server ${params.server} \\
            --prod \\
            --analysis-id \$ANALYSIS_ID_FILE
    done
    mv ${meta.climb_id}.onyx_analysis.publish.log.txt ${meta.climb_id}.Orange_Box_Onyx_publish_log.txt
    """

    stub:
    def id_files = [analysis_id_files].flatten().join(' ')
    """
    echo "would publish: ${id_files}" > ${meta.climb_id}.Orange_Box_Onyx_publish_log.txt
    """
}
