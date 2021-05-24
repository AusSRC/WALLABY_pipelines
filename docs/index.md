# Configuration

There are a number of parameters required to run the entire WALLABY workflow. Users can provide these through the `-params-file` option when launching a workflow. Users can use the content of the `workflow.params` file below

```
TBA
```

Users should read on to understand the additional configuration requirements.

## Download

You need CASDA credentials in order to download files from their archive. These can be provided to the workflow as a `credentials.ini` file or as environment variables.

Should you choose to create a credentials file, the format should be as follows

```
[login]
username = austin.shen@csiro.au
password = <PASSWORD>
```

## Linmos

To parallelise `linmos` across a number of worker nodes in the cluster you can specify the number of tasks and number of tasks per node as follows in the nextflow configuration:

```
clusterOptions = '--ntasks=324 --ntasks-per-node=18'
```

## SoFiAX

You will also need to define a file called `database.env` which contains details about the PostgreSQL database to connect with. You will need to populate it with the following:

```
DJANGO_DATABASE_NAME=<NAME>
DJANGO_DATABASE_USER=<USER>
DJANGO_DATABASE_PASSWORD=<PASSWORD
DJANGO_DATABASE_HOST=<HOST>
```