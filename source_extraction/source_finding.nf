#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
projectDir = projectDir
launchDir = launchDir
scratchRoot = '/mnt/shared/'

outputFilename = 'MilkyWay'
outputDir = '/mnt/shared/home/ashen/data/outputs/'

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Arguments: 
// - SBIDs for data cubes
// - sofia parameter files

// 1. DOWNLOAD
// https://data.csiro.au/collections/domain/casdaObservation/search/
// do it automatically (project code: AS102)
// You will need to download image cubes (contsub) and weights
// write process for this

// 2. Linear mosaicking
process linmos {
    container = "aussrc/yandasoft_devel_focal:latest"
    containerOptions = "--bind $scratchRoot:$scratchRoot"

    input:
        file linmos_config

    output:
        val "$outputDir/$outputFilename.fits", emit: image_out
        val "$outputDir/$outputFilename.weights.fits", emit: weight_out

    script:
        """
        #!/bin/bash
        if [ ! -f "$outputDir/$outputFilename.fits" ]; then
            mpirun linmos-mpi -c $linmos_config
        fi
        """
}

// TODO(austin):
// Introduce some step here to allow for inspecting of the
// mosaicked cube and enter it into the database

// 3. Source finding
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

// 4. Write to database
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
// Main
// ----------------------------------------------------------------------------------------

workflow {
    params_ch = Channel.fromPath( './test_case/*.par' )
    conf = file( './test_case/config.ini' )

    main:
        sofia(params_ch, conf)
        sofiax(sofia.out.params, sofia.out.conf)
}

// ----------------------------------------------------------------------------------------

