
include { QC_SAMPLE    }              from "../modules/qc_metrics.nf"
// include { CLASPAR      }              from "../modules/claspar.nf"
// include { UNCLASSIFIED_QC_ANALYSIS } from "../subworkflows/unclassified_qc.nf"


workflow ORANGE_BOX_ANALYSES {

    take:
    sample_ch
    server
    bucket
    profiles_json
    taxaplease

    main:
    // Run analyses
    // Run on All samples subworkflow
    QC_SAMPLE(sample_ch, server)
    // CLASPAR(sample_ch, server, profiles_json, taxaplease)
    // UNCLASSIFIED_QC_ANALYSIS(sample_ch, server)


    // emit:
    //     qc           = QC_SAMPLE.out.upload_id_file
    //     kraken       = CLASPAR.out.kraken
    //     viralign     = CLASPAR.out.viralign
    //     sylph        = CLASPAR.out.sylph
    //     unclassified = UNCLASSIFIED_QC_ANALYSIS.out.uploads


}
