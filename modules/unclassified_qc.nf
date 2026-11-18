process FASTQ_READ_STATS {
    /*
        Runs fastq_read_stats.py on the input climb_id. This process takes the unclassified read fraction and calculates standard
        read metrics such as phred score and gc content for each read, which are stored as an output table.

        Inputs:
            - climb_id: Climb ID for a given sample
            - fastq_files: unclassified read QC fastq files
            - output_dir: Directory to write results to

        Outputs:
            - exit_code: Exit status for the program.
            - result_file: Path to the output statistics table.
            - readQC_complete.txt: Path to the file reporting process success.
    */
    label "process_low"
    tag "${ch_meta.climb_id}"

    // change to the gpha-mscape-fastq-read-stats container
    container "ghcr.io/ukhsa-collaboration/gpha-mscape-fastq-read-stats:1.0.0"
    publishDir "${params.outdir}/${ch_meta.climb_id}", mode: 'copy'

    input:
    tuple val(ch_meta), path(reads)

    output:
    tuple val(ch_meta), path("readQC_complete.txt"), path("*.stats"), emit: readQC

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
            - climb_id: Climb ID for a given sample
            - readQC_status: Path to the file reporting process success
            - csv: Path to the output statistics table.

        Outputs:
            - json_output: Analysis json table for upload into onyx.
            - log: Log file.
            - csv: Path to the output statistics table.
    */

    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-fastq-read-stats:1.0.0'
    label "process_low"
    tag "${ch_meta.climb_id}"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(ch_meta), val(qc_text), path(stats_list)
    val server

    output:
    path("${ch_meta.climb_id}.unclassified_readQC.analysis_fields.json"), emit: stats_summary
    tuple path("${ch_meta.climb_id}.unclassified.readQC.analysis_fields.log.txt"), path(stats_list), emit: upload_files
    script:
    """
        create_onyx_json.py \\
        --store-onyx \\
        -i ${ch_meta.climb_id} \\
        -s ${server} \\
        -o . \\
        -p "${workflow.manifest.name}, ${workflow.manifest.version}, ${workflow.manifest.homePage}" \\
        -f ${stats_list} \\
        -r ${qc_text}
    """

    stub:
    """
    echo '{}' > ${ch_meta.climb_id}.unclassified_readQC.analysis_fields.json
    touch ${ch_meta.climb_id}.unclassified.readQC.analysis_fields.log.txt
    """
}
