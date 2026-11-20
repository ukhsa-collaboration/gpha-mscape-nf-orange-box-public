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

        Outputs (one channel per ClasPar analysis, each keyed by meta):
            - viralign: tuple(meta, analysis_json, csv)
            - kraken:   tuple(meta, analysis_json, genera_csv, species_csv)
            - sylph:    tuple(meta, analysis_json, csv)
    */
    container 'ghcr.io/ukhsa-collaboration/gpha-mscape-orangebox-claspar:latest'
    label "process_low"
    tag "${meta.climb_id}"
    publishDir "${params.outdir}/claspar", mode: "copy"

    input:
    val meta

    output:
    tuple val(meta), path("${meta.climb_id}.claspar-viralaligner.analysis_fields.json"), path("${meta.climb_id}_viral_aligner_processed.csv"), emit: viralign
    tuple val(meta), path("${meta.climb_id}.claspar-krakenbacteria.analysis_fields.json"), path("${meta.climb_id}_kraken_processed_genera.csv"), path("${meta.climb_id}_kraken_processed_species.csv"), emit: kraken
    tuple val(meta), path("${meta.climb_id}.claspar-sylph.analysis_fields.json"), path("${meta.climb_id}_sylph_processed.csv"), emit: sylph

    script:
    """
    claspar -i $meta.climb_id -o . -s $params.server -p $params.profiles_json -d $params.taxaplease_db
    """

    stub:
    """
    for f in claspar-viralaligner claspar-krakenbacteria claspar-sylph; do echo '{}' > ${meta.climb_id}.\$f.analysis_fields.json; done
    touch ${meta.climb_id}_viral_aligner_processed.csv ${meta.climb_id}_kraken_processed_genera.csv ${meta.climb_id}_kraken_processed_species.csv ${meta.climb_id}_sylph_processed.csv
    """
}
