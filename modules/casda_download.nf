#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------


// Download image cube and weights files
process download {
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxErrors 10

    input:
        val sbid
        val output_dir
        val ready

    output:
        val true, emit: ready

    script:
        """
        #!/bin/bash

        python3 -u /app/casda_download.py \
            -s $sbid \
            -o $output_dir \
            -c ${params.CASDA_CREDENTIALS_CONFIG} \
            -p WALLABY
        """
}

// Get file from output directory
process get_image_and_weights_cube_files {
    executor = 'local'

    input:
        val sbid
        val output_dir
        val ready

    output:
        val mosaic_files, emit: mosaic_files

    exec:
        mosaic_files = [file("${output_dir}/image*cube*.fits")[0], file("${output_dir}/weight*cube*.fits")[0]]
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow casda_download {
    take:
        sbid
        output_dir
        ready

    main:
        download(sbid, output_dir, ready)
        get_image_and_weights_cube_files(sbid, output_dir, download.out.ready)

    emit:
        mosaic_files = get_image_and_weights_cube_files.out.mosaic_files
}

// ----------------------------------------------------------------------------------------
