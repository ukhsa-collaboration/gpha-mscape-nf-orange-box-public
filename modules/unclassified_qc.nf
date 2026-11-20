process FASTQ_READ_STATS {
    /*
        Runs fastq_read_stats.py on the input climb_id. This process takes the unclassified read fraction and calculates standard
        read metrics such as phred score and gc content for each read, which are stored as an output table.

        Inputs:
            - meta: samplesheet row for the sample (meta.climb_id is used for naming)
            - reads: unclassified read fastq file(s), one for single-end or two for paired-end
            - output_dir: Directory to write results to

        Outputs:
            - readQC: tuple(meta, readQC_complete.txt, *.stats)
                - readQC_complete.txt: "True" if every fastq_read_stats.py run succeeded, else "False"
                - *.stats: one statistics table per input fastq
    */
    label "process_low"
    tag "${meta.climb_id}"

    // change to the gpha-mscape-fastq-read-stats container
    container "ghcr.io/ukhsa-collaboration/gpha-mscape-fastq-read-stats:1.0.0"
    publishDir "${params.outdir}/${meta.climb_id}_unclassified_qc", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("readQC_complete.txt"), path("*.stats"), emit: readQC

    script:
    def read_list = reads instanceof List ? reads : [reads]

    def commands  = read_list.withIndex().collect { fq, i ->
        "fastq_read_stats.py \"${fq}\" > \"${fq}.stats\" 2> fastq_stdout_r${i + 1}.txt || status=1"
    }.join('\n    ')
    """
    status=0
    ${commands}

    if [ \$status -eq 0 ]; then
        echo "True" > readQC_complete.txt
    else
        echo "False" > readQC_complete.txt
    fi
    """

    stub:
    def read_list = reads instanceof List ? reads : [reads]
    def touches   = read_list.collect { fq -> "touch \"${fq}.stats\"" }.join('\n    ')
    """
    ${touches}
    echo "True" > readQC_complete.txt
    """
}

process CREATE_READQC_ONYX_JSON {
    /*
        Creates the analysis json file and calculates some summary statistics across the unclassified read fraction.

        Inputs:
            - meta: samplesheet row for the sample (meta.climb_id is used for naming)
            - qc_text: contents of readQC_complete.txt ("True" or "False")
            - stats_list: statistics table(s) from FASTQ_READ_STATS

        Outputs:
            - stats_summary: Analysis json for upload into Onyx.
            - results: tuple(meta, analysis json, log file, statistics table(s))
    */

    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-fastq-read-stats:latest'
    label "process_low"
    tag "${meta.climb_id}"
    publishDir "${params.outdir}/${meta.climb_id}_unclassified_qc", mode: 'copy'

    input:
    tuple val(meta), val(qc_text), path(stats_list)

    output:
    tuple val(meta), path("${meta.climb_id}.unclassified_readQC.analysis_fields.json"), path("${meta.climb_id}.unclassified.readQC.analysis_fields.log.txt"), path(stats_list), emit: results

    script:
    """
    create_onyx_json \\
        -i ${meta.climb_id} \\
        -s ${params.server} \\
        -o . \\
        -p "${workflow.manifest.name}, ${workflow.manifest.version}, ${workflow.manifest.homePage}" \\
        -f ${stats_list} \\
        -r ${qc_text}
    """

    stub:
    """
    echo '{}' > ${meta.climb_id}.unclassified_readQC.analysis_fields.json
    touch ${meta.climb_id}.unclassified.readQC.analysis_fields.log.txt
    """
}
