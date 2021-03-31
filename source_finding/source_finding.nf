#!/usr/bin/env nextflow

nextflow.enable.dsl=2
projectDir = projectDir

process sofia {
    input:
        file params

    output:
        stdout emit: output

    script:
        """
        docker run -v \$(pwd)/test_case:/app/test_case sofia /app/test_case/$params
        """
}

process sofiax {
    input:
        file config
        file params

    output:
        stdout

    script:
        """
        docker run -v \$(pwd)test_case:/app/test_case sofiax -c /app/test_case/$config -p /app/test_case/$params
        """
}

workflow {
    params_ch = Channel.fromPath( './test_case/sofia.par' )
    config_ch = Channel.fromPath( './test_case/config.ini' )
    
    sofia(params_ch)
    sofia.out.view()

    sofiax(config_ch, params_ch)
    sofiax.out.view()
}