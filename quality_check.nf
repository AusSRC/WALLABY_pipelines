#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { casda_download } from './modules/casda_download'
include { source_finding } from './modules/source_finding'
include { moment0 } from './modules/moment0'

workflow {
    sbid = "${params.SBID}"

    main:
        casda_download(sbid)
        source_finding(casda_download.out.image_cube)
        moment0(source_finding.out.outputs)
}