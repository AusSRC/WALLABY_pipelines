#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Download image cubes from CASDA
// TODO(austin): Allow credentials to be passed as parameters?
// TODO(austin): What to do for authenticated users in our system?
process casda_download {
    container = params.SCRIPTS_CONTAINER

    input:
        val sbid

    output:
        stdout emit: cube

    script:
        """
        python3 -u /app/download.py -i $sbid -o ${params.WORKDIR} -c ${params.CASDA_CREDENTIALS}
        """
}

// Checksum comparison
process checksum {
    container = params.SCRIPTS_CONTAINER

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
    container = params.SCRIPTS_CONTAINER

    input:
        val cubes

    output:
        stdout emit: linmos_config

    script:
        """
        python3 -u /app/generate_config.py -i "$cubes" -f ${params.WORKDIR}/${params.LINMOS_OUTPUT_IMAGE} -c ${params.WORKDIR}/${params.LINMOS_CONFIG}
        """
}

// Linear mosaicking
// TODO(austin): emit mosaicked cube location
process linmos {
    container = "aussrc/yandasoft_devel_focal:latest"
    clusterOptions = params.LINMOS_CLUSTER_OPTIONS

    input:
        val linmos_config

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
    sbids = Channel.fromList(params.SBIDS)

    main:
        casda_download(sbids)
        checksum(casda_download.out.cube)
        generate_config(checksum.out.cube.collect())
        linmos(generate_config.out.linmos_config)
}

// ----------------------------------------------------------------------------------------

