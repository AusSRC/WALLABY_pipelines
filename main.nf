#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { download } from './download/main'
include { mosaicking } from './mosaicking/main'
include { source_finding } from './source_finding/main'

workflow {
    sbids = Channel.of(params.SBIDS.replaceAll(',', ' '))
    sofia_parameter_file = "${params.SOFIA_PARAMETER_FILE}"

    main:
        download(sbids)
        mosaicking(download.out.footprints.collect(), download.out.weights.collect())
        source_finding(mosaicking.out.cube, sofia_parameter_file)
}