# WALLABY workflows

Collection of [Nextflow](https://www.nextflow.io/) workflow definitions for the WALLABY science teams.

## Source finding example

We have written a nextflow workflow for running a source finding pipeline. This will run the following:
 
1. `sofia`
2. `sofiax`
3. Custom duplicate identification algorithm

This example relies on having a subdirectory in the `launchDir` (see [documentation](https://www.nextflow.io/docs/latest/metadata.html) for description and other metadata) called `test_case`. This subdirectory contains:

* `config.ini`
* `sofia.par`
* `sofia_test_datacube.fits`
* `outputs/`

You will also need to define a file called `database.env` which contains details about the PostgreSQL database to connect with. You will need to populate it with the following:

```
DJANGO_ALLOW_ASYNC_UNSAFE=True
DJANGO_SETTINGS_MODULE=api.settings
DJANGO_DATABASE_NAME=<NAME>
DJANGO_DATABASE_USER=<USER>
DJANGO_DATABASE_PASSWORD=<PASSWORD
DJANGO_DATABASE_HOST=<HOST>
```

## Execute workflow

In either local or Slurm environment, to run the workflow execute the following command:

```
nextflow run source_finding.nf
```

## Run locally

Nextflow will by default set the `executor` in the `nextflow.config` to local. The `local` branch of this repository contains code for this. To execute the workflow, run the command from above in the `source_finding/` subdirectory.

## Run on Slurm

To enable this on the Nimbus cluster there are a few changes that are required:

* Update the `nextflow.config` file with executor details and to use singularity rather than docker.
* Update `containerOptions` for mounting in the `source_finding.nf` file.

The code for this can be found in the `main` branch.
