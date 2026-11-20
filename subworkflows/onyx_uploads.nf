include { FIRST_ONYX_WRITE }  from "../modules/onyx_upload_processes.nf"
include { S3_UPLOAD }         from "../modules/onyx_upload_processes.nf"
include { FINAL_ONYX_UPDATE } from "../modules/onyx_upload_processes.nf"

workflow ONYX_UPLOAD_PROCESS {

    take:
    sample_ch
    analysis_name
    analysis_json
    upload_files

    main:
        FIRST_ONYX_WRITE(
            sample_ch,
            analysis_name,
            analysis_json,
        )

        S3_UPLOAD(
            sample_ch,
            analysis_name,
            FIRST_ONYX_WRITE.out.temp_analysis_id_file,
            upload_files
        )

        FINAL_ONYX_UPDATE(
            climb_id,
            analysis_name,
            analysis_json,
            FIRST_ONYX_WRITE.out.temp_analysis_id_file,
            S3_UPLOAD.out.s3_location_json
        )

    emit:
        analysis_id_file = FINAL_ONYX_UPDATE.out.analysis_id_file

        funnel_logs = FIRST_ONYX_WRITE.out.funnel_logs
            .mix(S3_UPLOAD.out.funnel_logs)
            .mix(FINAL_ONYX_UPDATE.out.funnel_logs)
}
