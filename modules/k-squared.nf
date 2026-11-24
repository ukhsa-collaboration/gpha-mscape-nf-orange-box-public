#!/usr/bin/env nextflow

process KRAKEN {
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
    """
    kraken2 --db ${kraken_db} ${fastq} --output ${fastq.baseName}_${climb_id}_${scan_name}_kraken_results.txt --report ${fastq.baseName}_${climb_id}_${scan_name}_kraken_report.txt
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