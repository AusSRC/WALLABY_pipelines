#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Check all dependencies in place for pipeline run
process dependency_check {
    input:
        val footprints
        val weights

    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash

        # Ensure working directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_NAME} ] && mkdir ${params.WORKDIR}/${params.RUN_NAME}

        # Ensure all image cube files exist
        [ ! -f ${footprints} ] && { echo "Footprint file could not be found"; exit 1; }

        # Ensure all weights cube files exist
        [ ! -f ${weights} ] && { echo "Weight file could not be found"; exit 1; }

        # Ensure default linmos config file exists
        [ ! -f ${params.LINMOS_CONFIG_FILE} ] && \
            { echo "Linmos configuration file (params.LINMOS_CONFIG_FILE) not found"; exit 1; }

        # Ensure sofia output directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME} ] && mkdir ${params.WORKDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME}

        # Ensure source finding parameter file exists
        [ ! -f ${params.SOFIA_PARAMETER_FILE} ] && \
            { echo "Source finding parameter file (params.SOFIA_PARAMETER_FILE) not found"; exit 1; }

        # Ensure s2p setup file exists
        [ ! -f ${params.S2P_TEMPLATE} ] && \
            { echo "Source finding s2p_setup template file (params.S2P_TEMPLATE) not found"; exit 1; }

        exit 0
        """
}

// Update configuration
process update_linmos_config {
    container = params.UPDATE_LINMOS_CONFIG_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val footprints
        val weights
        val check

    output:
        val "${params.WORKDIR}/${params.RUN_NAME}/${params.LINMOS_CONFIG_FILENAME}", emit: config

    script:
        """
        python3 -u /app/update_linmos_config.py \
            --config ${params.LINMOS_CONFIG_FILE} \
            --output ${params.WORKDIR}/${params.RUN_NAME}/${params.LINMOS_CONFIG_FILENAME} \
            --linmos.names "$footprints" \
            --linmos.weights "$weights" \
            --linmos.outname "${params.WORKDIR}/${params.RUN_NAME}/mosaic" \
            --linmos.outweight "${params.WORKDIR}/${params.RUN_NAME}/weights.mosaic"
        """
}

// Linear mosaicking
process linmos {
    input:
        val linmos_config
    
    output:
        val "${params.WORKDIR}/${params.RUN_NAME}/${params.MOSAIC_OUTPUT_FILENAME}.fits", emit: cube

    script:
        """
        #!/bin/bash
        singularity pull ${params.SINGULARITY_CACHEDIR}/askapsoft.sif ${params.LINMOS_IMAGE}
        export OMP_NUM_THREADS=4
	    mpiexec -np 144 singularity exec \
            --bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT} \
            ${params.SINGULARITY_CACHEDIR}/askapsoft.sif \
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
        dependency_check(footprints, weights)
        update_linmos_config(footprints.collect(), weights.collect(), dependency_check.out.stdout)
        linmos(update_linmos_config.out.config)
    
    emit:
        cube = linmos.out.cube
}

// ----------------------------------------------------------------------------------------
