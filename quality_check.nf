#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './pipeline_components/nextflow/modules/singularity'
include { casda_download } from './modules/download'
include { run_sofia } from './pipeline_components/nextflow/modules/sofia'
include { moment0; diagnostic_plot; cleanup } from './pipeline_components/nextflow/modules/outputs'
include { create_run } from './pipeline_components/nextflow/modules/database'


// Source finding, moment 0 map and diagnostic plot for a footprint [image cube, weights cube],
// then create the run in the database. Output directories
//      <WORKDIR>/quality/<RUN_NAME>                    downloaded cubes
//      <WORKDIR>/quality/<RUN_NAME>/sofia              parameter files
//      <WORKDIR>/quality/<RUN_NAME>/sofia/output       sofia products, moment 0 map and plot
workflow quality_check {
    take:
        RUN_NAME
        footprint

    main:
        output_dir = "${params.WORKDIR}/quality/${RUN_NAME}/sofia"
        products_dir = "${output_dir}/output"

        footprint
            .multiMap { image, weights ->
                image_cube: image
                weights_cube: weights
            }
            .set { cubes }

        run_sofia(
            cubes.image_cube,
            cubes.weights_cube,
            RUN_NAME,
            output_dir,
            products_dir,
            ""
        )

        moment0(
            run_sofia.out.parameter_files,
            products_dir,
            "${products_dir}/mom0.fits"
        )

        diagnostic_plot(
            run_sofia.out.parameter_files,
            "${RUN_NAME}",
            products_dir,
            "${products_dir}/diagnostics.pdf"
        )

        create_run(
            moment0.out.done.combine(diagnostic_plot.out.done),
            RUN_NAME
        )

    emit:
        moment0_done = moment0.out.done
        diagnostic_plot_done = diagnostic_plot.out.done
}

// Run the quality check for either
//      --SBID                              Download the cubes for the observation from CASDA
//      --IMAGE_CUBE and --WEIGHTS_CUBE     Use existing cubes
workflow {
    main:
        if (!params.RUN_NAME) {
            error "RUN_NAME is required"
        }
        if (!params.SBID && !(params.IMAGE_CUBE && params.WEIGHTS_CUBE)) {
            error "Provide either SBID or both IMAGE_CUBE and WEIGHTS_CUBE"
        }

        download_containers([
            params.AUSSRC_PIPELINE_COMPONENTS_IMAGE,
            params.S2P_SETUP_IMAGE,
            params.SOFIA_IMAGE
        ])

        if (params.SBID) {
            casda_download(
                params.SBID,
                "${params.WORKDIR}/quality/${params.RUN_NAME}",
                download_containers.out.ready
            )
            footprint = casda_download.out.footprint
        }
        else {
            footprint = download_containers.out.ready.map { [params.IMAGE_CUBE, params.WEIGHTS_CUBE] }
        }

        quality_check(params.RUN_NAME, footprint)

        // Remove the sofia products of a downloaded observation
        if (params.SBID) {
            cleanup(
                quality_check.out.moment0_done,
                quality_check.out.diagnostic_plot_done,
                "${params.WORKDIR}/quality/${params.RUN_NAME}/sofia/output",
                params.RUN_NAME
            )
        }
}
