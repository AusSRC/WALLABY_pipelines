#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Download image cubes from CASDA
process casda_download {
    container = $wallabyScriptsContainer

    input:
        val sbid

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/download.py -i $sbid -o $launchDir -c $launchDir/credentials.ini
        """
}

// Checksum comparison
process checksum {
    container = $wallabyScriptsContainer

    input:
        val cube

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/verify_checksum.py $cube
        """
}

// Generate configuration
process generate_config {
    container = $wallabyScriptsContainer

    input:
        val cubes

    output:
        stdout emit: linmos_config

    script:
        """
        python3 -u /app/generate_config.py -i "$cubes" -f mosaicked -c linmos.config
        """
}

// Linear mosaicking
// TODO(austin): emit mosaicked cube location
process linmos {
    container = "aussrc/yandasoft_devel_focal:latest"
    clusterOptions = "--ntasks=324 --ntasks-per-node=18"

    input:
        file linmos_config

    script:
        """
        #!/bin/bash
        mpirun linmos-mpi -c $linmos_config
        """
}

// TODO(austin): statistical check of mosaicked cube

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow {
    sbids = Channel.of(10809, 10812)

    main:
        casda_download(sbids)
        checksum(casda_download.out.cube)
        generate_config(checksum.out.cube.collect().view())
        linmos(generate_config.out.linmos_config)
}

// ----------------------------------------------------------------------------------------

