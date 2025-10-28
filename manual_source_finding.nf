#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './modules/singularity'
include { source_finding_quality_check } from './modules/source_finding'
include { moment0; diagnostic_plot } from './modules/outputs'


workflow source_finding_run {
    take:
        RUN_NAME
        IMAGE_CUBE
        WEIGHTS_CUBE

    main:
        download_containers()
        source_finding_quality_check(
            ["${params.IMAGE_CUBE}", "${params.WEIGHTS_CUBE}"],
            "${RUN_NAME}",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/sofiax.ini",
            ""
        )
        moment0(
            source_finding_quality_check.out.done,
            "${RUN_NAME}",
            "${params.DATABASE_ENV}",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output/mom0.fits"
        )
        diagnostic_plot(
            source_finding_quality_check.out.done,
            "${RUN_NAME}",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output",
            "${params.WORKDIR}/quality/${RUN_NAME}/sofia/output/diagnostics.pdf",
            "${params.DATABASE_ENV}"
        )
}

workflow {
    main:
        source_finding_run(
                params.RUN_NAME,
                params.IMAGE_CUBE,
                params.WEIGHTS_CUBE,
        )
}
