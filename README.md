<h1 align="center">WALLABY workflows</h1>

Collection of [Nextflow](https://www.nextflow.io/) workflows for the WALLABY science teams.

[![Tests](https://github.com/AusSRC/WALLABY_workflow/actions/workflows/tests.yaml/badge.svg)](https://github.com/AusSRC/WALLABY_workflow/actions/workflows/tests.yaml)
[![Linting](https://github.com/AusSRC/WALLABY_workflow/actions/workflows/lint.yaml/badge.svg)](https://github.com/AusSRC/WALLABY_workflow/actions/workflows/lint.yaml)

## Description

Here we describe the processing steps for the WALLABY workflow. They are:

#### 1. Download

Download data cube and weights from CASDA. Uses the [download.py](mosaicking/scripts/download.py) script to query and download. You can view the CASDA data manually through their [Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/)

#### 2. Checkum

Calculate the checksum for the image cube and weights. Compare with the checksum that is downloaded from the previous step.

#### 3. Create `linmos` config

Create the `linmos` configuration file from a template. It will replace the input image cube and weights with those downloaded as part of the workflow. The user specifies the filename and location of the temporary configuration file and `linmos` mosaicked image cube output.

#### 4. Run `linmos`

Run `linmos` on the image cubes downloaded with the configuration file generated.

#### 5. Create `sofia` config

TBA

#### 6. Run `sofia`

Run the source finding code on the mosaicked image cube with the configuration file generated from the previous step. 

#### 7. Run `sofiax`

Write detections from `sofia` into a database.

## Configuration

There are a number of parameters required to run the entire WALLABY workflow. Users can provide these through the `-params-file` option when launching a workflow. Users can use the content of the `workflow.params` file below

```
TBA
```

Users should read on to understand the additional configuration requirements.

#### Download

You need CASDA credentials in order to download files from their archive. These can be provided to the workflow as a `credentials.ini` file or as environment variables.

Should you choose to create a credentials file, the format should be as follows

```
[login]
username = austin.shen@csiro.au
password = <PASSWORD>
```

#### Linmos

To parallelise `linmos` across a number of worker nodes in the cluster you can specify the number of tasks and number of tasks per node as follows in the nextflow configuration:

```
clusterOptions = '--ntasks=324 --ntasks-per-node=18'
```

#### SoFiAX

You will also need to define a file called `database.env` which contains details about the PostgreSQL database to connect with. You will need to populate it with the following:

```
DJANGO_DATABASE_NAME=<NAME>
DJANGO_DATABASE_USER=<USER>
DJANGO_DATABASE_PASSWORD=<PASSWORD
DJANGO_DATABASE_HOST=<HOST>
```

## Run workflow

We have two subdirectories for logically separate parts of the workflow: `mosaicking` and `source_extraction`. These together compose the WALLABY workflow, but they can be run indepdendently where necessary.

You will need to specify whether to run locally or with the Slurm executor by explicitly stating the configuration file

```
nextflow run main.nf -c local.config
```

or

```
nextflow run main.nf -c slurm.config
```

## Tests

Unit tests for the WALLABY scripts can be found at [`mosaicking/scripts/tests.py`](mosaicking/scripts/tests.py). They can be run locally with the following commands

```
cd mosaicking/scripts/
./tests.py
```

You may need to create a virtual environment `venv` and install the [requirements.txt](mosiacking/requirements.txt) first.

**download.py**

* Assert `stdout` is the filename of the downloaded image cube only

**generate_config.py**

* Assert the configuration file is written
* Assert the content of the configuration file is as expected
* Assert the `stdout` is the configuration filename.

## Other

### Local/Slurm differences

There are a few differences between the Nextflow workflow definitions for a local executor compared to the Slurm executor in addition to the configuration. They are

* Update `containerOptions` for mounting in the `source_finding.nf` file. Local uses Docker's volume `-v` flag whereas Slurm uses `--bind` to mount volumes.
