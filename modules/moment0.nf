#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Create scripts for running SoFiA via SoFiAX
process mosaic {
    container = params.WALLMERGE_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val output_directory

    output:
        val "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.WALLMERGE_OUTPUT}", emit: mom0

    script:
        """
        #!/bin/bash
        python3 -u /app/run_wallmerge.py \
            $output_directory \
            ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.WALLMERGE_OUTPUT}
        """
}

process compress {
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val mom0

    script:
        """
        #!/bin/bash

        gzip $mom0
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow moment0 {
    take:
        output_directory

    main:
        mosaic(output_directory)
        compress(mosaic.out.mom0)
}

// ----------------------------------------------------------------------------------------
