#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Download image cubes from CASDA
process casda_download {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val sbid

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/casda_download.py \
            -i $sbid \
            -o ${params.WORKDIR} \
            -u '${params.CASDA_USERNAME}' \
            -p '${params.CASDA_PASSWORD}' \
            -ct '${params.CASDA_CUBE_TYPE}' \
            -cf '${params.CASDA_CUBE_FILENAME}' \
            -wt '${params.CASDA_WEIGHTS_TYPE}' \
            -wf '${params.CASDA_WEIGHTS_FILENAME}'
        """
}

// Checksum comparison
process checksum {
    container = params.WALLABY_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val cube

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/verify_checksum.py $cube
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow download {
    take: sbids

    main:
        casda_download(sbids)
        // checksum(casda_download.out.cube)
    
    emit:
        footprints = casda_download.out.cube
}

// ----------------------------------------------------------------------------------------

