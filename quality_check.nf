#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { casda_download } from './modules/casda_download'
include { source_finding } from './modules/source_finding'
include { download_containers } from './modules/singularity'
include { moment0; diagnostic_plot } from './modules/outputs'


workflow wallaby_quality {

    take:
        RUN_NAME
        SBID

    main:
        download_containers()

        casda_download(SBID,
                       "${params.WORKDIR}/quality/${RUN_NAME}/",
                       download_containers.out.ready)

        source_finding(casda_download.out.mosaic_files,
                       "${RUN_NAME}",
                       "${params.WORKDIR}/quality/${RUN_NAME}/sofia/",
                       "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output",
                       "${params.WORKDIR}/quality/${RUN_NAME}/sofia/sofiax.ini",
                       "")

        moment0(source_finding.out.done,
                "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output",
                "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output/mom0.fits")

        diagnostic_plot(source_finding.out.done,
                        "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output/diagnostics.pdf")
}

workflow {
    main:
        wallaby_quality(params.RUN_NAME,
                        params.SBID)
}