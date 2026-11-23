#!/usr/bin/env nextflow

process KRAKEN {
    container 'quay.io/biocontainers/kraken2:2.17--pl5321h077b44d_0'
    label 'process_medium'
    publishDir "results", mode: 'copy'
    
    input:
        val climb_id
        val run_id 
        val fastq
        val scan_name
        val kraken_db

    output:
        path "${fastq.getBaseName(1)}_${climb_id}_${scan_name}_kraken_results.txt", emit: kresults
        path "${fastq.getBaseName(1)}_${climb_id}_${scan_name}_kraken_report.txt", emit: kreport

    script:
    """
    kraken2 --db ${kraken_db} ${fastq} --output ${fastq.baseName}_${climb_id}_${scan_name}_kraken_results.txt --report ${fastq.baseName}_${climb_id}_${scan_name}_kraken_report.txt
    """
}


process KSQUARED {
    container ''
    publishDir "results", mode: 'copy'
    
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