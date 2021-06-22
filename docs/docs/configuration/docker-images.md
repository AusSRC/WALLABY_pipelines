---
sidebar_position: 4
---

# Docker images

We use official [AusSRC](https://hub.docker.com/u/aussrc) docker images for executing the Nextflow pipelines. The default images can be updated if necessary. The Nextflow parameters for these images are given below.

| Parameter | Default Image | Description |
|---|---|---|
| `WALLABY_COMPONENTS_IMAGE_IMAGE` | `aussrc/WALLABY_COMPONENTS_IMAGE:latest` | Collection of Python scripts for WALLABY workflow components. This includes the generation of configuration files, downloading image cubes and checksum calculations. Repository found [here](https://github.com/AusSRC/WALLABY_components). |
| `S2P_IMAGE` | `aussrc/s2p_setup:latest` | Python script for the generation of `sofia.par` and `config.ini` required to run `sofia` and `sofiax`. Adapted from SoFiA-Admin repository found [here](https://github.com/SoFiA-Admin/s2p_setup) for Nextflow execution. |
| `SOFIA_IMAGE` | Docker image for `sofia` execution. | `astroaustin/sofiax:v0.0.5`* | 
| `SOFIAX_IMAGE` | Docker image for `sofiax` execution. | `aussrc/sofiax:latest` |

*Official image pending.