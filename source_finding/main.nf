#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Generate sofia parameter file from Nextflow params and defaults
process generate_params {
    container = params.WALLABY_SCRIPTS

    input:
        val cube_file

    output:
        stdout emit: sofia_params

    script:
        """
        python3 -u /app/generate_sofia_params.py \
            -i $cube_file \
            -f ${params.WORKDIR}/${params.SOFIA_PARAMS_FILE}
        """
}

// Create scripts for running SoFiA via SoFiAX
process s2p_setup {
    container = params.S2P_IMAGE
    run_name = params.SOFIA_RUN_NAME

    input:
        val cube_file
        val sofia_params

    script:
        """
        python3 -u /app/s2p_setup.py \
            $cube_file \
            $sofia_params \
            $run_name
        """
}

// Run source finding application (sofia) through sofiax
// TODO(austin): actually get this working.
process sofia {
    container = "astroaustin/sofiax:latest"
    
    input:
        val config
        val params

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofia $params
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_finding {
    take: cube

    main:
        generate_config(cube)
        s2p_setup(cube, generate_config.out.sofia_params)
}

// ----------------------------------------------------------------------------------------
