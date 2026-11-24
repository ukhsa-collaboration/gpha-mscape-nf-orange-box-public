#!/usr/bin/env nextflow

process KRAKEN {
    /*
        This process takes a sample fastq(s) and runs kraken against the
        reads using the specified reference database.

        Inputs:
            - meta: Sample metadata - climb id and bool of whether reads
              are single or paired end
            - reads: Path to read(s) - one path if single end, two paths
              if paired end
            - scan_name: Taxonomic group of interest
            - kraken_db: Path to kraken_db
        Outputs:
            - meta: Sample metadata
            - kraken_out: Kraken outfile
            - kraken_report: Kraken report file
    */
    container 'quay.io/biocontainers/kraken2:2.17--pl5321h077b44d_0'
    label 'process_medium'
    tag "${meta.climb_id}"
    publishDir "${params.outdir}/ksquared_${scan_name}/", mode: 'copy'

    input:
        tuple val(meta), path(reads)
        val scan_name
        val kraken_db

    output:
       tuple val(meta), path ("${meta.climb_id}_${scan_name}_kraken_out.txt"), path("${meta.climb_id}_${scan_name}_kraken_report.txt"), emit: kraken_files

    script:
    def input_cmd = meta.single_end ? "${reads}" : "--paired ${reads[0]} ${reads[1]}"
    """
    kraken2 \\
    --db ${kraken_db} \\
    --output ${meta.climb_id}_${scan_name}_kraken_out.txt \\
    --report ${meta.climb_id}_${scan_name}_kraken_report.txt \\
    ${input_cmd}
    """

    stub:
    def input_cmd = meta.single_end ? "${reads}" : "--paired ${reads[0]} ${reads[1]}"
    """
    echo ${input_cmd}
    touch ${meta.climb_id}_${scan_name}_kraken_out.txt
    touch ${meta.climb_id}_${scan_name}_kraken_report.txt
    """
}


process SUMMARISE_KRAKEN {
    /*
        This process takes the results of a kraken run and extracts the
        results for the taxa of interest and reformats them.

        Inputs:
            - meta: Sample metadata - climb id
            - kraken_out: Kraken outfile
            - kraken_report: Kraken report file
            - scan_name: Taxonomic group of interest
        Outputs:
            - meta: Sample metadata
            - *_taxa.txt:
            - *_taxacounts.txt:
            - *_lineages.txt:
            - *_reclassifier_json:
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label 'process_low'
    tag "${meta.climb_id}"
    publishDir "${params.outdir}/ksquared_${scan_name}/", mode: 'copy'

    input:
        tuple val(meta), path(kraken_report), path(kraken_out)
        val scan_name

    output:
        tuple val(meta), path("${meta.climb_id}_taxacounts.txt"), path("${meta.climb_id}_taxa.txt"), path("${meta.climb_id}_lineages.txt"), path("${meta.climb_id}_${scan_name}_reclassifier.kraken.json"), emit: results

    script:
    """
    classify run-reclassification \\
    --sample-id ${meta.climb_id} \\
    --fastq ${fastq} \\
    --kraken_report ${kraken_report} \\
    --kraken_results ${kraken_results} \\
    --microbe ${scan_name} \\
    --tp_database ${tp_database} \\
    --ncbi_database ${ncbi_database} \\
    --out_dir ${out_dir} \\
    --publish
    """

    stub:
    """
    echo '{}' > ${meta.climb_id}.ksquared.${scan_name}.analysis_fields.json
    touch ${meta.climb_id}_taxacounts.txt
    touch ${meta.climb_id}_taxa.txt
    touch ${meta.climb_id}_lineages.txt
    touch ${meta.climb_id}_${scan_name}_reclassifier.kraken.json
    """

}
