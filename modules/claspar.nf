#!/usr/bin/env nextflow

process CLASPAR {
    /*
	The process for running ClasPar.

        Inputs:
            - climb_id: Climb ID for a given sample
            - server: Where Onyx results should go i.e. synthscape or mscape.
            - outdir: (optional) Output dir - here given as . (work dir) and Nextflow will publish to params.outdir anyway.
            - profiles_json: path to json which contains the taxa to profile mappings.
            - taxaplease: path to taxaplease database. If not provided, a new database will be created for each sample.

        Outputs:
            - 3 upload_files_* channels: for viral aligner, kraken-bacteria (this is a tuple of two files) and sylph results files to be uploaded to S3.
            - 3 analysis_json_* channels for viral_aligner, kraken-bacteria and sylph analyses to be added to Onyx.
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-orangebox-claspar:latest'
    label "process_low"
    tag "${sample_ch.climb_id}"
    publishDir "${params.outdir}/claspar", mode: "copy"

    input:
    val sample_ch
    val server
    path profiles_json
    path taxaplease

    output:
    path "${sample_ch.climb_id}_viral_aligner_processed.csv", emit: upload_files_viralign
    tuple (path "${sample_ch.climb_id}_kraken_processed_genera.csv"), (path "${sample_ch.climb_id}_kraken_processed_species.csv"), emit: upload_files_kraken
    path "${sample_ch.climb_id}_sylph_processed.csv", emit: upload_files_sylph

    path "${sample_ch.climb_id}.claspar-viralaligner.analysis_fields.json", emit: analysis_json_viralign
    path "${sample_ch.climb_id}.claspar-krakenbacteria.analysis_fields.json", emit: analysis_json_kraken
    path "${sample_ch.climb_id}.claspar-sylph.analysis_fields.json", emit: analysis_json_sylph

    //path "${climb_id}_.*_claspar.log", emit: logs

    script:
    """
    claspar -i $sample_ch.climb_id -o . -s $server -p $profiles_json -d $taxaplease
    """
}
