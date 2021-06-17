# Configuration

On this web page this document we discuss how to configure the W

## Parameter file

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

Flags:

:exclamation:		: the parameter is required for running the entire workflow

:milky_way: 		: the parameter is required when running the mosaicking module only

:sparkles: 		: the parameter is required when running the source finding module only

Otherwise optional.

### General

| Parameter Name  | Description | Default Value (if applicable) |
|---|---|---|---|
| `RUN_NAME` | Name for the Nextflow run which will be written into the database. |  |
| :exclamation:	:milky_way: `SBIDS` | The scheduling block IDs for the footprints of interest |  |
| :exclamation:	`WORKDIR` | Working directory in the AusSRC shared file system to store all temporary files. This should start with `/mnt/shared/home/` followed by your username. |  |


### CASDA

| Parameter Name  | Description | Default Value |
|---|---|---|---|
| :exclamation: `CASDA_USERNAME` | Username for [OPAL](https://opal.atnf.csiro.au/) account that is required to programatically access the [CASDA Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/) |  |
| :exclamation: `CASDA_PASSWORD` | Password for the [OPAL](https://opal.atnf.csiro.au/) account |  |


### Download

You need CASDA credentials in order to download files from their archive. These can be provided to the workflow as a `credentials.ini` file or as environment variables.

Should you choose to create a credentials file, the format should be as follows

```
[login]
username = austin.shen@csiro.au
password = <PASSWORD>
```

### Linmos

To parallelise `linmos` across a number of worker nodes in the cluster you can specify the number of tasks and number of tasks per node as follows in the nextflow configuration:

```
clusterOptions = '--ntasks=324 --ntasks-per-node=18'
```

### SoFiA


### SoFiAX

You will also need to define a file called `database.env` which contains details about the PostgreSQL database to connect with. You will need to populate it with the following:

```
DJANGO_DATABASE_NAME=<NAME>
DJANGO_DATABASE_USER=<USER>
DJANGO_DATABASE_PASSWORD=<PASSWORD
DJANGO_DATABASE_HOST=<HOST>
```