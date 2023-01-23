<h1 align="center">WALLABY pipelines</h1>

Data post-processing pipelines for the [WALLABY Survey](https://www.atnf.csiro.au/research/WALLABY/) developed by the [AusSRC](https://aussrc.org).

## Run

To run a pipeline you need to specify (1) which pipeline to run (`main.nf`, `source_finding.nf` or `quality_check.nf`) as well as the environment in which to run it (`setonix` or `carnaby). 

The command is as follows:

```
nextflow run <PIPELINE> -params-file <PARAMETER_FILE> -profile <ENVIRONMENT> -resume
```

or 

```
nextflow run https://github.com/AusSRC/WALLABY_pipelines -main-script <PIPELINE> -params-file <PARAMETER_FILE> -profile <ENVIRONMENT> -resume
```

More details on how to run Nextflow pipelines can be found on their [documentation page](https://www.nextflow.io/docs/latest/index.html). 

## Pipelines

There are three pipelines for WALLABY postprocessing

[`main.nf`](main.nf)

This is the main post-processing pipeline that is used for most of the WALLABY survey. It performs mosaicking and source finding for a number of observations. It can be used to mosaic and find sources in footprint pairs, or for joining together any number of tiles. 

A example parameter file for `main.nf`

```
{
  "RUN_NAME": "milkyway",
  "FOOTPRINTS": "image.restored.i.NGC5044_4A.SB25701.cube.MilkyWay.contsub.fits, image.restored.i.NGC5044_4B.SB25750.cube.MilkyWay.contsub.fits",
  "WEIGHTS": "weights.i.NGC5044_4A.SB25701.cube.MilkyWay.fits, weights.i.NGC5044_4B.SB25750.cube.MilkyWay.fits",
  "REGION": "200.77, 204.77, -24.605, -20.605",
}
```

[`source_finding.nf`](source_finding.nf)
  
The source finding pipeline only runs SoFiA and SoFiAX for extracting detections from an image and uploading the detection properties and products to a database.

A example parameter file for `source_finding.nf`

```
{
  "RUN_NAME": "198-19_198-13_r",
  "IMAGE_CUBE": "/mnt/shared/wallaby/post-runs/198-19_198-13/mosaic.fits",
  "WEIGHTS_CUBE": "/mnt/shared/wallaby/post-runs/198-19_198-13/weights.mosaic.fits",
  "REGION": "192.74, 196.74, -18.08, -14.08",
}
```

*NOTE: The `REGION` parameter is optional. Without this the entire field will be processed.

[`quality_check.nf`](quality_check.nf)

The quality check pipeline takes a single observation and produces a moment 0 map of the field. The user specifies the SBID and the pipeline will download the observation image cube and weights cube, then run the source finder to produce output products and generate the moment 0 map. This is then used for inspecting the quality of the observation and is used prior to the main postprocessing pipeline. For new observations, this pipeline will be run prior to both other post-processing pipelines so the downloading of files occurs as part of this workflow.
    
An example parameter file for `quality_check.nf`
  
```
{
  "SBID": "45652",
  "RUN_NAME": "SB45652_qc"
}
```

## Environments

Currently there are two environments in which these pipelines can be run

- `setonix` (Production)
- `carnaby` (AusSRC development cluster)

In the [`nextflow.config`](nextflow.config) there are default parameters that allow these pipelines to run in these environments.

## Configuration

The user-provided parameters used in the pipelines are described in the table below

| Parameter | Description |
| -- | -- |
| `RUN_NAME` | Name of the pipeline run. Will determine output subdirectories for pipeline products and temporary files |
| `SBID` | SBID for the observation on which quality checking will be performed |
| `IMAGE_CUBE` | Mosaicked image cube on which to run source finding pipeline |
| `WEIGHTS_CUBE` | Mosaicked weights cube on which to run source finding pipeline |
| `FOOTPRINTS` | Space separated list of image cube files to run the postprocessing pipeline on. Can be used for performing post-processing on multiple tiles instead of footprints. |
| `WEIGHTS` | Space separated list of weights cube files to run the postprocessing pipeline on. Position of each weights cube file in space separated list should match the image cube |
| `REGION` | RA/Dec boundary of the image cube on which to run the source finding. If not provided the entire image cube will be processed. Optional parameter for all pipelines. |

Defaults have been provided for the following parameters through the `nextflow.config`. Users are unlikely to need to change these values.

| Parameter | Description |
| -- | -- |
| `SOFIA_PARAMETER_FILE` | Location to template [`SoFiA-2`](https://github.com/SoFiA-Admin/SoFiA-2) parameter file for configuring the source finding run. |
| `S2P_TEMPLATE` | Template [`s2p_setup`](https://github.com/AusSRC/s2p_setup) configuration for setting up SoFiAX runs |
| `SOFIAX_CONFIG_FILE` | Template values for SoFiAX configuration (database credentials provided here) |
| `LINMOS_CONFIG_FILE` | Template mosaicking configuration for `linmos` |
| `MOSAIC_OUTPUT_FILENAME` | Output filename for mosaicked image cubes |
| `SOFIA_OUTPUTS_DIRNAME` | Name of the subdirectory where `SoFiA-2` will store subcube output products |
| `LINMOS_CONFIG_FILENAME` | Name of the `linmos` configuration generated for the pipeline run instance |
| `LINMOS_LOG_FILE` | Log file output default name |
| `SOFIAX_CONFIG_FILENAME` | Output filename for the SoFiAX config file for the pipeline run instance |
| `WALLMERGE_OUTPUT` | Output filename for the merged moment 0 map file produced by the quality check pipeline |

## Reference

- [CASDA data access portal](https://data.csiro.au/collections/domain/casdaObservation/search/)
- [Nextflow pipeline sharing](https://www.nextflow.io/docs/latest/sharing.html) (how to run)
- [SoFiA-2 repository](https://github.com/SoFiA-Admin/SoFiA-2)
