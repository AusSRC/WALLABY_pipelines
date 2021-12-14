<h1 align="center"><a href="https://aussrc.github.io/WALLABY_workflows/">WALLABY workflows</a></h1>

WALLABY survey data post-processing pipelines by the [AusSRC](https://aussrc.org). 

## Overview

The WALLABY survey science data post-processing generates advanced data products, that are used by scientists for their research. We have composed some of these data post-processing tasks into [Nextflow](https://www.nextflow.io/) pipelines for convenient execution, thereby abstracting the low-level computing details of these activities from the science users.

Currently we provide support for two modules for the pipeline, which each produce an important advanced data product. These components are the following: 

* download footprints and weights from CASDA
* mosaicking with `linmos`
* source finding to generate the detections for the WALLABY catalogue (using [SoFiA-2](https://github.com/SoFiA-Admin/SoFiA-2) and [SoFiAX](https://github.com/AusSRC/SoFiAX))

## Getting started

Pipelines are deployed from the head node of a Slurm cluster. The AusSRC cluster is available to the WALLABY community for deploying these jobs. To submit a job run the following:

```
nextflow run https://github.com/AusSRC/WALLABY_workflows -params-file params.yaml
```

where `params.yaml` is the parameter file that we provide. The contents of which is used to configure the pipeline. A template is provided for you below

```
{
  # Required 
  "SBIDS": "25750 25701",
  "WORKDIR": "/mnt/shared/home/ashen/runs/NGC5044_4",
  
  # Download credentials
  "CASDA_USERNAME": "",
  "CASDA_PASSWORD": "",

  # Source finding parameters
  "SOURCE_FINDING_RUN_NAME": "NGC5044_4",
  "SOFIA_PARAMETER_FILE": "/mnt/shared/home/ashen/runs/NGC5044_4/sofia.par",
  "S2P_TEMPLATE": "/mnt/shared/home/ashen/runs/NGC5044_4/s2p_setup.ini",

  # Database credentials
  "DATABASE_HOST": "",
  "DATABASE_NAME": "wallabydb",
  "DATABASE_USER": "admin",
  "DATABASE_PASS": "admin"
}
```

More information can be found in the documentation.

## Useful Links

* [Documentation home](https://aussrc.github.io/WALLABY_workflows/)
* [Modules](https://aussrc.github.io/WALLABY_workflows/docs/overview#modules)
* [Getting started](https://aussrc.github.io/WALLABY_workflows/docs/getting_started)
* [Configuration reference](https://aussrc.github.io/WALLABY_workflows/docs/configuration/end-to-end)
* [CASDA's Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/)
* [YANDASoft linmos](https://www.atnf.csiro.au/computing/software/askapsoft/sdp/docs/current/calim/linmos.html)