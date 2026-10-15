#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process ser_add_sbids_to_fits_header {
    container = params.AUSSRC_PIPELINE_COMPONENTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ser
        val file
        val database_env

    output:
        val true, emit: done

    script:
        """
        #!/bin/bash

        python3 -m aussrc_pipeline_components.metadata.add_sbid_to_ser_mosaic_header -s $ser -f $file -e $database_env
        """
}