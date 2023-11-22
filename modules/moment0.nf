#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

process mosaic {
    container = params.WALLMERGE_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ready
        val output_directory
        val output_file

    output:
        val output_file, emit: output_mom_file

    script:
        """
        #!/bin/bash
        python3 -u /app/run_wallmerge.py \
            $output_directory \
            $output_file
        """
}

process compress {
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val output_file

    script:
        """
        #!/bin/bash

        gzip $output_file
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow moment0 {
    take:
        ready
        output_directory
        output_file

    main:
        mosaic(ready,
               output_directory,
               output_file)
}

// ----------------------------------------------------------------------------------------
