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
            -o ${params.WORKDIR}/${params.SOFIA_PARAMS_FILE} \
            -d /app/templates/sofia.ini \
            -t /app/templates/sofia.j2
        """
}

// Run source finder
// TODO(austin): how to parallelise this.
process sofia {
    container = "astroaustin/sofia:latest"
    
    input:
        file params

    output:
        path params, emit: params

    script:
        """
        #!/bin/bash
        sofia /app/test_case/$params
        """
}

// Write to database
process sofiax {
    container = "astroaustin/sofiax:latest"

    input:
        path params
        path conf

    output:
        stdout emit: output
        val dependency = 'sofiax', emit: dependency

    script:
        """
        #!/bin/bash
        sofiax -c /app/test_case/$conf -p /app/test_case/$params
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow {
    cube_file = params.CUBE_FILE

    main:
        generate_config(cube_file)
        sofia(generate_config.out.params)
        // sofiax(sofia.out.params, sofia.out.conf)
}

// ----------------------------------------------------------------------------------------

