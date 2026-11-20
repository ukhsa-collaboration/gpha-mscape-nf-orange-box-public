
include { QC_METRICS   }              from "../modules/qc_metrics.nf"
include { CLASPAR      }              from "../modules/claspar.nf"
// include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX_ANALYSES {

    take:
    sample_ch

    main:
    // Run analyses
    // Run on All samples subworkflow
    QC_METRICS(sample_ch)
    CLASPAR(sample_ch)
    // UNCLASSIFIED_QC_ANALYSIS(sample_ch, server)


    emit:
        qc           = QC_METRICS.out.analysis_json
        kraken       = CLASPAR.out.analysis_json_kraken
        viralign     = CLASPAR.out.analysis_json_viralign
        sylph        = CLASPAR.out.analysis_json_sylph
    //     unclassified = UNCLASSIFIED_QC_ANALYSIS.out.uploads


}
