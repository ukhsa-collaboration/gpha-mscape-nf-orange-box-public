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
}


process KSQUARED {
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper:latest'
    label 'process_low'
    tag "${meta.climb_id}"
    publishDir "${params.outdir}/ksquared_${scan_name}/", mode: 'copy'
    
    input:
        val sample_id
        path fastq
        path kraken_report
        path kraken_results
        val microbe
        val tp_database
        val ncbi_database
        val out_dir

    output:
        // file "data.json"
        path "${climbid}_taxacounts.txt", emit: taxacounts
        path "${climbid}_taxa.txt"
        path "${climbid}_lineages.txt", emit: lineages
        path "${climbid}_viral_reclassifier.kraken.json", emit: json

    script:
    """
    classify run-reclassification \
    --sample-id ${sample_id} \
    --fastq ${fastq} \
    --kraken_report ${kraken_report} \
    --kraken_results ${kraken_results} \
    --microbbe ${microbe} \
    --tp_database ${tp_database} \
    --ncbi_database ${ncbi_database} \
    --out_dir ${out_dir} \
    --publish
    """
}