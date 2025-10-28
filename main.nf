#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './modules/singularity'
include { download_ser_footprints } from './modules/download'
include { generate_linmos_config as footprint_generate_linmos_config } from './modules/mosaicking'
include { generate_linmos_config as ser_generate_linmos_config } from './modules/mosaicking'
include { run_linmos as footprint_run_linmos } from './modules/mosaicking'
include { run_linmos as ser_run_linmos } from './modules/mosaicking'
include { ser_add_sbids_to_fits_header } from './modules/metadata'
include { source_finding } from './modules/source_finding'
include { moment0 } from './modules/outputs'


workflow wallaby_ser {
    take:
        SER

    main:
        download_containers()
        download_ser_footprints(SER, download_containers.out.ready)

        // Mosaic observation footprints to produce tiles (parallel if multiple tiles)
        footprint_generate_linmos_config(
            download_footprint.out.tile_files,
            download_footprint.out.tile_name,
            1, SER
        )
        footprint_run_linmos(
            footprint_generate_linmos_config.out.linmos_conf,
            footprint_generate_linmos_config.out.linmos_log_conf,
            footprint_generate_linmos_config.out.mosaic_files,
            1
        )

        // Mosaic tiles together for SER
        ser_collect(footprint_run_linmos.out.mosaic_files.collect(), SER)
        ser_generate_linmos_config(
            ser_collect.out.ser_files,
            ser_collect.out.tile_name,
            ser_collect.out.run_mosaic,
            SER
        )
        ser_run_linmos(
            ser_generate_linmos_config.out.linmos_conf,
            ser_generate_linmos_config.out.linmos_log_conf,
            ser_generate_linmos_config.out.mosaic_files,
            ser_collect.out.run_mosaic
        )

        // inject metadata
        ser_run_linmos.out.mosaic_files.view()
        ser_add_sbids_to_fits_header(SER, ser_run_linmos.out.mosaic_files.flatMap(), "${params.DATABASE_ENV}")

        // Pixel extent is 1170 pixels either side of centre for a SER
        source_finding(
            ser_run_linmos.out.mosaic_files,
            SER,
            "${params.WORKDIR}/regions/${SER}/sofia/",
            "${params.WORKDIR}/regions/${SER}/sofia/output",
            "${params.WORKDIR}/regions/${SER}/sofia/sofiax.ini",
            "\"1170, 1170\"",
            ser_add_sbids_to_fits_header.out.done.collect()
        )

        // Generate moment 0 map
        moment0(
            source_finding.out.done,
            SER,
            "${params.DATABASE_ENV}",
            "${params.WORKDIR}/regions/${SER}/sofia/output",
            "${params.WORKDIR}/regions/${SER}/sofia/output/mom0.fits"
        )
}

workflow {
    main:
        wallaby_ser(params.SER)
}
