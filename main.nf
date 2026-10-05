#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './pipeline_components/nextflow/modules/singularity'
include { download_ser_footprints } from './modules/download'
include { apply_flags } from './modules/flagging'
include { tile_job; ser_job } from './modules/mosaicking'
include { mosaic as mosaic_tiles; mosaic as mosaic_ser } from './pipeline_components/nextflow/modules/linmos'
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
            params.ASKAPSOFT_IMAGE,
            params.S2P_SETUP_IMAGE,
            params.SOFIA_IMAGE,
            params.SOFIAX_IMAGE
        ])
        download_ser_footprints(SER, download_containers.out.ready)
        apply_flags(SER, download_ser_footprints.out.footprints_map)

        // Step 1: mosaic the footprints of each tile. Each tile is mosaicked once its
        // footprints have been flagged, and the tiles are mosaicked in parallel.
        mosaic_tiles(apply_flags.out.tile.map { tile -> tile_job(SER, tile) })

        // Wait for all of the tiles. This is a single list with the files of each tile
        //      [[tile 1 image, tile 1 weights], [tile 2 image, tile 2 weights], ...]
        tiles = mosaic_tiles.out.mosaic.collect(flat: false)

        // Step 2: mosaic the tiles of the SER. Only needed if the SER has more than one
        // tile, otherwise the tile is used for source finding as it is.
        one_tile = tiles.filter { it.size() == 1 }
        many_tiles = tiles.filter { it.size() > 1 }

        mosaic_ser(many_tiles.map { ser_job(SER, it) })

        // The mosaic for source finding, [image cube, weights cube]. Only one of these two
        // channels has a value, the tile (first and only item of the list) or the SER mosaic.
        mosaic_files = one_tile.map { it[0] }.mix(mosaic_ser.out.mosaic)

        // inject metadata
        mosaic_files.view()
        ser_add_sbids_to_fits_header(SER, mosaic_files.flatMap(), "${params.DATABASE_ENV}")

        source_finding_ser(
            mosaic_files,
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
