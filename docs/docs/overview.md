---
sidebar_position: 1
---

# Overview

The WALLABY survey science data post-processing generates advanced data products, that are used by scientists for their research. We have composed some of these data post-processing tasks into [Nextflow](https://www.nextflow.io/) pipelines for convenient execution, thereby abstracting the low-level computing details of these activities from the science users.

Currently we provide support for two modules for the pipeline, which each produce an important advanced data product. These components are the following: 

*  mosaicking of image footprints (taken directly from ASKAP), 
*  source finding to generate the detections for the WALLABY catalogue. 

The WALLABY workflow is composed of two separate Nextflow modules for the two key functional components of the workflow. The end-to-end workflow takes raw footprints from [CASDA's Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/), performs linear mosaicking with [linmos](https://www.atnf.csiro.au/computing/software/askapsoft/sdp/docs/current/calim/linmos.html) to generate a WALLABY image cube. We then run source finding with [SoFiA-2](https://github.com/SoFiA-Admin/SoFiA-2) and write the output to a PostgreSQL database with [SoFiAX](https://github.com/AusSRC/SoFiAX). We provide the capability to run the two modules independently or together on a variety of computing resources.

## Modules

### Mosaicking

The mosaicking module downloads raw image footprints from CASDA's [Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/) for SBIDs of the user's choosing, and runs the `linmos` application to generate the mosaicked image cube advanced data product.

The individual processes of the workflow are executed sequentially, as they are dependent on the output of the previous process. The steps of the module are:

##### 1. Download

Download data cube and weights from CASDA's [Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/). Uses the `casda_download.py` script in the [WALLABY components](https://github.com/AusSRC/WALLABY_components) repository to query and download. This step requires users to have an [OPAL](https://opal.atnf.csiro.au/) account for programmatic access to the service. 

This step performs a download of the image cube and weights, both of which are required for the linear mosaicking application.

##### 2. Checksum

This step will verify that the image cubes and weights downloaded from CASDA are free from error. We calculate the checksum of the downloaded file with that expected.

##### 3. Generate config

Create the `linmos` configuration file from the [template](https://github.com/AusSRC/WALLABY_components/blob/main/generate_linmos_config.py). It will replace the input image cube and weights with those downloaded as part of the workflow. The user specifies the filename and location of the temporary configuration file and `linmos` mosaicked image cube output.

##### 4. Run linmos

Run `linmos` on the image cubes downloaded with the configuration file generated in the previous step.

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