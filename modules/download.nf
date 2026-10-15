#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download } from '../pipeline_components/nextflow/modules/casda'

// CASDA TAP query for the WALLABY image and weights cubes of a list of SBIDs
def wallaby_query(sbids) {
    def ids = sbids.collect { "'${it}'" }.join(',')
    return "SELECT * FROM ivoa.obscore WHERE obs_id IN (${ids}) AND " +
           "dataproduct_type='cube' AND (" +
           "filename LIKE 'weights.i.%.cube.fits' OR " +
           "filename LIKE 'image.restored.i.%.cube.contsub.fits')"
}

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Get the footprint [image cube, weights cube] from the download manifest
import groovy.json.JsonSlurper
process parse_manifest {
    executor = 'local'

    input:
        val manifest

    output:
        val footprint, emit: footprint

    exec:
        def image = null
        def weight = null

        def files = new JsonSlurper().parseText(new File("$manifest").text)
        files.each {
            def filename = new File("$it").getName()
            if (filename.matches('image\\.restored\\.i\\..*\\.cube\\.contsub\\.fits')) {
                image = it
            }
            else if (filename.matches('weights\\.i\\..*\\.cube\\.fits')) {
                weight = it
            }
        }

        if (image == null) {
            throw new Exception("image cube file is not found")
        }

        if (weight == null) {
            throw new Exception("weights cube file is not found")
        }

        footprint = [image, weight]
}

// Get footprints for a given SER
process get_footprints {
    executor = 'local'
    container = params.AUSSRC_PIPELINE_COMPONENTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT} --bind \$HOME:\$HOME"

    input:
        val SER
        val ready

    output:
        val "${params.WORKDIR}/regions/${SER}/${SER}_query.json", emit: footprints_file

    script:
        """
        #!python3

        import os
        import json
        import pyvo as vo
        from pyvo.auth import authsession, securitymethods
        from collections import defaultdict
        from configparser import ConfigParser

        foot_map = defaultdict(list)

        parser = ConfigParser()
        parser.read('${params.TAP_CREDENTIALS}')
        username = parser['WALLABY']['username']
        password = parser['WALLABY']['password']

        ser = '${SER}'
        if not ser:
            raise ValueError('SER is empty')

        query = f"SELECT ser.name, t.name as tile_name, obs.sbid "\
                f"FROM wallaby.source_extraction_region as ser, "\
                f"wallaby.source_extraction_region_tile as sert, "\
                f"wallaby.tile as t, "\
                f"wallaby.tile_obs as tile_obs, "\
                f"wallaby.observation as obs "\
                f"WHERE  "\
                f"ser.id=sert.ser_id AND "\
                f"sert.tile_id=t.id AND "\
                f"t.id = tile_obs.tile_id AND "\
                f"tile_obs.obs_id = obs.id AND "\
                f"ser.name ='{ser}' "\
                f"ORDER BY ser.name"\

        URL = 'https://wallaby.aussrc.org/tap'
        auth = vo.auth.AuthSession()
        auth.add_security_method_for_url(URL, vo.auth.securitymethods.BASIC)
        auth.credentials.set_password(username, password)
        service = vo.dal.TAPService(URL, session=auth)
        rowset = service.search(query)
        for r in rowset:
            foot_map[r['tile_name']].append(r['sbid'])

        try:
            os.makedirs('${params.WORKDIR}/regions/${SER}/', exist_ok=True)
        except:
            pass

        with open('${params.WORKDIR}/regions/${SER}/${SER}_query.json', 'w') as f:
            json.dump(foot_map, f)

        """
}

process load_footprints {
    executor = 'local'

    input:
        val footprints_file

    output:
        val footprints_json, emit: footprints_json_map

    exec:
        def jsonSlurper = new JsonSlurper()
        def footprints = new File("${footprints_file}")
        String footprints_text = footprints.text
        footprints_json = jsonSlurper.parseText(footprints_text)
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

// Download image and weights cube pair for a given SBID
workflow casda_download {
    take:
        sbid
        output_dir
        ready

    main:
        download(
            ready.map { wallaby_query([sbid]) },
            output_dir,
            "${output_dir}/manifest.json"
        )
        parse_manifest(download.out.manifest)

    emit:
        footprint = parse_manifest.out.footprint
}

// Download image and weights cubes for all SBIDs that contribute to a given SER. The cubes
// for each tile (pair of footprints) are downloaded to <WORKDIR>/regions/<SER>/<tile>
workflow download_ser_footprints {
    take:
        SER
        ready

    main:
        get_footprints(SER, ready)
        load_footprints(get_footprints.out.footprints_file)

        // One download for each tile: [tile name, [sbids]]
        load_footprints.out.footprints_json_map
            .flatMap()
            .multiMap { footprint ->
                def tile_dir = "${params.WORKDIR}/regions/${SER}/${footprint.getKey()}"
                query: wallaby_query(footprint.getValue())
                output_dir: tile_dir
                manifest: "${tile_dir}/${footprint.getKey()}_files.json"
            }
            .set { tiles }
        download(tiles.query, tiles.output_dir, tiles.manifest)

        // Downloads complete in any order, so the tile is identified from the manifest
        tile_name = download.out.manifest.map { new File("$it").getParentFile().getName() }
        footprints_map = tile_name
            .combine(load_footprints.out.footprints_json_map)
            .map { tile, footprints -> footprints.find { it.getKey() == tile } }

    emit:
        tile_name = tile_name
        tile_files = download.out.manifest
        footprints_map = footprints_map
}

// ----------------------------------------------------------------------------------------
