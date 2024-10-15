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
        val ready
        val output_file

    output:
	    val true, emit: ready

    script:
        """
        #!/bin/bash

        gzip -f $output_file
        """
}

process plot_frequency_distribution {
    container = params.PIPELINE_PLOTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ready
        val run_name
        val output_directory
        val output_file

    output:
        val true, emit: ready

    script:
        """
        #!/bin/bash

        python3 /app/plot_frequency_distribution_xml.py \
            -r $run_name -i $output_directory -o $output_file
        """
}

process database_insert {
    container = params.PIPELINE_PLOTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ready
        val column
        val run_name
        val database_env
        val file

    output:
	    val true, emit: ready

    script:
        """
        #!/bin/bash

        python3 /app/add_plot_to_database.py \
            -c $column -r $run_name -e $database_env -f $file
        """
}

process cleanup {
    executor = 'local'

    input:
        val mom0_ready
        val diagnostic_plot_ready
        val output_directory
        val prefix

    output:
        val true, emit: ready

    script:
        """
        #!/bin/bash
        rm -rf $output_directory/$prefix*
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow moment0 {
    take:
        ready
        run_name
        database_env
        output_directory
        output_file

    main:
        mosaic(ready,
               output_directory,
               output_file)
        database_insert(mosaic.out.output_mom_file,
                        "mom0",
                        run_name,
                        database_env,
                        mosaic.out.output_mom_file)
        compress(database_insert.out.ready, mosaic.out.output_mom_file)

    emit:
        done = compress.out.ready
}

workflow diagnostic_plot {
    take:
        ready
        run_name
        output_directory
        output_file
        database_env

    main:
        plot_frequency_distribution(ready, run_name, output_directory, output_file)
        database_insert(
            plot_frequency_distribution.out.ready,
            "frequency",
            run_name,
            database_env,
            output_file)

    emit:
        done = database_insert.out.ready
}

// ----------------------------------------------------------------------------------------
