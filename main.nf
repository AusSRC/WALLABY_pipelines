#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { download } from './download/main'
include { mosaicking } from './mosaicking/main'
include { source_finding } from './source_finding/main'

workflow {
    sbids = Channel.of(params.SBIDS.replaceAll(',', ' '))
    footprints = Channel.of(params.FOOTPRINTS.split(','))
    mosaicked_cube = "${params.MOSAICKED_IMAGE}"
    sofia_parameter_file = "${params.SOFIA_PARAMETER_FILE}"

    main:
        download(sbids)
        mosaicking(download.out.footprints.collect())
        source_finding(mosaicking.out.cube, sofia_parameter_file)
        // mosaicking(footprints.collect())
        // source_finding(mosaicked_cube, sofia_parameter_file)
}