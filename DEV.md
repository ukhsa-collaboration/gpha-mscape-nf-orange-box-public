# Development Guide

## Orange Box overview
The Orange Box workflow is structured using Nextflow modules and subworkflows.
- Analysis tools are implemented as individual subworkflows with appropriate modules.
- Results from analysis subworkflows are formatted into tuples and passed to the `onyx_upload` workflow.

## Adding Analyses
To add a new function to the Orange Box, create a new subworkflow within the `orange_box_analyses` workflow.

### Parameters
This subworkflow should take the samplesheet channel (`sample_ch`) which contains metadata provided by Cher ami. This can be used to access data such as sample ids, or read URI's.

There are currently multiple global params used in Orange Box, such as `outdir`. These can be found in the `params.config` file.

Once the tool has ran, and generated output files, use the [Onyx Helper](https://github.com/ukhsa-collaboration/gpha-mscape-onyx-analysis-helper) to generate an analysis metadata JSON file in the format: `${climb_id}.{module}.analysis_fields.json`

Log files and nextflow stubs are also encouraged.

### Outputs: Single Analysis Output File
Create a tuple of your results in the module outputs in the format `tuple val(meta), path(analysis_fields.json), path(output_file)`:
```
output:
tuple val(meta), path(${climb_id}.{module}.analysis_fields.json), path("${meta.climb_id}_output_file.csv"), emit: results
```
These are then emited from the subworkflow:
```
emit:
    results = ANALYSIS_MODULE.out.results
```
Then add the tuple to the `results` channel along with the analysis name using `map`:
```
results = channel.empty().mix(
    ANALYSIS_SUBWORKFLOW.out.results
            .map { meta, json, csv -> tuple(meta, 'ANALYSIS_NAME', json, csv) },
    ...
)
```

### Outputs: Multiple Output Files for the Same Analysis
First pass all files as a tuple from your module to the submodule:
```
tuple val(meta), path(${climb_id}.{module}.analysis_fields.json), path("${meta.climb_id}_output_file_1.csv"), path("${meta.climb_id}_output_file_2.csv"), emit: results
```
In the subworkflow combine the output files to a list:
```
results   = ANALYSIS_MODULE.out.results
            .map { meta, json, file_1, file_2 -> tuple(meta, json, [file_1, file_2]) }
```
Then add the tuple to the `results` channel along with the analysis name using `map`, instead of using a variable describing the output file type (i.e. csv) use the term `files`:
```
results = channel.empty().mix(
    ANALYSIS_SUBWORKFLOW.out.results
            .map { meta, json, files -> tuple(meta, 'ANALYSIS_NAME', json, files) },
    ...
)
```
### Outputs: Multiple Analyses from the Same Subworkflow
In the analysis module, use unique `emit` names for each output, but each should still be a tuple following the format:
```
output:
tuple val(meta), path("${meta.climb_id}.UNIQUE_ANALYSIS_NAME.analysis_fields.json"), path("${meta.climb_id}_unique_analysis_name_1.csv"), emit: unique_analysis_name_1
tuple val(meta), path("${meta.climb_id}.UNIQUE_ANALYSIS_NAME.analysis_fields.json"), path("${meta.climb_id}_unique_analysis_name_2_file_1.csv"), path("${meta.climb_id}_unique_analysis_name_2_file_2.csv"), emit: unique_analysis_name_2
tuple val(meta), path("${meta.climb_id}.UNIQUE_ANALYSIS_NAME.analysis_fields.json"), path("${meta.climb_id}_unique_analysis_name_3.csv"), emit: unique_analysis_name_3
```
In the subworkflow each emitted output tuple should be emited with a unique name again:
```
emit:
    // Each emit is tuple(meta, analysis_json, upload_files)
    unique_analysis_name_1 = ANALYSIS_MODULE.out.unique_analysis_name_1
    unique_analysis_name_2   = ANALYSIS_MODULE.out.unique_analysis_name_2
        .map { meta, json, genera, species -> tuple(meta, json, [file_1, file_2]) }
    unique_analysis_name_3    = ANALYSIS_MODULE.out.unique_analysis_name_3
```
These can the each be added to the `results` channel in the `orange_box_analyses` workflow. Each should be supplied with a unique analysis name in the `map` function.:
```
        results = channel.empty().mix(
            ANALYSIS_SUBWORKFLOW.out.unique_analysis_name_1
                .map { meta, json, csv -> tuple(meta, 'UNIQUE_ANLAYSIS_NAME', json, csv) },
            ANALYSIS_SUBWORKFLOW.out.unique_analysis_name_2
                .map { meta, json, files -> tuple(meta, 'UNIQUE_ANLAYSIS_NAME', json, files) },
            ANALYSIS_SUBWORKFLOW.out.unique_analysis_name_3
                .map { meta, json, csv -> tuple(meta, 'UNIQUE_ANLAYSIS_NAME', json, csv) },
        )
```

## Upload
All uploads are performed only when all analyses in the `orange_box_analyses` workflow are complete.

If you are testing your analyses, you can pass the parameter `--onyx_upload False`. This will prevent the pipeline attempting an upload to Onyx on completion of the the `orange_box_analyses` workflow.
