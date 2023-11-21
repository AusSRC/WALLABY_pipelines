# WALLABY pipelines

Data post-processing pipelines for the [WALLABY Survey](https://www.atnf.csiro.au/research/WALLABY/) developed by the [AusSRC](https://aussrc.org).

# Pipelines

* Quality Check Pipeline
* Main Survey Pipeline

## Quality Check

Runs SoFiA-2 on a single ASKAP footprint and displays the results in the WALLABY portal.

### Run

Create batch script: `run.sh`

```
#!/bin/bash --login

#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --account=ja3
#SBATCH --mem-per-cpu=64G
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1

module load singularity/3.11.4-slurm
module load nextflow/23.04.3

srun nextflow run https://github.com/AusSRC/WALLABY_pipelines -r main -main-script quality_check.nf -profile setonix --SBID="12345" --RUN_NAME="SB12345_qc"
```

```
sbatch run.sh
```

* SBID: ASKAP SBID
* RUN_NAME: WALLABY run name


## Main Survey

Mosaics multiple footprints into overlapping source extraction regions. It then runs SoFiA-2 and displays the results in the WALLABY portal

## Run

Create batch script: `run.sh`

```
#!/bin/bash --login

#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --account=ja3
#SBATCH --mem-per-cpu=64G
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1

module load singularity/3.11.4-slurm
module load nextflow/23.04.3

srun nextflow run https://github.com/AusSRC/WALLABY_pipelines -r main -main-script main.nf -profile setonix --SER="SER_123-123"
```

```
sbatch run.sh
```

* SER: Name of the Source Extraction Region found in the WALLABY portal. 


## Reference

* [CASDA data access portal](https://data.csiro.au/collections/domain/casdaObservation/search/)
* [SoFiA-2 repository](https://github.com/SoFiA-Admin/SoFiA-2)
