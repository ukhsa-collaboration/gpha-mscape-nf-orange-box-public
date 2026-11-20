
include { QC_METRICS   }              from "../subworkflows/qc_metrics.nf"
include { CLASPAR      }              from "../modules/claspar.nf"
// include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX_ANALYSES {

    take:
        sample_ch

    main:
        // Run analyses
        // Run on All samples subworkflow
        QC_METRICS(sample_ch)
        // CLASPAR(sample_ch)
        // UNCLASSIFIED_QC_ANALYSIS(sample_ch, server)


    emit:
        qc_climb_id                 = QC_METRICS.out.qc_climb_id
        qc_metrics_analysis_json    = QC_METRICS.out.analysis_json
        qc_metrics_upload_files     = QC_METRICS.out.upload_files
        // claspar_kraken       = CLASPAR.out.analysis_json_kraken
        // claspar_viralign     = CLASPAR.out.analysis_json_viralign
        // claspar_sylph        = CLASPAR.out.analysis_json_sylph
    //     unclassified = UNCLASSIFIED_QC_ANALYSIS.out.uploads


}
