#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Download image cubes from CASDA
process casda_download {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val sbid

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/casda_download.py \
            -i $sbid \
            -o ${params.WORKDIR} \
            -u '${params.CASDA_USERNAME}' \
            -p '${params.CASDA_PASSWORD}' \
            -ct '${params.CASDA_CUBE_TYPE}' \
            -cf '${params.CASDA_CUBE_FILENAME}' \
            -wt '${params.CASDA_WEIGHTS_TYPE}' \
            -wf '${params.CASDA_WEIGHTS_FILENAME}'
        """
}

// Checksum comparison
process checksum {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val cube

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/verify_checksum.py $cube
        """
}

// Generate configuration
process generate_config {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val cubes

    output:
        stdout emit: linmos_config

    script:
        """
        python3 -u /app/generate_linmos_config.py \
            -i "$cubes" \
            -f ${params.WORKDIR}/${params.LINMOS_OUTPUT_IMAGE_CUBE} \
            -c ${params.WORKDIR}/${params.LINMOS_CONFIG_FILENAME}
        """
}

// Linear mosaicking
process linmos {
    container = "aussrc/yandasoft_devel_focal:latest"
    containerOptions = '--bind /mnt/shared:/mnt/shared'
    clusterOptions = params.LINMOS_CLUSTER_OPTIONS

    input:
        val linmos_config
    
    output:
        val "${params.WORKDIR}/${params.LINMOS_OUTPUT_IMAGE_CUBE}.fits", emit: cube_file

    script:
        """
        #!/bin/bash
        mpirun linmos-mpi -c $linmos_config
        """
}

// TODO(austin): statistical check of mosaicked cube

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow mosaicking {
    take: sbids

    main:
        casda_download(sbids)
        checksum(casda_download.out.cube)
        generate_config(checksum.out.cube.collect())
        linmos(generate_config.out.linmos_config)
    
    emit:
        cube = linmos.out.cube_file
}

// ----------------------------------------------------------------------------------------

