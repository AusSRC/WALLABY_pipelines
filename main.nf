#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { download } from './download/main'
include { mosaicking } from './mosaicking/main'
include { source_finding } from './source_finding/main'

workflow {
    // sbids = Channel.of(params.SBIDS.split(','))
    // footprints = Channel.of(params.FOOTPRINTS.split(','))
    cube = params.SOURCE_FINDING_IMAGE_CUBE

    main:
        // download(sbids)
        // mosaicking(footprints.collect())
        // mosaicking(download.out.footprints.collect())
        // source_finding(mosaicking.out.cube)
        source_finding(cube)
}