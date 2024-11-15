#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './modules/singularity'
include { generate_linmos_config as footprint_generate_linmos_config } from './modules/mosaicking'
include { generate_linmos_config as ser_generate_linmos_config } from './modules/mosaicking'
include { run_linmos as footprint_run_linmos } from './modules/mosaicking'
include { run_linmos as ser_run_linmos } from './modules/mosaicking'
include { ser_add_sbids_to_fits_header } from './modules/observation_metadata'
include { source_finding } from './modules/source_finding'
include { moment0 } from './modules/outputs'


process get_footprints {
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val SER
        val barrier

    output:
        val "${params.WORKDIR}/regions/${SER}/${SER}_query.json", emit: footprints_file

    script:
        """
        #!python3

        import os
        import json
        import pyvo as vo
        from collections import defaultdict

        foot_map = defaultdict(list)

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

        service = vo.dal.TAPService('https://wallaby.aussrc.org/tap')
        rowset = service.run_async(query)
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

import groovy.json.JsonSlurper
import groovy.json.JsonOutput

process load_footprints {
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

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


import groovy.json.JsonSlurper

process download_footprint {
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxErrors 10

    input:
        val footprint_map
        val SER

    output:
        val tile_files, emit: tile_files
        val tile_name, emit: tile_name

    script:
        tile_files = "${params.WORKDIR}/regions/${SER}/${footprint_map.getKey()}/${footprint_map.getKey()}_files.json"
        tile_name = "${footprint_map.getKey()}"
        """
        #!/bin/bash

        python3 -u /app/casda_download.py \
            -s ${footprint_map.getValue().join(' ')} \
            -m ${params.WORKDIR}/regions/${SER}/${footprint_map.getKey()}/${footprint_map.getKey()}_files.json \
            -o ${params.WORKDIR}/regions/${SER}/${footprint_map.getKey()} \
            -c ${params.CASDA_CREDENTIALS_CONFIG} \
            -p WALLABY
        """
}


process ser_collect {
    input:
        val all_mosaic_files
        val SER

    output:
        val ser_files, emit: ser_files
        val tile_name, emit: tile_name
        val run_mosaic, emit: run_mosaic

    exec:
        def json_str = JsonOutput.toJson(all_mosaic_files)
        new File("${params.WORKDIR}/regions/${SER}/${SER}_files.json").write(json_str)

        ser_files = "${params.WORKDIR}/regions/${SER}/${SER}_files.json"

        if (all_mosaic_files.size() > 2) {
            run_mosaic = 1
            tile_name = SER
        }
        else {
            // There is only a single TILE in the SER, get the TILE name
            run_mosaic = 0
            File f = new File(all_mosaic_files[0])
            def ra_dec = f.getName().split('_')[1]
            tile_name = "TILE_" + ra_dec
        }
}


workflow wallaby_ser {
    take:
        SER

    main:
        download_containers()

        get_footprints(SER, download_containers.out.ready)

        load_footprints(get_footprints.out.footprints_file)

        // SER can have 1 or more TILES. If more than one then flatten map and process in parallel
        download_footprint(load_footprints.out.footprints_json_map.flatMap(), SER)

        footprint_generate_linmos_config(download_footprint.out.tile_files,
                                         download_footprint.out.tile_name,
                                         1,
                                         SER)

        footprint_run_linmos(footprint_generate_linmos_config.out.linmos_conf,
                             footprint_generate_linmos_config.out.linmos_log_conf,
                             footprint_generate_linmos_config.out.mosaic_files,
                             1)

        ser_collect(footprint_run_linmos.out.mosaic_files.collect(), SER)

        ser_generate_linmos_config(ser_collect.out.ser_files,
                                   ser_collect.out.tile_name,
                                   ser_collect.out.run_mosaic,
                                   SER)

        ser_run_linmos(ser_generate_linmos_config.out.linmos_conf,
                       ser_generate_linmos_config.out.linmos_log_conf,
                       ser_generate_linmos_config.out.mosaic_files,
                       ser_collect.out.run_mosaic)

        // inject metadata
        ser_run_linmos.out.mosaic_files.view()
        ser_add_sbids_to_fits_header(SER, ser_run_linmos.out.mosaic_files.flatMap(), "${params.DATABASE_ENV}")

        // Pixel extent is 1700 pixels either side of centre for a SER
        source_finding(ser_run_linmos.out.mosaic_files,
                       SER,
                       "${params.WORKDIR}/regions/${SER}/sofia/",
                       "${params.WORKDIR}/regions/${SER}/sofia/output",
                       "${params.WORKDIR}/regions/${SER}/sofia/sofiax.ini",
                       "\"1170, 1170\"",
                       ser_add_sbids_to_fits_header.out.done.collect())

        moment0(source_finding.out.done,
                SER,
                "${params.DATABASE_ENV}",
                "${params.WORKDIR}/regions/${SER}/sofia/output",
                "${params.WORKDIR}/regions/${SER}/sofia/output/mom0.fits")
}

workflow {
    main:
        wallaby_ser(params.SER)
}
