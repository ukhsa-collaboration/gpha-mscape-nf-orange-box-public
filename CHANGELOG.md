# Changelog
## 2026-11-20 v.2.0.0 - Orange Box
Updated documentation
### Changes:
- Bumped version number
- Referenced DEV.md in README.md

### Added:
- DEV.md file to describe how to add new analyses into Orange Box.

## 2026-11-20 v.1.1.0 - Orange Box
Merging refactor/unclassified-qc with pre-production branch

### Changes:
- Converted to more nf native workflow (results combined)
- Removed server, bucket, output directory calls
- Changed input arg to samplesheet (not input)

### Added:
- Gatekeep before any onyx interactions

## 2026-11-18 v.1.0.5 - Orange Box
Merging refactor/unclassified-qc with pre-production branch

### Changes:
- Now handles all sample metadata as a channel
- Outdir is called directly as a param, not passed through workflows/processes

### Added:
- Unclassified-qc processes
- Profiles for resources
- Upload of unclassified-qc processes

---
---

## 2026-11-18 v.1.0.4 - Orange Box
Merging feat/samplesheet with pre-production branch

### Changes:
- Combined READMEs
- Renamed funnel to onyx_upload_processes

### Removed:
- PORTAL process as nf handles aggregation
- QC and CLASPAR subworkflows as they only call a single process
- Python scripts in bin (no longer used)
- Tests no longer used
- Removed docker file


v.1.0.0 - Orange Box
Functioning first release with Claspar and QC modules, and option to run locally without
pushing to Onyx.

### Changes:
- added devscape to the profiles
- bumped claspar and QC versions to allow devscape use - now set to latest.
- removed unecessary config lines.
- orange box version is added to json before pushing, and the json is written to a new file (only in production mode, not if --skip_onyx_upload used).
- updated to v0.6.7 of the onyx analysis helper in all onyx modules.
- tidied comments from testing and development
- changed param name from 'profile_tables' to 'profiles_json' in line with claspar updates.

### Added:
- pipeline_trace file to the nextflow.config.
- added (optional) subworkflow for onyx upload
- skip_onyx_upload param added

---
---

March 2026 - ClasPar
ClasPar the classifier parser and taxa profiler has been added to the orange box.
ClasPar itself is run once, but creates three analyses (Kraken, Sylph and Viraligner), each of which are handled separately.
