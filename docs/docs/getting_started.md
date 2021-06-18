---
sidebar_position: 2
---

# Getting started

## Executing the workflow

Do this

```
nextflow run https://github.com/AusSRC/WALLABY_workflows -params-file <PARAMETER_FILE>
```

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
