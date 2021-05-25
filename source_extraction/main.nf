#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Generate sofia config
process generate_config {
    container = params.SCRIPTS_CONTAINER

    input:
        val cube_file

    output:
        stdout emit: sofia_params

    script:
        """
        python3 -u /app/generate_sofia_config.py \
            -i $cube_file \
            -f ${params.WORKDIR}/${params.SOFIA_PARAMS_FILE} \
            -d /app/templates/sofia.ini \
            -t /app/templates/sofia.j2
        """
}

// Run source finder
// TODO(austin): how to parallelise this.
process sofia {
    container = "astroaustin/sofia:latest"
    
    input:
        val params

    output:
        stdout emit: output
        val params, emit: params

    script:
        """
        #!/bin/bash
        sofia $params
        """
}

// Write to database
process sofiax {
    container = "astroaustin/sofiax:latest"

    input:
        val params
        val conf

    output:
        stdout emit: output
        val dependency = 'sofiax', emit: dependency

    script:
        """
        #!/bin/bash
        sofiax -c $conf -p $params
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_extraction {
    take: cube

    main:
        generate_config(cube)
        sofia(generate_config.out.params)
        // sofiax(sofia.out.params, sofia.out.conf)
}

// ----------------------------------------------------------------------------------------

