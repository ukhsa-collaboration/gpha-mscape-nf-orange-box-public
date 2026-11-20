include { QC_UPLOAD_PREP }              from "../subworkflows/onyx_qc_upload.nf"

workflow ONYX_UPLOADS {

    take:
    sample_ch
    server
    bucket

    // QC_SAMPLE outputs
    qc_analysis_json
    qc_upload_files

    // CLASPAR outputs
    viralign_analysis_json
    viralign_upload_files
    kraken_analysis_json
    kraken_upload_files
    sylph_analysis_json
    sylph_upload_files

    // // Unclassified QC_SAMPLE outputs
    unclass_qc_analysis_json
    unclass_qc_upload_files

    main:
    // QC
    QC_UPLOAD_PREP(sample_ch, "QC", qc_analysis_json)

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

    // Publish once every analysis has been written to Onyx and S3.
    PUBLISH_ONYX(
        sample_ch,
        server,
        FOU__QC.out.analysis_id_file,
        // FOU__CLASPAR_VIRALIGN.out.analysis_id_file,
        // FOU__CLASPAR_KRAKEN.out.analysis_id_file,
        // FOU__CLASPAR_SYLPH.out.analysis_id_file,
        // FOU__UNCLASS_QC.out.analysis_id_file,
    )

    emit:
    publish_logs = PUBLISH_ONYX.out.publish_logs
    funnel_logs  = FOW__QC.out.funnel_logs
        .mix(S3U__QC.out.funnel_logs, FOU__QC.out.funnel_logs)
        // .mix(FOW__CLASPAR_VIRALIGN.out.funnel_logs, S3U__CLASPAR_VIRALIGN.out.funnel_logs, FOU__CLASPAR_VIRALIGN.out.funnel_logs)
        // .mix(FOW__CLASPAR_KRAKEN.out.funnel_logs, S3U__CLASPAR_KRAKEN.out.funnel_logs, FOU__CLASPAR_KRAKEN.out.funnel_logs)
        // .mix(FOW__CLASPAR_SYLPH.out.funnel_logs, S3U__CLASPAR_SYLPH.out.funnel_logs, FOU__CLASPAR_SYLPH.out.funnel_logs)
        // .mix(S3U__UNCLASS_QC.out.funnel_logs, FOU__UNCLASS_QC.out.funnel_logs)
}
