# WALLABY workflows

Collection of [Nextflow](https://www.nextflow.io/) workflow definitions for the WALLABY science teams.

### Source finding

A nextflow workflow for running a source finding pipeline. This will run the following:
 
1. `sofia`
2. `sofiax`

This example relies on having a subdirectory in the `launchDir` (see [documentation](https://www.nextflow.io/docs/latest/metadata.html) for description and other metadata) called `test_case`. This subdirectory contains:

* `config.ini`
* `sofia.par`
* `sofia_test_datacube.fits`
* `outputs/`

To run the source finding workflow:

```
cd source_finding && nextflow run source_finding.nf
```
