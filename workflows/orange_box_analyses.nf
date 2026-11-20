
include { QC_METRICS   }              from "../modules/qc_metrics.nf"
// include { CLASPAR      }              from "../modules/claspar.nf"
// include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX_ANALYSES {

    take:
    sample_ch

    main:
    // Run analyses
    // Run on All samples subworkflow
    QC_METRICS(sample_ch)
    QC_METRICS.out.analysis_json.view()
    // CLASPAR(sample_ch, server, profiles_json, taxaplease)
    // UNCLASSIFIED_QC_ANALYSIS(sample_ch, server)


    emit:
        qc           = QC_METRICS.out.upload_id_file
    //     kraken       = CLASPAR.out.kraken
    //     viralign     = CLASPAR.out.viralign
    //     sylph        = CLASPAR.out.sylph
    //     unclassified = UNCLASSIFIED_QC_ANALYSIS.out.uploads


}
