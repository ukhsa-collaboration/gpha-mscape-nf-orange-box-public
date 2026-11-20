
include { QC_METRICS               } from "../subworkflows/qc_metrics.nf"
include { CLASPAR                  } from "../subworkflows/claspar.nf"
include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX_ANALYSES {

    take:
        sample_ch

    main:
        // Run analyses
        // Run on All samples subworkflow
        QC_METRICS(sample_ch)
        CLASPAR(sample_ch)
        // UNCLASSIFIED_QC_ANALYSIS(sample_ch, server)

        // Every analysis is reshaped to the same contract so ONYX_UPLOAD can treat them identically:
        //   tuple(meta, analysis_name, analysis_json, upload_files)
        // analysis_name is the key used in Onyx/S3 file names (QC, CLASPAR_VA, ...).
        results = channel.empty().mix(
            QC_METRICS.out.results
                .map { meta, json, files -> tuple(meta, 'QC', json, files) },
            // CLASPAR.out.viralign
            //     .map { meta, json, csv -> tuple(meta, 'CLASPAR_VA', json, csv) },
            // CLASPAR.out.kraken
            //     .map { meta, json, genera, species -> tuple(meta, 'CLASPAR_KRAKEN', json, [genera, species]) },
            // CLASPAR.out.sylph
            //     .map { meta, json, csv -> tuple(meta, 'CLASPAR_SYLPH', json, csv) },
            // // UNCLASSIFIED_QC_ANALYSIS.out.results
            //     .map { meta, json, files -> tuple(meta, 'UNCLASS_QC', json, files) },
        )



    emit:
        results


}
