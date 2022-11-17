#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Check dependencies for pipeline run
process check_write_directory {
    input:
        val run_name

    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        # Ensure download write directory exists
        [ ! -d ${params.WORKDIR}/$run_name ] && mkdir ${params.WORKDIR}/$run_name
        exit 0
        """
}

// Download image cube and weights files
process download {
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val sbid
        val run_name
        val check

    output:
        stdout emit: stdout

    script:
        """
        python3 -u /app/casda_download.py \
            -s $sbid \
            -o ${params.WORKDIR}/${params.RUN_NAME} \
            -c ${params.CASDA_CREDENTIALS_CONFIG} \
            -d ${params.DATABASE_ENV} \
            -p WALLABY
        """
}

// Get file from output directory
process get_image_and_weights_cube_files {
    executor = 'local'

    input:
        val sbid
        val run_name
        val download

    output:
        val image_cube, emit: image_cube
        val weights_cube, emit: weights_cube

    exec:
        image_cube = file("${params.WORKDIR}/$run_name/image*$sbid*.fits")[0]
        weights_cube = file("${params.WORKDIR}/$run_name/weight*$sbid*.fits")[0]
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow casda_download {
    take:
        run_name
        sbid

    main:
        check_write_directory(run_name)
        download(sbid, run_name, check_write_directory.out.stdout)
        get_image_and_weights_cube_files(sbid, run_name, download.out.stdout)

    emit:
        image_cube = get_image_and_weights_cube_files.out.image_cube
        weights_cube = get_image_and_weights_cube_files.out.weights_cube
}

// ----------------------------------------------------------------------------------------