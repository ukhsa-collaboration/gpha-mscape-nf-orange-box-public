# gpha-mscape-nf-orange-box

# gpha-mscape-nf-orange-box
This repository contains the Orange Box, a single-sample processing pipeline designed
specifically for UKHSA's mSCAPE project.

## Use

To run the Orange Box you require:
- a samplesheet - this is a simple text file with _climb_id_ as a header and then the sample id underneath, with multiple IDs across multiple rows (do not make a list of IDs in one row)
- the location of taxaplease database and the profiles json.

### Just run the modules

If you wish to just run the modules and see their outputs, run:

```bash
nextflow run ukhsa-collaboration/gpha-mscape-nf-orange-box-public
    -profile climb,<SERVER> \
    --samplesheet <path/to/samplesheet.csv> \
    --taxaplease_db <path/to/db> \
    --profiles_json <path/to/profiles> \
    --onyx_upload false
```

This will create all of the outputs in `results` directort, or you can specify an output location with `--output_dir <path/to/output>` argument.

### Push to Onyx

If you wish to run the orange box in full production mode and push to the Onyx database, you will need to request the location of the following from the current lead of the mSCAPE workgroup:

- the server token - Change your token in your environment for the relevant token you have obtained from the lead of the mscape group in your environment variables then pass these into the Nextflow command.
- the name of the bucket


```bash
nextflow run /ukhsa-collaboration/gpha-mscape-nf-orange-box-public \
    -profile climb,<*SCAPE> \
    --outdir <outdir> \
    --samplesheet <samplesheet> \
    --taxaplease_db <path_to_database> \
    --profiles_json <path_to_profiles_json> \
    --onyx_upload true \
    --bucket <bucket> \
    -e.ONYX_TOKEN=$ONYX_TOKEN
```
