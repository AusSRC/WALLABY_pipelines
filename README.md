<h1 align="center">WALLABY workflows</h1>

[![Docs](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/documentation.yml/badge.svg)](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/documentation.yml)

[Nextflow](https://www.nextflow.io/) workflow for the WALLABY science project data post-processing.

The WALLABY workflow is composed of two separate Nextflow modules for the two key functional components of the workflow. The end-to-end workflow takes raw footprints from [CASDA's Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/), performs linear mosaicking with [linmos](https://www.atnf.csiro.au/computing/software/askapsoft/sdp/docs/current/calim/linmos.html) to generate a WALLABY image cube. We then run source finding with [SoFiA-2](https://github.com/SoFiA-Admin/SoFiA-2) and write the output to a PostgreSQL database with [SoFiAX](https://github.com/AusSRC/SoFiAX).

## Modules

### Mosaicking

The mosaicking workflow module downloads the image cubes for specified SBIDs 

Steps:

##### 1. Download

Download data cube and weights from CASDA. Uses the [casda_download.py](mosaicking/scripts/casda_download.py) script to query and download. You can view the CASDA data manually through their [Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/)

##### 2. Checksum

Calculate the checksum for the image cube and weights. Compare with the checksum that is downloaded from the previous step.

##### 3. Generate config

Create the `linmos` configuration file from a template. It will replace the input image cube and weights with those downloaded as part of the workflow. The user specifies the filename and location of the temporary configuration file and `linmos` mosaicked image cube output.

##### 4. Run linmos
Run `linmos` on the image cubes downloaded with the configuration file generated.

### Source finding

##### 1. Generate sofia parameters

Generate the default `sofia.par` file based on user-provided configuration details. This step is just used to parameterise the `sofia` run.

##### 2. s2p

Based on scripts written by the SoFiA Admin to generate the `sofia` and `sofiax` parameter/configuration files for a given data cube ([repository](https://github.com/SoFiA-Admin/s2p_setup)).

Will generate all of the `sofia.par` files and the `config.ini` for the execution of both `sofia` and `sofiax`. Will take a selected WALLABY data cube and automatically decide on the best sub-cube splitting arrangement for running on the AusSRC Slurm cluster.

##### 3. Database credentials

Update the `config.ini` file with database credentials. This is required by `sofiax` to write `sofia` outputs.

##### 4. Run `sofia`

Run `sofia` on the entire data cube. 

##### 5. Run `sofiax`

Write detections from `sofia` into a database by running `sofiax`. SoFiAX will be run without executing `sofia`.

## Configuration

See [documentation](https://aussrc.github.io/WALLABY_workflows/) for configuration of the WALLABY workflow.

## Execution

We suggest using the AusSRC RADEC platform for executing this workflow as it provides all configuration requirements in a simple web form. 

The workflow is intended to be executed on a Slurm cluster via `ssh` access to the head node, or with a job submitted to the cluster through RADEC. 

### End-to-end

```
nextflow run https://github.com/AusSRC/WALLABY_workflows -params-file <PARAMETER_FILE>
```

### Mosaicking

TBA

### Source finding

TBA

