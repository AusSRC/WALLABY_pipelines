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

    output:
	val true, emit: ready

    script:
        """
        #!/bin/bash

        gzip $output_file
        """
}

process plot_frequency_distribution {
    container = params.DIAGNOSTIC_PLOT_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ready
        val output_file

    script:
        """
        #!/bin/bash

        python3 /app/plot_frequency_distribution.py \
            -r ${params.RUN_NAME} -e ${params.DATABASE_ENV} -o $output_file
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
        compress(mosaic.out.output_mom_file)
}

workflow diagnostic_plot {
    take:
        ready
        output_file

    main:
        plot_frequency_distribution(ready, output_file)
}

// ----------------------------------------------------------------------------------------
