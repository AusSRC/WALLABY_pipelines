#!/usr/bin/env nextflow

nextflow.enable.dsl=2
projectDir = projectDir

process sofia {
    echo true
    
    input:
        file params

    output:
        stdout emit: output

    script:
        """
        docker run -v /Users/she393/Dropbox/projects/WALLABY/workflow/source_finding/test_case:/app/test_case sofia /app/test_case/$params
        """
}

process sofiax {
    echo true

    input:
        file config
        file params

    output:
        stdout emit: output

    script:
        """
        docker run -v /Users/she393/Dropbox/projects/WALLABY/workflow/source_finding/test_case:/app/test_case sofiax -c /app/test_case/$config -p /app/test_case/$params
        """
}

workflow runSofia {
    take: params
    main:
        sofia(params)
    emit:
        sofia.out    
}

workflow runSofiax {
    take: dependency
    take: config
    take: params

    main:
        sofiax(config, params)
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