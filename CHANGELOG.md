# Changelog

## 2026-11-18 v.1.0.4 - Orange Box
Merging feat/samplesheet with pre-production branch

### Changes:
- Combined READMEs
-

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
