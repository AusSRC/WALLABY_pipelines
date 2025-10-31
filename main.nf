#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './modules/singularity'
include { download_ser_footprints } from './modules/download'
include { apply_flags } from './modules/flagging'
include { generate_linmos_config as footprint_linmos_config; run_linmos as footprint_linmos} from './modules/mosaicking'
include { generate_linmos_config as ser_linmos_config; run_linmos as ser_linmos} from './modules/mosaicking'
include { ser_collect } from './modules/mosaicking'
include { ser_add_sbids_to_fits_header } from './modules/metadata'
include { source_finding } from './modules/source_finding'
include { moment0 } from './modules/outputs'


workflow wallaby_ser {
    take:
        SER

    main:
        download_containers()
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

        // Pixel extent is 1170 pixels either side of centre for a SER
        source_finding(
            ser_linmos.out.mosaic_files,
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
