#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
scratchRoot = '/mnt/shared/'

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// 1. Download image cubes from CASDA
process casda_download {
    container = "astroaustin/wallaby_scripts:latest"
    containerOptions = "--bind $scratchRoot:$scratchRoot"

    input:
        val sbid

    output:
        stdout emit: cube

    script:
        """
        /app/download.py -i $sbid -o $launchDir -c $launchDir/credentials.ini
        """
}

// 2. Checksum comparison
process checksum {
    container = "astroaustin/wallaby_scripts:latest"
    containerOptions = "--bind $scratchRoot:$scratchRoot"

    input:
        val cube

    output:
        stdout emit: cube

    script:
        """
        python3 /app/verify_checksum.py $cube
        """
}

// 3. Generate configuration
process linmos_config {
    input:
        val cubes

    output:
        stdout emit: config

    script:
        """
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
        checksum(casda_download.out.cube)
        linmos_config(checksum.out.collect)
}

// ----------------------------------------------------------------------------------------

