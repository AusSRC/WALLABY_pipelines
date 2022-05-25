#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Create parameter files and config files for running SoFiA via SoFiAX
process s2p_setup {
    container = params.S2P_SETUP_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val image_cube_file
        val sofia_parameter_file_template

    output:
        stdout emit: stdout

    script:
        """
        python3 -u /app/s2p_setup.py \
            ${params.S2P_TEMPLATE} \
            $image_cube_file \
            $sofia_parameter_file_template \
            ${params.RUN_NAME} \
            ${params.WORKDIR}/${params.RUN_NAME} \
            ${params.WORKDIR}/${params.RUN_NAME}/${params.OUTPUT_DIR}
        """
}

// Update sofiax configuration file with run name
process update_sofiax_config {
    container = params.UPDATE_SOFIAX_CONFIG_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val s2p_setup

    output:
        val "${params.WORKDIR}/${params.RUN_NAME}/${params.SOFIAX_CONFIG_FILENAME}", emit: sofiax_config
    
    script:
        """
        python3 -u /app/update_sofiax_config.py \
            --config ${params.SOFIAX_CONFIG_FILE} \
            --output ${params.WORKDIR}/${params.RUN_NAME}/${params.SOFIAX_CONFIG_FILENAME} \
            --run_name ${params.RUN_NAME}
        """
}

// Fetch parameter files from the filesystem (dynamically)
process get_parameter_files {
    executor = 'local'

    input:
        val sofiax_config

    output:
        val parameter_files, emit: parameter_files

    exec:
        parameter_files = file("${params.WORKDIR}/${params.RUN_NAME}/sofia_*.par")
}

// Run source finding application (sofia)
process sofia {
    container = params.SOFIA_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"
    
    input:
        file parameter_file

    output:
        path parameter_file, emit: parameter_file

    script:
        """
        #!/bin/bash
        
        OMP_NUM_THREADS=8 sofia $parameter_file
        """
}

// Write sofia output to database (sofiax)
process sofiax {
    container = params.SOFIAX_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"
    
    input:
        file parameter_file

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofiax -c ${params.WORKDIR}/${params.RUN_NAME}/${params.SOFIAX_CONFIG_FILE} -p $parameter_file
        """
}

// TODO(austin): rename weights cube tools
process rename_mosaic {
    input:
        val sofiax
    
    script:
        """
        #!/bin/bash

        # Rename mosaic image file if it exists
        [ -f ${params.WORKDIR}/${params.RUN_NAME}/mosaic.fits ] && \
            { mv ${params.WORKDIR}/${params.RUN_NAME}/mosaic.fits ${params.WORKDIR}/${params.RUN_NAME}/\$(echo "image.restored.i.SB${params.SBIDS.replaceAll(',', ' ')}.mosaic.cube.fits" | tr " " .) }

        # Remame weights image file if it exists
        [ -f ${params.WORKDIR}/${params.RUN_NAME}/mosaic.fits ] && \
            { mv ${params.WORKDIR}/${params.RUN_NAME}/mosaic.weights.fits ${params.WORKDIR}/${params.RUN_NAME}/\$(echo "weights.i.SB${params.SBIDS.replaceAll(',', ' ')}.mosaic.cube.fits" | tr " " .) }
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_finding {
    take: 
        cube
        sofia_parameter_file

    main:
        s2p_setup(cube, sofia_parameter_file)
        update_sofiax_config(s2p_setup.out.stdout)
        get_parameter_files(update_sofiax_config.out.sofiax_config)
        sofia(get_parameter_files.out.parameter_files.flatten())
        sofiax(sofia.out.parameter_file)
        rename_mosaic(sofiax.out.output)
}

// ----------------------------------------------------------------------------------------
