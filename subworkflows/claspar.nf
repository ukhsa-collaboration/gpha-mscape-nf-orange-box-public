#!/usr/bin/env nextflow

// include { CLASPAR_PROCESS } from "../modules/clapar.nf"
// include { ONYX_UPLOAD_PROCESS as VIRALIGN_OUP } from "../subworkflows/onyx_uploads.nf"
// include { ONYX_UPLOAD_PROCESS as KRAKEN_OUP }   from "../subworkflows/onyx_uploads.nf"
// include { ONYX_UPLOAD_PROCESS as SYLPH_OUP }    from "../subworkflows/onyx_uploads.nf"

// workflow CLASPAR {
//     // Workflow to retrieve sample QC metrics
//     take:
//         sample_ch
//     main:
//         CLASPAR_PROCESS(sample_ch)

//     emit:
//         analysis_json_viralign = CLASPAR.out.analysis_json_viralign
//         analysis_json_kraken = CLASPAR.out.analysis_json_kraken
//         analysis_json_sylph = CLASPAR.out.analysis_json_sylph
//         upload_files_viralign = CLASPAR.out.upload_files_viralign
//         upload_files_kraken = CLASPAR.out.upload_files_kraken
//         upload_files_sylph = CLASPAR.out.upload_files_sylph
// }

// workflow CLASPAR_ONYX_UPLOAD {

//     take:
//         sample_ch
//         analysis_json
//         upload_files

//     main:
//         VIRALIGN_OUP(
//             sample_ch,
//             "CLASPAR_VA",
//             analysis_json_viralign,
//             upload_files_viralign
//         )

//         KRAKEN_OUP(
//             sample_ch,
//             "CLASPAR_KRAKEN",
//             analysis_json_kraken,
//             upload_files_kraken
//         )

//         SYLPH_OUP(
//             sample_ch,
//             "CLASPAR_SYLPH",
//             analysis_json_sylph,
//             upload_files_sylph
//         )

//     emit:
//         viralign_analysis_id = VIRALIGN_FUNNEL.out.analysis_id_file
//         kraken_analysis_id = KRAKEN_FUNNEL.out.analysis_id_file
//         sylph_analysis_id = SYLPH_FUNNEL.out.analysis_id_file
//         funnel_logs = VIRALIGN_FUNNEL.out.funnel_logs
//                 .mix(KRAKEN_FUNNEL.out.funnel_logs)
//                 .mix(SYLPH_FUNNEL.out.funnel_logs)
// }
