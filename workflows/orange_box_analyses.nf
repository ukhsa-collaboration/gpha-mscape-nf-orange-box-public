
include { QC_METRICS                   } from "../subworkflows/qc_metrics.nf"
include { CLASPAR_ANALYSIS             } from "../subworkflows/claspar.nf"
include { UNCLASSIFIED_QC_ANALYSIS     } from "../subworkflows/unclassified_qc.nf"
include { K_SQUARED as K_SQUARED_VIRUS } from "../subworkflows/k_squared.nf"
include { K_SQUARED as K_SQUARED_FUNGI } from "../subworkflows/k_squared.nf"

workflow ORANGE_BOX_ANALYSES {

    take:
        sample_ch

    main:
        // Run analyses
        QC_METRICS(sample_ch)
        CLASPAR_ANALYSIS(sample_ch)
        UNCLASSIFIED_QC_ANALYSIS(sample_ch)
        K_SQUARED_VIRUS(sample_ch, "virus", params.k2_virus_db)
        K_SQUARED_FUNGI(sample_ch, "fungi", params.k2_fungi_db)

        // Every analysis is reshaped to the same contract so ONYX_UPLOAD can treat them identically:
        //   tuple(meta, analysis_name, analysis_json, upload_files)
        // analysis_name is the key used in Onyx/S3 file names (QC, CLASPAR_VA, ...).
        results = channel.empty().mix(
            QC_METRICS.out.results
                .map { meta, json, files -> tuple(meta, 'QC', json, files) },
            CLASPAR_ANALYSIS.out.viralign
                .map { meta, json, csv -> tuple(meta, 'CLASPAR_VA', json, csv) },
            CLASPAR_ANALYSIS.out.kraken
                .map { meta, json, files -> tuple(meta, 'CLASPAR_KRAKEN', json, files) },
            CLASPAR_ANALYSIS.out.sylph
                .map { meta, json, csv -> tuple(meta, 'CLASPAR_SYLPH', json, csv) },
            UNCLASSIFIED_QC_ANALYSIS.out.results
                .map { meta, json, files -> tuple(meta, 'UNCLASS_QC', json, files) },
        )



    emit:
        results


}
