#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Generate sofia parameter file from Nextflow params and defaults
process generate_params {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

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
// NOTE: output used only for workflow composition
process s2p_setup {
    container = params.S2P_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val cube_file
        val param_file

    output:
        val "${params.WORKDIR}/config.ini", emit: sofiax_config

    script:
        """
        python3 -u /app/s2p_setup.py \
            $cube_file \
            $param_file \
            ${params.SOFIA_RUN_NAME} \
            ${params.WORKDIR}
        """
}

// Another process for updating the config.ini file database credentials
process credentials {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val sofiax_config

    output:
        val sofiax_config, emit: sofiax_config
    
    script:
        """
        python3 /app/database_credentials.py \
            --config $sofiax_config \
            --host ${params.DATABASE_HOST} \
            --name ${params.DATABASE_NAME} \
            --username ${params.DATABASE_USER} \
            --password ${params.DATABASE_PASS}
        """
}

// Run source finding application (sofia)
process sofia {
    container = params.SOFIA_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'
    
    input:
        val sofiax_config
        val param_file

    output:
        val sofiax_config, emit: sofiax_config
        val param_file, emit: param_file

    script:
        """
        #!/bin/bash
        sofia $param_file
        """
}

// Join parameter files into single string
process params_string_join {
    input:
        val param_files
    
    output:
        stdout emit: sofiax_params
    
    script:
        """
        #!/usr/bin/env python3

        print('$param_files'.replace('[', '').replace(']', '').replace(',', ''))
        """  
}

// Write sofia output to database (sofiax)
process sofiax {
    container = params.SOFIAX_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'
    
    input:
        val param_files

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofiax -c ${params.WORKDIR}/${params.SOFIAX_CONFIG_FILE} -p $param_files
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_finding {
    take: cube

    main:
        generate_params(cube)
        s2p_setup(cube, generate_params.out.sofia_params)
        credentials(s2p_setup.out.sofiax_config)
        sofia(credentials.out.sofiax_config, Channel.fromPath("${params.WORKDIR}/sofia_*.par"))
        params_string_join(sofia.out.param_file.collect())
        sofiax(params_string_join.out.sofiax_params)
}

// ----------------------------------------------------------------------------------------
