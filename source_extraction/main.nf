#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Generate sofia config
process generate_config {

}

// Run source finder
process sofia {
    container = "astroaustin/sofia:latest"
    containerOptions = "-v $launchDir/test_case:/app/test_case"
    
    input:
        file params
        file conf 
    output:
        path params, emit: params
        path conf, emit: conf

    script:
        """
        #!/bin/bash
        sofia /app/test_case/$params
        """
}

// Write to database
process sofiax {
    container = "astroaustin/sofiax:latest"
    containerOptions = "-v $launchDir/test_case:/app/test_case"

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
    params_ch = Channel.fromPath( './test_case/*.par' )
    conf = file( './test_case/config.ini' )

    main:
        generate_config()
        sofia(generate_config.out.sofia_config)
        sofiax(sofia.out.params, sofia.out.conf)
}

// ----------------------------------------------------------------------------------------

