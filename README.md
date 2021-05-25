<h1 align="center">WALLABY workflows</h1>

Collection of [Nextflow](https://www.nextflow.io/) workflows and components for the WALLABY science project.

[![Tests](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/tests.yaml/badge.svg)](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/tests.yaml)
[![Linting](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/lint.yaml/badge.svg)](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/lint.yaml)

## Overview

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

### Source extraction

To run the source extraction workflow independently you need to provide the following arguments

* CUBE_FILE (full path to image cube)

```
nextflow run source_extraction/main.nf --CUBE_FILE /mnt/shared/home/ashen/tmp/mosaicked.fits
```

### Full pipeline

You can run the mosaicking and source extraction together

```
nextflow run main.nf --SBIDS '10809,10812' --WORKDIR /mnt/shared/home/ashen/tmp --CASDA_USERNAME <USERNAME> --CASDA_PASSWORD <PASSWORD>
```

### Pipeline sharing

You can run the full pipeline without cloning the repository locally by giving `nextflow` the repository location

```
nextflow run https://github.com/AusSRC/WALLABY_workflows.git -r main --SBIDS '10809,10812' --WORKDIR /mnt/shared/home/ashen/tmp --CASDA_USERNAME <USERNAME> --CASDA_PASSWORD <PASSWORD>
```

for more sharing options you can look at the [pipeline sharing](https://www.nextflow.io/blog/2014/share-nextflow-pipelines-with-github.html) documentation. 
