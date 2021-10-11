#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { download } from './download/main'
include { mosaicking } from './mosaicking/main'
include { source_finding } from './source_finding/main'

workflow {
    sbids = Channel.of(params.SBIDS.split(','))

    main:
        download(sbids)
        mosaicking(download.out.footprints.collect())
        source_finding(mosaicking.out.cube)
}