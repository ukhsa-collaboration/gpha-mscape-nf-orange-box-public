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
    label "process_tiny"

    // change to the gpha-mscape-fastq-read-stats container
    container "ghcr.io/ukhsa-collaboration/gpha-mscape-fastq-read-stats:1.0.0"
    publishDir "${outdir}/${climb_id}", mode: 'copy'

    input:
    tuple val(climb_id), val(fastq_files)
    val outdir

    output:
    tuple val(climb_id), path("readQC_complete.txt"), path("*.stats"), emit: readQC

    script:
    def fastq1 = fastq_files[0]
    def fastq2 = fastq_files.size() > 1 ? fastq_files[1] : null

    """
    set +e

    if [ "${fastq2}" = "null" ] || [ -z "${fastq2}" ]; then
        fastq_read_stats.py "${fastq1}" > "${fastq1}.stats" 2> fastq_stdout_r1.txt
        status=\$?
    else
        fastq_read_stats.py "${fastq1}" > "${fastq1}.stats" 2> fastq_stdout_r1.txt
        fastq_read_stats.py "${fastq2}" > "${fastq2}.stats" 2> fastq_stdout_r2.txt
        status=\$?
    fi

    if [ \$status -eq 0 ]; then
        echo "True" > readQC_complete.txt
    else
        echo "False" > readQC_complete.txt
    fi
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
    cpus 2
    memory '2GB'
    tag "${climb_id}"
    publishDir "${outdir}", mode: 'copy'

    input:
    tuple val(climb_id), val(readQC_status), path(csv)
    val server
    val outdir

    output:
    path("${climb_id}.unclassified_readQC.analysis_fields.json"), emit: stats_summary
    tuple path("${climb_id}.unclassified.readQC.analysis_fields.log.txt"), path(csv),emit: upload_files

    script:
    """
    create_onyx_json.py \\
    --store-onyx \\
    -i ${climb_id} \\
    -s $server \\
    -o . \\
    -p "${workflow.manifest.name}, ${workflow.manifest.version}, ${workflow.manifest.homePage}" \\
    -f $csv \\
    -r $readQC_status \\
    """
}