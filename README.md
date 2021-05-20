# WALLABY workflows

Collection of [Nextflow](https://www.nextflow.io/) workflow definitions for the WALLABY science teams.

## Workflow description

Here we describe the processing steps of the WALLABY workflow. Currently the steps are:
 
1. Download cubes from [CASDA](https://data.csiro.au/collections/domain/casdaObservation/search/).
2. Compose `linmos` config file
3. `linmos`
4. `sofia`
5. `sofiax`

### Parameters

The parameters required to run the WALLABY workflow include:

* Image cube SBIDs (required)
* Database credentials (required)
* SoFiA-2 parameter file (optional)

#### Database credentials

You will also need to define a file called `database.env` which contains details about the PostgreSQL database to connect with. You will need to populate it with the following:

```
DJANGO_ALLOW_ASYNC_UNSAFE=True
DJANGO_SETTINGS_MODULE=api.settings
DJANGO_DATABASE_NAME=<NAME>
DJANGO_DATABASE_USER=<USER>
DJANGO_DATABASE_PASSWORD=<PASSWORD
DJANGO_DATABASE_HOST=<HOST>
```

## Components

We have two subdirectories for logically separate parts of the workflow: `mosaicking` and `source_extraction`. 

### Mosaicking

Performs step 1-3 of the workflow.

### Source extraction

Performs step 4-5 of the workflow.

## Execute workflow

You will need to specify whether to run locally or with the Slurm executor by explicitly stating the configuration file

```
nextflow run main.nf -c local.config
```

or

```
nextflow run main.nf -c slurm.config
```

To parallelise `linmos` across a number of worker nodes in the cluster you can specify the number of tasks and number of tasks per node as follows in the nextflow configuration:

```
clusterOptions = '--ntasks=324 --ntasks-per-node=18'
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
