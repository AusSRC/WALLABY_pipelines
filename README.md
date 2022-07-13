
<h1 align="center">WALLABY pipeline</h1>

WALLABY survey data post-processing pipeline by the [AusSRC](https://aussrc.org). 

## Overview

This pipeline performs data post-processing (mosaicking + source finding) to generate advanced data products for WALLABY.

## Getting started

```
nextflow run https://github.com/AusSRC/WALLABY_workflows -r main -profile carnaby -params-file params.yaml
```

where `params.yaml` is the parameter file that we provide. The contents of which is used to configure the pipeline. An example template:

```
{
  "RUN_NAME": "NGC5044_4",
  "FOOTPRINTS": "image.restored.i.NGC5044_1A.SB33879.cube.contsub.fits, image.restored.i.NGC5044_1B.SB34302.cube.contsub.fits",
  "WEIGHTS": "weights.i.NGC5044_1A.SB33879.cube.fits, weights.i.NGC5044_1B.SB34302.cube.fits",
}
```

More information can be found in the documentation.

## Useful Links

* [CASDA's Data Access Portal](https://data.csiro.au/collections/domain/casdaObservation/search/)
* [YANDASoft linmos](https://www.atnf.csiro.au/computing/software/askapsoft/sdp/docs/current/calim/linmos.html)