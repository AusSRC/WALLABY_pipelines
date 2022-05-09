#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { mosaicking } from './mosaicking/main'
include { source_finding } from './source_finding/main'

workflow {
    footprints = Channel.of(params.FOOTPRINTS.replaceAll(',', ' '))
    weights = Channel.of(params.WEIGHTS.replaceAll(',', ' '))
    sofia_parameter_file = "${params.SOFIA_PARAMETER_FILE}"

    main:
        mosaicking(footprints, weights)
        source_finding(mosaicking.out.cube, sofia_parameter_file)
}