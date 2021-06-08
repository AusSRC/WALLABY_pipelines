<h1 align="center">WALLABY workflows</h1>

Collection of [Nextflow](https://www.nextflow.io/) workflows for the WALLABY science teams.

[![Tests](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/tests.yaml/badge.svg)](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/tests.yaml)
[![Linting](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/lint.yaml/badge.svg)](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/lint.yaml)

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

## Run workflow

The components of the workflow are created to be modular. You are able to run the `mosaicking` or `source-extraction` part of the workflows independently, or together. Here we describe the basics for deploying workflows. More configuration details can be found on the [documentation page](https://aussrc.github.io/WALLABY_workflows/).

### Mosaicking

The mosaicking workflow can be run with only the following parameter values

* SBIDS (comma separated string e.g. '10809,10812')
* WORKDIR (space to store downloaded and mosaicked data)
* CASDA_USERNAME (OPAL credentials)
* CASDA_PASSWORD (OPAL credentials)

You can run it as such

```
nextflow run mosaicking/main.nf --SBIDS '10809,10812' --WORKDIR /mnt/shared/home/ashen/tmp --CASDA_USERNAME <USERNAME> --CASDA_PASSWORD <PASSWORD>
```

### Source finding

To run the source finding workflow independently you need to provide the following arguments

* CUBE_FILE (full path to image cube)

```
nextflow run source_finding/main.nf --CUBE_FILE /mnt/shared/home/ashen/tmp/mosaicked.fits
```

### Full pipeline

You can run the mosaicking and source finding together.

## Tests

Unit tests for the WALLABY scripts can be found at [`mosaicking/scripts/tests.py`](mosaicking/scripts/tests.py). They can be run locally with the following commands

```
cd mosaicking/scripts/
./tests.py
```

You may need to create a virtual environment `venv` and install the [requirements.txt](mosiacking/requirements.txt) first. Run the following and you will be able to run the tests from the virtual environment created

```
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**download.py**

* Assert `stdout` is the filename of the downloaded image cube only
* Run download with all arguments (rather than relying on `argparse` default values)

**generate_linmos_config.py**

* Assert the configuration file is written
* Assert the content of the configuration file is as expected
* Assert the `stdout` is the configuration filename.
