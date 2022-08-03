
<h1 align="center">WALLABY pipelines</h1>

A collection of data post-processing pipelines for the [WALLABY Survey](https://www.atnf.csiro.au/research/WALLABY/) developed by the [AusSRC](https://aussrc.org).

## Pipelines

We have three pipelines for WALLABY postprocessing

- `main.nf`
- `source_finding.nf`
- `quality_check.nf`

To run the pipelines either clone the repository locally and run

```
nextflow run main.nf -params-file params.yaml -profile <PROFILE>
```

or

```
nextflow run https://github.com/AusSRC/WALLABY_pipelines -main-script main.nf -params-file params.yaml -profile <PROFILE>
```

replacing `main.nf` with the workflow of your choice and pointing to your parameter file `params.yaml`.

### Configuration

The `nextflow.config` provides defaults values for most required configuration parameters to run the pipelines. However for each pipeline users will need to provide some minimum configuration. If you look at the `nextflow.config` file you will notice there are two pre-defined environments in which these pipelines can run: `carnaby` which is the AusSRC development slurm cluster, or `magnus` which is supported by Pawsey. You will have to specify which environment to run the pipeline in with

### Main

The [`main.nf`](main.nf) pipeline performs mosaicking and source finding on observation footprints or tiles.

### Source finding

The [`source_finding.nf`](source_finding.nf) pipeline will run the source finding module from the main pipeline on a tile. This pipeline is used to perform post-processing on a different region of a mosaicked image cube that is already available on the cluster.

### Quality check

The [`quality_check.nf`](quality_check.nf) pipeline will download observations from CASDA, run the source finding application and produce a moment 0 map of the sources. The moment 0 map is then inspected by a WALLABY scientist to verify there are no artefacts in the image. Once an observation passes the quality check it can be processed with the main pipeline (assuming the overlapping footprint is available).

## Configuration

There is some configuration required running the pipelines. These include

| Parameter | Description |
| -- | -- |
| `RUN_NAME` | Name of the pipeline run. Will determine output subdirectories for pipeline products and temporary files. |
| `SBID` | SBID for the observation on which quality checking will be performed. Required parameter for `quality_check.nf`. |
| `IMAGE_CUBE` | Mosaicked image cube on which to run source finding pipeline. Required parameter for `source_finding.nf`. |
| `FOOTPRINTS` | Space separated list of image cube files to run the postprocessing pipeline on. Required parameter for the `main.nf`. Can be used for performing post-processing on multiple tiles instead of footprints. |
| `WEIGHTS` | Space separated list of weights cube files to run the postprocessing pipeline on. Position of each weights cube file in space separated list should match the image cube. Required parameter for the `main.nf`.|
| `REGION` | RA/Dec boundary of the image cube on which to run the source finding. If not provided the entire image cube will be processed. Optional parameter for all pipelines. |

## Tests

In the `tests/` subdirectory we have parameter files for pre-defined end-to-end tests that will run on the AusSRC Carnaby cluster. Note that these will not run in any other environment because there are configuration files at specific locations defined in the `nextflow.config` that will be required. A description of the tests are available below.

| Parameter file | Test description |
| -- | -- |
| `postprocessing.yaml` | Run mosaicking and source finding on a pair of Milkyway footprints. |
| `source_finding.yaml` | Run source finding on Milkyway image cube mosaic. |
| `quality_check.yaml` | Download from CASDA observation (footprint and weights) for SBID 40905. Run the source finding module on to generate cubelet moment 0 maps and mosaic these together. |

## Resources

- [CASDA data access portal](https://data.csiro.au/collections/domain/casdaObservation/search/)
- [Nextflow pipeline sharing](https://www.nextflow.io/docs/latest/sharing.html) (how to run)