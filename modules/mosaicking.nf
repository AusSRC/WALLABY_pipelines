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

        # Ensure working directories exists
        [ ! -d ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME} ] && mkdir ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}
        [ ! -d ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME} ] && mkdir ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME}

        # Ensure all image cube files exist
        [ ! -f ${footprints} ] && { echo "Footprint file could not be found"; exit 1; }
        [ ! -f ${weights} ] && { echo "Weight file could not be found"; exit 1; }

        # Check paramater files exist
        [ ! -f ${params.LINMOS_CONFIG_FILE} ] && \
            { echo "Linmos configuration file (params.LINMOS_CONFIG_FILE) not found"; exit 1; }
        [ ! -f ${params.SOFIA_PARAMETER_FILE} ] && \
            { echo "Source finding parameter file (params.SOFIA_PARAMETER_FILE) not found"; exit 1; }
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
        val "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.LINMOS_CONFIG_FILENAME}", emit: config

    script:
        """
        #!/bin/bash
        python3 -u /app/update_linmos_config.py \
            --config ${params.LINMOS_CONFIG_FILE} \
            --output ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.LINMOS_CONFIG_FILENAME} \
            --linmos.names "$footprints" \
            --linmos.weights "$weights" \
            --linmos.outname "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.MOSAIC_OUTPUT_FILENAME}" \
            --linmos.outweight "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/weights.${params.MOSAIC_OUTPUT_FILENAME}"
        """
}

// Linear mosaicking
process linmos {
    input:
        val linmos_config

    output:
        val "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.MOSAIC_OUTPUT_FILENAME}.fits", emit: image_cube
        val "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/weights.${params.MOSAIC_OUTPUT_FILENAME}.fits", emit: weights_cube

    script:
        """
        #!/bin/bash
        # singularity pull ${params.SINGULARITY_CACHEDIR}/askapsoft.sif ${params.LINMOS_IMAGE}
        export OMP_NUM_THREADS=4
	    mpiexec -np 144 singularity exec \
            --bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT} \
            ${params.SINGULARITY_CACHEDIR}/askapsoft.sif \
            linmos-mpi -c $linmos_config
        """
}

process get_sbids_from_footprint_filenames {
    input:
        path footprints

    output:
        stdout emit: stdout

    script:
        """
        #!/usr/bin/python3

        footprints = str("$footprints").split(' ')
        sbid_list = []
        for f in footprints:
            sbid_list += [s.replace('SB', '') for s in f.split('.') if 'SB' in s]
        sbids = ' '.join(sbid_list)
        print(sbids, end='')
        """
}

process add_sbids_to_header {
    container = params.METADATA_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        path files
        val sbids

    script:
        if (sbids == '')
            """
            #!/bin/bash
            python3 -u /app/add_mosaic_sbids_to_header.py -i $files
            """
        else
            """
            #!/bin/bash
            python3 -u /app/add_mosaic_sbids_to_header.py -i $files -s $sbids
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
        get_sbids_from_footprint_filenames(footprints.collect())
        add_sbids_to_header(
            footprints.concat(weights).collect(),
            get_sbids_from_footprint_filenames.out.stdout
        )

    emit:
        image_cube = linmos.out.image_cube
        weights_cube = linmos.out.weights_cube
}

// ----------------------------------------------------------------------------------------
