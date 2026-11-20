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

    // CLASPAR_FUNNEL(
    //     climb_id,
    //     server,
    //     bucket,

    //     CLASPAR_ANALYSIS.out.analysis_json_viralign,
    //     CLASPAR_ANALYSIS.out.upload_files_viralign,

    //     CLASPAR_ANALYSIS.out.analysis_json_kraken,
    //     CLASPAR_ANALYSIS.out.upload_files_kraken,

    //     CLASPAR_ANALYSIS.out.analysis_json_sylph,
    //     CLASPAR_ANALYSIS.out.upload_files_sylph
    // )

    // PUBLISH_ONYX(
    //     climb_id,
    //     server,
    //     QC_FUNNEL.out.analysis_id_file,
    //     CLASPAR_FUNNEL.out.viralign_analysis_id,
    //     CLASPAR_FUNNEL.out.kraken_analysis_id,
    //     CLASPAR_FUNNEL.out.sylph_analysis_id
    // )


    // CLASPAR
    // CLASPAR_VIRALIGN_UPLOAD_PREP(sample_ch, "CLASPAR_VA", analysis_json_viralign)
    // CLASPAR_KRAKEN_UPLOAD_PREP(sample_ch, "CLASPAR_KRAKEN", analysis_json_kraken)
    // CLASPAR_SYLPH_UPLOAD_PREP(sample_ch, "CLASPAR_SYLPH", analysis_json_sylph)

    // // ClasPar: viral aligner
    // FOW__CLASPAR_VIRALIGN(sample_ch, "CLASPAR_VA", viralign_analysis_json, server, bucket)
    // S3U__CLASPAR_VIRALIGN(sample_ch, "CLASPAR_VA", server, bucket, FOW__CLASPAR_VIRALIGN.out.temp_analysis_id_file, viralign_upload_files)
    // FOU__CLASPAR_VIRALIGN(sample_ch, "CLASPAR_VA", viralign_analysis_json, server, bucket, FOW__CLASPAR_VIRALIGN.out.temp_analysis_id_file, S3U__CLASPAR_VIRALIGN.out.s3_location_json)

    // // ClasPar: kraken
    // FOW__CLASPAR_KRAKEN(sample_ch, "CLASPAR_KRAKEN", kraken_analysis_json, server, bucket)
    // S3U__CLASPAR_KRAKEN(sample_ch, "CLASPAR_KRAKEN", server, bucket, FOW__CLASPAR_KRAKEN.out.temp_analysis_id_file, kraken_upload_files)
    // FOU__CLASPAR_KRAKEN(sample_ch, "CLASPAR_KRAKEN", kraken_analysis_json, server, bucket, FOW__CLASPAR_KRAKEN.out.temp_analysis_id_file, S3U__CLASPAR_KRAKEN.out.s3_location_json)

    // // ClasPar: sylph
    // FOW__CLASPAR_SYLPH(sample_ch, "CLASPAR_SYLPH", sylph_analysis_json, server, bucket)
    // S3U__CLASPAR_SYLPH(sample_ch, "CLASPAR_SYLPH", server, bucket, FOW__CLASPAR_SYLPH.out.temp_analysis_id_file, sylph_upload_files)
    // FOU__CLASPAR_SYLPH(sample_ch, "CLASPAR_SYLPH", sylph_analysis_json, server, bucket, FOW__CLASPAR_SYLPH.out.temp_analysis_id_file, S3U__CLASPAR_SYLPH.out.s3_location_json)

    // // Unclassified QC
    // FOW__UNCLASS_QC(sample_ch, "UNCLASS_QC", unclass_qc_analysis_json, server, bucket)
    // S3U__UNCLASS_QC(sample_ch, "UNCLASS_QC", server, bucket, FOW__UNCLASS_QC.out.temp_analysis_id_file, unclass_qc_upload_files)
    // FOU__UNCLASS_QC(sample_ch, "UNCLASS_QC", unclass_qc_analysis_json, server, bucket, FOW__UNCLASS_QC.out.temp_analysis_id_file, S3U__UNCLASS_QC.out.s3_location_json)

    // // Publish once every analysis has been written to Onyx and S3.
    // PUBLISH_ONYX(
    //     sample_ch,
    //     server,
    //     FOU__QC.out.analysis_id_file,
    //     // FOU__CLASPAR_VIRALIGN.out.analysis_id_file,
    //     // FOU__CLASPAR_KRAKEN.out.analysis_id_file,
    //     // FOU__CLASPAR_SYLPH.out.analysis_id_file,
    //     // FOU__UNCLASS_QC.out.analysis_id_file,
    // )

    // emit:
    // publish_logs = PUBLISH_ONYX.out.publish_logs
    // funnel_logs  = FOW__QC.out.funnel_logs
    //     .mix(S3U__QC.out.funnel_logs, FOU__QC.out.funnel_logs)
    //     // .mix(FOW__CLASPAR_VIRALIGN.out.funnel_logs, S3U__CLASPAR_VIRALIGN.out.funnel_logs, FOU__CLASPAR_VIRALIGN.out.funnel_logs)
    //     // .mix(FOW__CLASPAR_KRAKEN.out.funnel_logs, S3U__CLASPAR_KRAKEN.out.funnel_logs, FOU__CLASPAR_KRAKEN.out.funnel_logs)
    //     // .mix(FOW__CLASPAR_SYLPH.out.funnel_logs, S3U__CLASPAR_SYLPH.out.funnel_logs, FOU__CLASPAR_SYLPH.out.funnel_logs)
    //     // .mix(S3U__UNCLASS_QC.out.funnel_logs, FOU__UNCLASS_QC.out.funnel_logs)
}
