#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { casda_download } from './modules/casda_download'
include { observation_metadata } from './modules/observation_metadata'
include { source_finding } from './modules/source_finding'
include { moment0 } from './modules/moment0'

workflow {
    run_name = "${params.RUN_NAME}"
    sbid = "${params.SBID}"

    main:
        casda_download(run_name, sbid)
        observation_metadata(sbid, casda_download.out.image_cube)
        source_finding(casda_download.out.image_cube, casda_download.out.weights_cube)
        moment0(source_finding.out.outputs)
}