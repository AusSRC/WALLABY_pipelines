# Configuration

In this section we describe how to configure the WALLABY workflow.

## Parameter file

**NOTE**: A parameter file is only required for users running the workflow directly on the Slurm head node.

Nextflow will accept a parameter file for the execution of a workflow. This parameter file is accepted with the flag `-params-file`. For example

```
nextflow run main.nf -params-file <PARAMETER_FILE>
```

The parameter file needs to be either `json` or `yaml` format. Below is that format with the required parameters

```
{
  "SBIDS" : <SBIDS>,
  "WORKDIR" : <WORK_DIRECTORY>,
  "CASDA_USERNAME" : <YOUR_CASDA_USERNAME>,
  "CASDA_PASSWORD" : <YOUR_CASDA_PASSWORD>
}
```

Note that the `SBIDS` parameter expects a string with commas to separate each SBID (e.g. `"10809,10812"`). 

## Parameters

We will use these flags to incidate which parameters are required for each of the different WALLABY workflows. 

Flags:

❗  : the parameter is required for running the entire workflow

🌌  : the parameter is required when running the mosaicking module only

✨  : the parameter is required when running the source finding module only

the parameter is otherwise optional.

### General

| Parameter Name  | Description | Default Value (if applicable) | Flags |
|---|---|---|---|
| `SBIDS` | The scheduling block IDs for the footprints of interest |  | ❗🌌  |
|	`WORKDIR` | Working directory in the AusSRC shared file system to store all temporary files. This should start with `/mnt/shared/home/` followed by your username. |  | ❗ |


### CASDA Download


| Parameter Name  | Description | Default Value | Flags |
|---|---|---|---|
| `CASDA_USERNAME` | Username for [OPAL](https://opal.atnf.csiro.au/) account that is required to programatically access the [CASDA Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/) |  | ❗ |
| `CASDA_PASSWORD` | Password for the [OPAL](https://opal.atnf.csiro.au/) account |  | ❗ |
| `CASDA_CUBE_TYPE` | | |
| `CASDA_CUBE_FILENAME` | | |
| `CASDA_WEIGHTS_TYPE` | | |
| `CASDA_WEIGHTS_FILENAME` | | |

### Linmos

| Parameter Name  | Description | Default Value | Flags |
|---|---|---|---|
| `LINMOS_OUTPUT_IMAGE_CUBE` | Name of the mosaicked output image cube | `mosaicked` |  |
| `LINMOS_CONFIG_FILENAME ` | Name of the temporary `linmos` configuration file | `linmos.config` |  |
| `LINMOS_CLUSTER_OPTIONS` | Cluster options for the execution of `linmos` | `--ntasks=324 --ntasks-per-node=18` |  |

### SoFiA

| Parameter Name  | Description | Default Value | Flags |
|---|---|---|---|
| `SOFIA_RUN_NAME` | Name for the SoFiA run which will be written into the database. |  |  |


### SoFiAX

| Parameter Name  | Description | Default Value | Flags |
|---|---|---|---|
| `DATABASE_HOST` | Host address for the PostgreSQL database |  | ❗ |
| `DATABASE_NAME` | Name of the PostgreSQL database |  | ❗ |
| `DATABASE_USERNAME` | Username for PostgreSQL database access |  | ❗✨ |
| `DATABASE_PASSWORD` | Password for PostgreSQL database access |  | ❗✨ |

