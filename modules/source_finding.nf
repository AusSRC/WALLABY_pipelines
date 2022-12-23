#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Check dependencies for pipeline run
process check_dependencies {
    input:
        val image_cube
        val weights_cube

    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        # Ensure working directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME} ] && mkdir ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}
        # Ensure sofia output directory exists
        [ ! -d ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME} ] && mkdir ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME}
        # Ensure parameter file exists
        [ ! -f ${params.SOFIA_PARAMETER_FILE} ] && \
            { echo "Source finding parameter file (params.SOFIA_PARAMETER_FILE) not found"; exit 1; }
        # Ensure s2p setup file exists
        [ ! -f ${params.S2P_TEMPLATE} ] && \
            { echo "Source finding s2p_setup template file (params.S2P_TEMPLATE) not found"; exit 1; }
        # Ensure image cube file exists
        [ ! -f $image_cube ] && \
            { echo "Source finding image cube (params.IMAGE_CUBE) not found"; exit 1; }
        # Ensure weights cube file exists
        [ ! -f $weights_cube ] && \
            { echo "Source finding weights cube (params.WEIGHTS_CUBE) not found"; exit 1; }
        exit 0
        """
}

// Create parameter files and config files for running SoFiA via SoFiAX
process s2p_setup {
    container = params.S2P_SETUP_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val image_cube
        val weights_cube
        val check

    output:
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        python3 -u /app/s2p_setup.py \
            --config ${params.S2P_TEMPLATE} \
            --image_cube $image_cube \
            --weights_cube $weights_cube \
            --region '${params.REGION}' \
            --run_name ${params.RUN_NAME} \
            --sofia_template ${params.SOFIA_PARAMETER_FILE} \
            --output_dir ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME} \
            --products_dir ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME}
        """
}

// Update sofiax configuration file with run name
process update_sofiax_config {
    container = params.UPDATE_SOFIAX_CONFIG_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val s2p_setup

    output:
        val "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIAX_CONFIG_FILENAME}", emit: sofiax_config

    script:
        """
        #!/bin/bash
        python3 -u /app/update_sofiax_config.py \
            --config ${params.SOFIAX_CONFIG_FILE} \
            --database ${params.DATABASE_ENV} \
            --output ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIAX_CONFIG_FILENAME} \
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
        parameter_files = file("${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/sofia_*.par")
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
        stdout emit: stdout

    script:
        """
        #!/bin/bash
        python -m sofiax -c ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIAX_CONFIG_FILENAME} -p $parameter_file
        """
}

// Add DSS images to product table
process get_dss_image {
    container = params.GET_DSS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val sofiax_check

    script:
        """
        #!/bin/bash

        python /app/get_dss_image.py -r ${params.RUN_NAME} -e ${params.DATABASE_ENV}
        """
}

// TODO(austin): rename image and weights cubes
process rename_mosaic {
    input:
        val sofiax

    script:
        """
        #!/bin/bash

        # Rename mosaic image file if it exists
        [ -f ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/mosaic.fits ] && \
            { mv ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/mosaic.fits ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/\$(echo "image.restored.i.SB${params.SBIDS.replaceAll(',', ' ')}.mosaic.cube.fits" | tr " " .) }

        # Remame weights image file if it exists
        [ -f ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/mosaic.fits ] && \
            { mv ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/mosaic.weights.fits ${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/\$(echo "weights.i.SB${params.SBIDS.replaceAll(',', ' ')}.mosaic.cube.fits" | tr " " .) }
        """
}

// Generate source finding outputs
process get_products {
    executor = 'local'

    input:
        val sofiax

    output:
        val outputs, emit: outputs

    exec:
        outputs = "${params.WORKDIR}/${params.RUN_SUBDIR}/${params.RUN_NAME}/${params.SOFIA_OUTPUTS_DIRNAME}"
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_finding {
    take:
        image_cube
        weights_cube

    main:
        check_dependencies(image_cube, weights_cube)
        s2p_setup(image_cube, weights_cube, check_dependencies.out.stdout)
        update_sofiax_config(s2p_setup.out.stdout)
        get_parameter_files(update_sofiax_config.out.sofiax_config)
        sofia(get_parameter_files.out.parameter_files.flatten())
        sofiax(sofia.out.parameter_file.collect())
        get_dss_image(sofiax.out.stdout)
        get_products(sofiax.out.stdout)

    emit:
        outputs = get_products.out.outputs
}

// ----------------------------------------------------------------------------------------
