#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { source_finding_quality_check } from './modules/source_finding'
include { download_containers } from './modules/singularity'
include { moment0; diagnostic_plot; cleanup } from './modules/outputs'


workflow source_finding_run {
    take:
        IMAGE_CUBE
        WEIGHTS_CUBE
        RUN_NAME
        DIR

    main:
        source_finding_quality_check(["$IMAGE_CUBE", "$WEIGHTS_CUBE"],
                       "${RUN_NAME}",
                       "$DIR/sofia/",
                       "$DIR/sofia/output",
                       "$DIR/sofia/sofiax.ini",
                       "")

        moment0(source_finding_quality_check.out.done,
                "${RUN_NAME}",
                "${params.DATABASE_ENV}",
                "$DIR/sofia/output",
                "$DIR/sofia/output/mom0.fits")

        diagnostic_plot(source_finding_quality_check.out.done,
                "${RUN_NAME}",
                "$DIR/sofia/output",
                "$DIR/sofia/output/diagnostics.pdf",
                "${params.DATABASE_ENV}")
}

workflow {
    main:
        source_finding_run(
                params.IMAGE_CUBE,
                params.WEIGHTS_CUBE,
                params.RUN_NAME,
                params.DIR
        )
}
