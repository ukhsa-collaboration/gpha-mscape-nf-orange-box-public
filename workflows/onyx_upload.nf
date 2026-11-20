include { QC_METRICS_ONYX_UPLOAD }              from "../subworkflows/qc_metrics.nf"

workflow ONYX_UPLOAD {

    take:
    results // tuple(meta, analysis_name, analysis_json, upload_files)

    main:
    // 1. Create the Onyx analysis record (one task per sample x analysis)
    FIRST_ONYX_WRITE(
        results.map { sample_ch, name, json, files -> tuple(meta, name, json) }
    )

    // 2. Upload result files to S3. Join on [meta, analysis_name] so each temp
    //    analysis id is paired with its own sample's files, whatever order tasks finish in.
    S3_UPLOAD(
        FIRST_ONYX_WRITE.out.temp_analysis_id
            .join(results.map { sample_ch, name, json, files -> tuple(meta, name, files) }, by: [0, 1])
    )

     // 3. Write the S3 locations back to the Onyx record
    FINAL_ONYX_UPDATE(
        FIRST_ONYX_WRITE.out.temp_analysis_id
            .join(S3_UPLOAD.out.s3_location_json, by: [0, 1])
    )

    // 4. Publish. groupTuple() with no size only emits once FINAL_ONYX_UPDATE has
    //    finished for every sample and analysis (same barrier as .collect()), but still
    //    gives one PUBLISH_ONYX task per sample with all of that sample's analysis ids.
    PUBLISH_ONYX(
        FINAL_ONYX_UPDATE.out.analysis_id
            .map { meta, name, id_file -> tuple(meta, id_file) }
            .groupTuple()
    )

    emit:
    publish_logs = PUBLISH_ONYX.out.publish_logs
    funnel_logs  = FIRST_ONYX_WRITE.out.funnel_logs
        .mix(S3_UPLOAD.out.funnel_logs, FINAL_ONYX_UPDATE.out.funnel_logs)

}
