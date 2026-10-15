#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// WALLABY mosaicking
//
// Functions that describe the two WALLABY mosaics as jobs for the linmos module in
// pipeline_components (nextflow/modules/linmos.nf)
//
//      tile_job    Mosaic the footprints of a tile (observations A and B)
//      ser_job     Mosaic the tiles of a source extraction region (SER)
// ----------------------------------------------------------------------------------------

import groovy.json.JsonSlurper

// Lines written to the history of the mosaic image header
def linmos_history() {
    return [
        "AusSRC WALLABY pipeline START",
        "${workflow.repository} - ${workflow.revision} [${workflow.commitId}]",
        "${workflow.commandLine}",
        "${workflow.start}",
        "Austin Shen (austin.shen@csiro.au)",
        "AusSRC WALLABY pipeline END"
    ]
}

// Mosaic the footprints of a tile. The footprint image and weights cubes are listed in the
// download manifest of the tile. Output files
//      <WORKDIR>/regions/<SER>/<tile>/<tile>_image.fits
//      <WORKDIR>/regions/<SER>/<tile>/<tile>_weights.fits
def tile_job(ser, tile) {
    def tile_dir = "${params.WORKDIR}/regions/${ser}/${tile}"
    def files = new JsonSlurper().parseText(new File("${tile_dir}/${tile}_files.json").text)

    return [
        name: tile,
        images: files.findAll { new File("$it").getName().startsWith('image.') }.sort(),
        weights: files.findAll { new File("$it").getName().startsWith('weights.') }.sort(),
        image_out: "${tile_dir}/${tile}_image",
        weights_out: "${tile_dir}/${tile}_weights",
        config: "${tile_dir}/linmos.conf",
        history: linmos_history()
    ]
}

// Mosaic the tiles of a SER. The tiles are the outputs of the tile mosaics, a list with
// [image cube, weights cube] for each tile. Output files
//      <WORKDIR>/regions/<SER>/<SER>/<SER>_image.fits
//      <WORKDIR>/regions/<SER>/<SER>/<SER>_weights.fits
def ser_job(ser, tiles) {
    def ser_dir = "${params.WORKDIR}/regions/${ser}/${ser}"

    return [
        name: ser,
        images: tiles.collect { image, weights -> image }.sort(),
        weights: tiles.collect { image, weights -> weights }.sort(),
        image_out: "${ser_dir}/${ser}_image",
        weights_out: "${ser_dir}/${ser}_weights",
        config: "${ser_dir}/linmos.conf",
        history: linmos_history()
    ]
}
