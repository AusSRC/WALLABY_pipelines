---
sidebar_position: 2
---

# Getting started

## Executing the workflow

**NOTE**: We currently only support the execution of this WALLABY workflow on AusSRC resources.

### Tower

This is the preferred method for executing the pipeline as it presents a web page for entering the required parameters, and provides a well-designed space to view the progress of your runs.

In order to access [Nextflow Tower](https://tower.nf/) you will need to sign up and be invited to join the WALLABY workspace.

**NOTE**: This Nextflow Tower interface is a temporary solution provided prior to the development of RADEC.

### Slurm head node

For those with access to the AusSRC Slurm cluster you are able to execute this pipeline directly. We do not recommend this method as it requires the user to generate the configuration file manually. 

The command for executing the workflow is the following

```
nextflow run https://github.com/AusSRC/WALLABY_workflows -params-file <PARAMETER_FILE>
```

#### Parameter file

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

More information about the parameters can be found on the [Configuration](/docs/configuration/end-to-end) page.
