
<h1 align="center">WALLABY pipelines</h1>

A collection of data post-processing pipelines for the [WALLABY Survey](https://www.atnf.csiro.au/research/WALLABY/) developed by the [AusSRC](https://aussrc.org). 

## Pipelines

### Main

The [`main.nf`](main.nf) pipeline performs mosaicking and source finding on observation footprints or tiles.

### Source finding

The [`source_finding.nf`](source_finding.nf) pipeline will run the source finding subset of the main pipeline on a tile.

### Quality check

The [`quality_check.nf`](quality_check.nf) pipeline will download observations from CASDA, run the source finding application and produce a moment 0 map of the sources. The moment 0 map is then inspected by a WALLABY scientist to verify there are no artefacts in the image. Once an observation passes the quality check it can be processed with the main pipeline (assuming the overlapping footprint is available).

## Tests

In the `tests/` subdirectory we have parameter files for pre-defined end-to-end tests that will run on the AusSRC Carnaby cluster. Note that these will not run in any other environment because there are configuration files at specific locations defined in the `nextflow.config` that will be required.

| Parameter file | Test description | 
| -- | -- | 
| `postprocessing.yaml` | Something | 
| `source_finding.yaml` | Something | 
| `quality_check.yaml` | Something | 

## Resources

- [CASDA data access portal](https://data.csiro.au/collections/domain/casdaObservation/search/)
- [Nextflow pipeline sharing](https://www.nextflow.io/docs/latest/sharing.html) (how to run)