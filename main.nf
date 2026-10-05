#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './pipeline_components/nextflow/modules/singularity'
include { download_ser_footprints } from './modules/download'
include { apply_flags } from './modules/flagging'
include { generate_linmos_config as footprint_linmos_config; run_linmos as footprint_linmos} from './modules/mosaicking'
include { generate_linmos_config as ser_linmos_config; run_linmos as ser_linmos} from './modules/mosaicking'
include { ser_collect } from './modules/mosaicking'
include { ser_add_sbids_to_fits_header } from './modules/metadata'
include { source_finding_ser } from './modules/source_finding'
include { moment0 } from './pipeline_components/nextflow/modules/outputs'


// Mosaic the footprints of a source extraction region (SER) and run source finding
workflow wallaby_ser {
    take:
        SER
        RUN_NAME

    main:
        download_containers([
            params.AUSSRC_PIPELINE_COMPONENTS_IMAGE,
            params.LINMOS_IMAGE,
            params.S2P_SETUP_IMAGE,
            params.SOFIA_IMAGE,
            params.SOFIAX_IMAGE
        ])
        download_ser_footprints(SER, download_containers.out.ready)
        apply_flags(SER, download_ser_footprints.out.footprints_map)

        // Mosaic observation footprints to produce tiles (parallel if multiple tiles)
        footprint_linmos_config(
            download_ser_footprints.out.tile_files,
            download_ser_footprints.out.tile_name,
            1,
            SER,
            apply_flags.out.done.collect()
        )
        footprint_linmos(
            footprint_linmos_config.out.linmos_conf,
            footprint_linmos_config.out.linmos_log_conf,
            footprint_linmos_config.out.mosaic_files,
            1
        )

        // Mosaic tiles together for SER
        ser_collect(footprint_linmos.out.mosaic_files.collect(), SER)
        ser_linmos_config(
            ser_collect.out.ser_files,
            ser_collect.out.tile_name,
            ser_collect.out.run_mosaic,
            SER,
            true
        )
        ser_linmos(
            ser_linmos_config.out.linmos_conf,
            ser_linmos_config.out.linmos_log_conf,
            ser_linmos_config.out.mosaic_files,
            ser_collect.out.run_mosaic
        )

        // inject metadata
        ser_linmos.out.mosaic_files.view()
        ser_add_sbids_to_fits_header(SER, ser_linmos.out.mosaic_files.flatMap(), "${params.DATABASE_ENV}")

        source_finding_ser(
            ser_linmos.out.mosaic_files,
            SER,
            RUN_NAME,
            ser_add_sbids_to_fits_header.out.done.collect()
        )

        // Generate moment 0 map
        moment0(
            source_finding_ser.out.done,
            "${params.WORKDIR}/regions/${RUN_NAME}/sofia/output",
            "${params.WORKDIR}/regions/${RUN_NAME}/sofia/output/mom0.fits"
        )
}

// Run the WALLABY mosaick and source finding pipeline
//      --SER       Source extraction region
//      --RUN_NAME  Name of the run (optional, defaults to SER)
workflow {
    main:
        if (!params.SER) {
            error "SER is required"
        }

        wallaby_ser(params.SER, params.RUN_NAME ?: params.SER)
}
