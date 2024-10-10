#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { casda_download } from './modules/casda_download'
include { source_finding_quality_check } from './modules/source_finding'
include { download_containers } from './modules/singularity'
include { moment0; diagnostic_plot } from './modules/outputs'


workflow quality_check {
    take:
        RUN_NAME
        SBID

    main:
        download_containers()

        casda_download(SBID,
                       "${params.WORKDIR}/quality/${RUN_NAME}/",
                       download_containers.out.ready,
                       "${params.CASDA_DOWNLOAD_MANIFEST}")

        source_finding_quality_check(casda_download.out.mosaic_files,
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

workflow quality_check_no_download {
    take:
        RUN_NAME
        IMAGE_CUBE
        WEIGHTS_CUBE

    main:
        download_containers()
        source_finding_quality_check(["${params.IMAGE_CUBE}", "${params.WEIGHTS_CUBE}"],
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
        // TODO: add plots to quality_check table
}

workflow {
    main:
        quality_check(params.RUN_NAME, params.IMAGE_CUBE, params.WEIGHTS_CUBE)
}
