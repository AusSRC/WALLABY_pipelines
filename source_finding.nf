#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { source_finding } from './modules/source_finding'

workflow {
    image_cube = "${params.IMAGE_CUBE}"
    sofia_parameter_file = "${params.SOFIA_PARAMETER_FILE}"

    main:
        source_finding(image_cube, sofia_parameter_file)
}