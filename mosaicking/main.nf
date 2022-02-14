#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Generate configuration
process generate_config {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val footprints

    output:
        stdout emit: linmos_config

    // TODO(austin): Eventually provide weights image paths here
    script:
        """
        python3 -u /app/generate_linmos_config.py \
            -i "$footprints" \
            -f ${params.WORKDIR}/${params.RUN_NAME}/${params.LINMOS_OUTPUT_IMAGE_CUBE} \
            -c ${params.WORKDIR}/${params.RUN_NAME}/${params.LINMOS_CONFIG_FILENAME}
        """
}

// Linear mosaicking
process linmos {
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"
    clusterOptions = params.LINMOS_CLUSTER_OPTIONS

    input:
        val linmos_config
    
    output:
        val "${params.WORKDIR}/${params.RUN_NAME}/${params.LINMOS_OUTPUT_IMAGE_CUBE}.fits", emit: mosaicked_cube

    script:
        """
        #!/bin/bash

        export SINGULARITY_PULLDIR=${params.SINGULARITY_CACHEDIR}
        singularity pull ${params.SINGULARITY_CACHEDIR}/yandasoft.img ${params.LINMOS_IMAGE}
        srun --nodes=12 --ntasks-per-node=24 --cpus-per-task=1 \
            singularity exec \
            --bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT} \
            ${params.SINGULARITY_CACHEDIR}/yandasoft.img \
            linmos-mpi -c $linmos_config
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow mosaicking {
    take: 
        footprints
        weights

    main:
        generate_config(footprints)
        linmos(generate_config.out.linmos_config)
    
    emit:
        cube = linmos.out.mosaicked_cube
}

// ----------------------------------------------------------------------------------------
