#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { mosaicking } from './modules/mosaicking'
include { source_finding } from './modules/source_finding'

workflow {
    footprints = Channel.of(params.FOOTPRINTS)
    weights = Channel.of(params.WEIGHTS)
    sofia_parameter_file = "${params.SOFIA_PARAMETER_FILE}"

    main:
        mosaicking(footprints, weights)
        source_finding(mosaicking.out.cube, sofia_parameter_file)
}