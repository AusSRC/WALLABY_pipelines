#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Download image cubes from CASDA
process casda_download {
    container = params.CASDA_DOWNLOAD_COMPONENTS_IMAGE
    containerOptions = '--bind /mnt/shared:/mnt/shared'

    input:
        val sbids

    output:
        stdout emit: stdout

    script:
        """
        python3 -u /app/casda_download.py \
            -i $sbids \
            -o ${params.WORKDIR} \
            -u '${params.CASDA_USERNAME}' \
            -p '${params.CASDA_PASSWORD}'
        """
}

// Find downloaded images on file system
process get_downloaded_files {
    input:
        val casda_download

    output:
        val footprints, emit: footprints
        val weights, emit: weights

    exec:
        footprints = file("${params.WORKDIR}/image.restored.i.*.cube.contsub.fits")
        weights = file("${params.WORKDIR}/weights.i.*.cube.fits")
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow download {
    take: sbids

    main:
        casda_download(sbids)
        get_downloaded_files(casda_download.out.stdout)
    
    emit:
        footprints = get_downloaded_files.out.footprints
        weights = get_downloaded_files.out.weights
}

// ----------------------------------------------------------------------------------------

