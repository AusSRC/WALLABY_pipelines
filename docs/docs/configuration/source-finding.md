---
sidebar_position: 3
---

# Source finding

The source finding workflow will allow users to execute SoFiA and SoFiAX on a mosaicked image cube that exists in the AusSRC shared file system.

## Parameters

We use ❗ to indicate that a parameter is required and no default value is provided (the user will need to provide this on execution of the workflow). The parameter is otherwise optional.

### Environment 

| Parameter Name  | Description | Default Value |
|---|---|---|
|	`IMAGE_CUBE`❗ | Path to the mosaicked image cube for SoFiA |  |
|	`WORKDIR`❗| Working directory in the AusSRC shared file system to store all temporary files. This should start with `/mnt/shared/home/` followed by your username, or in the WALLABY shared space `/mnt/shared/wallaby/` | `/mnt/shared/wallaby/nextflow_runs/` |

### SoFiA

| Parameter Name  | Description | Default Value | 
|---|---|---|
| `SOFIA_RUN_NAME` | Name for the SoFiA run which will be written into the database. |  | `sofia` |


### SoFiAX

| Parameter Name  | Description | Default Value | 
|---|---|---|
| `DATABASE_HOST`❗ | Host address for the PostgreSQL database |  |
| `DATABASE_NAME`❗ | Name of the PostgreSQL database |  |
| `DATABASE_USER`❗ | Username for PostgreSQL database access |  |
| `DATABASE_PASS`❗ | Password for PostgreSQL database access |  |
