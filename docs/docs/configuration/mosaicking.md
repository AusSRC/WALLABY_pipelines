---
sidebar_position: 2
---

# Mosaicking

The mosaicking workflow will download footprints from CASDA, generate the linmos configuration and run linmos. The output file will be stored on the AusSRC shared file system.

The output filename is given by the `LINMOS_OUTPUT_IMAGE_CUBE` and the output path is given by the `WORKDIR`.

## Parameters

We use ❗ to indicate that a parameter is required and no default value is provided (the user will need to provide this on execution of the workflow). The parameter is otherwise optional.

### Environment

| Parameter Name  | Description | Default Value |
|---|---|---|---|
|	`WORKDIR`❗| Working directory in the AusSRC shared file system to store all temporary files. This should start with `/mnt/shared/home/` followed by your username, or in the WALLABY shared space `/mnt/shared/wallaby/` | `/mnt/shared/wallaby/nextflow_runs/` |


### CASDA Download


| Parameter Name  | Description | Default Value |
|---|---|---|---|
| `SBIDS`❗ | The scheduling block IDs for the footprints of interest |  |
| `CASDA_USERNAME`❗ | Username for [OPAL](https://opal.atnf.csiro.au/) account that is required to programatically access the [CASDA Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/) |  |
| `CASDA_PASSWORD`❗ | Password for the [OPAL](https://opal.atnf.csiro.au/) account |  |
| `CASDA_CUBE_TYPE` | Cube type in the CASDA Portal search query | `cube` |
| `CASDA_CUBE_FILENAME` | Cube filename in the search query. | `image.restored.%SB$SBID%.cube.MilkyWay.contsub.fits` |
| `CASDA_WEIGHTS_TYPE` | Cube weight type in the CASDA portal search query | `cube` |
| `CASDA_WEIGHTS_FILENAME` | Cube filename in the search query. | `weights%SB$SBID%.cube.MilkyWay.fits` |

**Query notes**:

* `%` is a wildcard
* `$SBID` will be replaced with the string values from `SBIDS`

### Linmos

| Parameter Name  | Description | Default Value | 
|---|---|---|---|
| `LINMOS_OUTPUT_IMAGE_CUBE` | Name of the mosaicked output image cube | `mosaicked` |  |
| `LINMOS_CONFIG_FILENAME ` | Name of the temporary `linmos` configuration file | `linmos.config` |  |
| `LINMOS_CLUSTER_OPTIONS` | Cluster options for the execution of `linmos` | `--ntasks=324 --ntasks-per-node=18` |  |
