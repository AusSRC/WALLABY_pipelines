#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Check dependencies for pipeline run
process check_metadata_directory {
    input:
        val download

    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        # Ensure metadata output directory exists
        [ ! -d ${params.WORKDIR}/${params.METADATA_SUBDIR} ] && mkdir ${params.WORKDIR}/${params.METADATA_SUBDIR}
        exit 0
        """
}

// Get metadata for observation
process get_metadata {
    container = params.OBSERVATION_METADATA_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val sbid
        val check

    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        python3 -u /app/get_slurm_output.py \
            -s $sbid \
            -f ${params.WORKDIR}/${params.METADATA_SUBDIR} \
            -d ${params.SOFIAX_CONFIG_FILE}
        """
}

process ser_add_sbids_to_fits_header {
    container = params.METADATA_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ser
        val file
        val database_env

    output:
        val true, emit: done

    script:
        """
        #!/bin/bash

        python3 /app/add_sbid_to_ser_mosaic_header.py -s $ser -f $file -e $database_env
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow observation_metadata {
    take:
        sbid
        download

    main:
        check_metadata_directory(download)
        get_metadata(sbid, check_metadata_directory.out.stdout)
}

// ----------------------------------------------------------------------------------------