#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { source_finding } from './modules/source_finding'

workflow {
    image_cube = "${params.IMAGE_CUBE}"

    main:
        source_finding(image_cube)
}