#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Check all dependencies in place for pipeline run
process pre_run_dependency_check {
    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash

        # Ensure working directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_NAME} ] && mkdir ${params.WORKDIR}/${params.RUN_NAME}

        # Ensure sofia output directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_NAME}/outputs ] && mkdir ${params.WORKDIR}/${params.RUN_NAME}/outputs

        # Ensure parameter file exists
        [ ! -f ${params.SOFIA_PARAMETER_FILE} ] && \
            { echo "Source finding parameter file (params.SOFIA_PARAMETER_FILE) not found"; exit 1; }

        # Ensure s2p setup file exists
        [ ! -f ${params.S2P_TEMPLATE} ] && \
            { echo "Source finding s2p_setup template file (params.S2P_TEMPLATE) not found"; exit 1; }

        exit 0
        """
}

// Download image cubes from CASDA
process casda_download {
    container = params.CASDA_DOWNLOAD_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val sbids
        val check

    output:
        stdout emit: stdout

    script:
        """
        python3 -u /app/casda_download.py \
            -i $sbids \
            -o ${params.WORKDIR}/${params.RUN_NAME} \
            -u '${params.CASDA_USERNAME}' \
            -p '${params.CASDA_PASSWORD}' \
            -q '${params.DOWNLOAD_QUERY}'
        """
}

// Find downloaded images on file system
process get_downloaded_files {
    executor = 'local'

    input:
        val casda_download

    output:
        val footprints, emit: footprints
        val weights, emit: weights

    exec:
        footprints = file("${params.WORKDIR}/${params.RUN_NAME}/image.restored.i.*.cube.contsub.fits")
        weights = file("${params.WORKDIR}/${params.RUN_NAME}/weights.i.*.cube.fits")
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow download {
    take:
        sbids

    main:
        pre_run_dependency_check()
        pre_run_dependency_check.out.stdout.view()
        casda_download(sbids, pre_run_dependency_check.out.stdout)
        get_downloaded_files(casda_download.out.stdout)
    
    emit:
        footprints = get_downloaded_files.out.footprints
        weights = get_downloaded_files.out.weights
}

// ----------------------------------------------------------------------------------------

