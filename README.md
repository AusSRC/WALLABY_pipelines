<h1 align="center"><a href="https://aussrc.github.io/WALLABY_workflows/">WALLABY workflows</a></h1>

[![Docs](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/documentation.yml/badge.svg)](https://github.com/AusSRC/WALLABY_workflows/actions/workflows/documentation.yml)

WALLABY survey data post-processing pipelines by the [AusSRC](https://aussrc.org). 

## Overview

The WALLABY survey science data post-processing generates advanced data products, that are used by scientists for their research. We have composed some of these data post-processing tasks into [Nextflow](https://www.nextflow.io/) pipelines for convenient execution, thereby abstracting the low-level computing details of these activities from the science users.

Currently we provide support for two modules for the pipeline, which each produce an important advanced data product. These components are the following: 

*  mosaicking of image footprints (taken directly from ASKAP), 
*  source finding to generate the detections for the WALLABY catalogue. 

The WALLABY workflow is composed of two separate Nextflow modules for the two key functional components of the workflow. The end-to-end workflow takes raw footprints from [CASDA's Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/), performs linear mosaicking with [linmos](https://www.atnf.csiro.au/computing/software/askapsoft/sdp/docs/current/calim/linmos.html) to generate a WALLABY image cube. We then run source finding with [SoFiA-2](https://github.com/SoFiA-Admin/SoFiA-2) and write the output to a PostgreSQL database with [SoFiAX](https://github.com/AusSRC/SoFiAX). We provide the capability to run the two modules independently or together on a variety of computing resources.

## Quick Start

**AusSRC science users, [Nextflow Tower](https://tower.nf) provides a visual interface and preferred method for submitting this workflow.**

The pipeline can be run from a Slurm cluster head node. This is provided by AusSRC for the WALLABY science community, but it can be run on public cloud providers or other on-premise clusters. To submit the `nextflow` jobs to the cluster run the following command 

```
nextflow run https://github.com/AusSRC/WALLABY_workflows -params-file <PARAMETER_FILE>
```

A parameter file is required for the direct execution of the workflow via the Slurm head node. It is the mechanism by which the user can pass run-specific configuration information to Nextflow. This parameter file is accepted with the flag `-params-file` as shown above.

The parameter file needs to be either `json` or `yaml` format. Below is a template that the user should feel free to copy.

```
{
  "SBIDS" : <SBIDS>,
  "WORKDIR" : <WORK_DIRECTORY>,
  "CASDA_USERNAME" : <YOUR_CASDA_USERNAME>,
  "CASDA_PASSWORD" : <YOUR_CASDA_PASSWORD>,
  "DATABASE_HOST" : <YOUR_DATABASE_HOST>,
  "DATABASE_NAME" : <YOUR_DATABASE_NAME>,
  "DATABASE_USER" : <YOUR_DATABASE_USER>,
  "DATABASE_PASS" : <YOUR_DATABASE_PASS>
  
}
```

More information can be found in the documentation.

## Documentation

* [Documentation home](https://aussrc.github.io/WALLABY_workflows/)
* [Modules](https://aussrc.github.io/WALLABY_workflows/docs/overview#modules)
* [Getting started](https://aussrc.github.io/WALLABY_workflows/docs/getting_started)
* [Configuration reference](https://aussrc.github.io/WALLABY_workflows/docs/configuration/end-to-end)