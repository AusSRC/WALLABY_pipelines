#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { casda_download } from './modules/casda_download'
include { source_finding } from './modules/source_finding'
include { moment0 } from './modules/moment0'

workflow {
    sbid = "${params.SBID}"

    main:
        source_finding(sbid)
        moment0(source_finding.out.output_directory)
}