# gpha-mscape-nf-orange-box

For running Orange Box manually:
```bash
nextflow run /ukhsa-collaboration/gpha-mscape-nf-orange-box-public \
    -profile climb,<*SCAPE> \
    --samplesheet <samplesheet> \
    --taxaplease_db <taxaplease_db> \
    --profiles_json <profiles_json> \
    --outdir <outdir> \
```
