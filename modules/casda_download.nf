#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Check dependencies for pipeline run
process check_write_directory {
    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        # Ensure download write directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_NAME} ] && mkdir ${params.WORKDIR}/${params.RUN_NAME}
        exit 0
        """
}

// Download image cube and weights files
process download {
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val sbid
        val check

    output:
        stdout emit: stdout
    
    script:
        """
        python3 -u /app/casda_download.py \
            -i $sbid \
            -o ${params.WORKDIR}/${params.RUN_NAME} \
            -c ${params.CASDA_CREDENTIALS_CONFIG}
        """
}

// Get file from output directory
process get_image_and_weights_cube_files {
    executor = 'local'

    input:
        val sbid
        val download

    output:
        val image_cube, emit: image_cube
        val weights_cube, emit: weights_cube

    exec:
        image_cube = file("${params.WORKDIR}/${params.RUN_NAME}/image*$sbid*.fits")[0]
        weights_cube = file("${params.WORKDIR}/${params.RUN_NAME}/weight*$sbid*.fits")[0]
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow casda_download {
    take: 
        sbid

    main:
        check_write_directory()
        download(sbid, check_write_directory.out.stdout)
        get_image_and_weights_cube_files(sbid, download.out.stdout)
    
    emit:
        image_cube = get_image_and_weights_cube_files.out.image_cube
        weights_cube = get_image_and_weights_cube_files.out.weights_cube
}

// ----------------------------------------------------------------------------------------