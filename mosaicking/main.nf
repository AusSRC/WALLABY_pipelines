#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
scratchRoot = '/mnt/shared/'

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// 1. Download image cubes from CASDA
process casda_download {
    input:
        val sbid

    output:
        stdout emit: cube

    script:
        """
        python3 $launchDir/download.py -l ${sbids} -o $launchDir -c $launchDir/credentials.ini
        """
}

// 2. Checksum comparison
process checksum {
    input:
        val cube

    output:
        stdout emit: cube

    script:
        """
        python3 $launchDir/verify_checksum.py cubes
        """
}

// collect here

// 3. Generate configuration
process linmos_config {
    input:
        val cubes

    output:
        stdout emit: output

    script:
        """
        python3 $projectDir/download.py -l $sbids -o $projectDir -c $projectDir/credentials.ini
        """
}

// 4. Linear mosaicking
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
// automated check on data cube for reasonable outcome from mosaicking.

// ----------------------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------------------

workflow {
    sbids = Channel.of(10809, 10812)

    main:
        casda_download(sbids)
        checksum(casda_download.cube)
}

// ----------------------------------------------------------------------------------------

