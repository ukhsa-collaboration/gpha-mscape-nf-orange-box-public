include { FIRST_ONYX_WRITE  }                 from "../modules/onyx_upload_processes.nf"
include { S3_UPLOAD         }                 from "../modules/onyx_upload_processes.nf"
include { FINAL_ONYX_UPDATE }                 from "../modules/onyx_upload_processes.nf"

workflow ONYX_UPLOADS {

    take:
    // QC_SAMPLE outputs
    qc_analysis_json
    qc_upload_files

    FIRST_ONYX_WRITE(sample_ch, "QC", qc_analysis_json, ${params.server}, ${params.bucket})
    S3_UPLOAD(sample_ch, "QC", server, bucket, FOW__QC.out.temp_analysis_id_file, qc_upload_files)
    FINAL_ONYX_UPDATE(sample_ch, "QC", qc_analysis_json, server, bucket, FOW__QC.out.temp_analysis_id_file, S3U__QC.out.s3_location_json)

    emit:
    upload_id_file = FINAL_ONYX_UPDATE.out.analysis_id_file
}
