#!/usr/bin/env nextflow

nextflow.enable.dsl=2
projectDir = projectDir
launchDir = launchDir

process sofia {
    container = "astroaustin/sofia:latest"
    containerOptions = "-v $launchDir/test_case:/app/test_case"
    
    input:
        file params

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofia /app/test_case/$params
        """
}

process sofiax {
    container = "astroaustin/sofiax:latest"
    containerOptions = "-v $launchDir/test_case:/app/test_case"

    input:
        file config
        file params

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofiax -c /app/test_case/$config -p /app/test_case/$params
        """
}

workflow runSofia {
    take: params
    main:
        sofia(params)
        sofia.out.view()
    emit:
        sofia.out    
}

workflow runSofiax {
    take: sofia
    take: config
    take: params

    main:
        sofiax(config, params)
        sofiax.out.view()
    emit:
        sofiax.out
}

workflow {
    params_ch = Channel.fromPath( './test_case/sofia.par' )
    config_ch = Channel.fromPath( './test_case/config.ini' )

    main:
        runSofia(params_ch)
        runSofiax(runSofia.out, config_ch, params_ch)
}