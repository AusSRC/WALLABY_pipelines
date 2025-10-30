#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

process casda {
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxErrors 10

    input:
        val sbid
        val output_dir
        val ready
        val project

    output:
        val true, emit: ready

    script:
        """
        #!/bin/bash

        python3 -u /app/casda_download.py \
            -s $sbid \
            -o $output_dir \
            -c ${params.CASDA_CREDENTIALS_CONFIG} \
            -p $project \
            -t 10800
        """
}

// Get file from output directory
process get_image_and_weights_cube_files {
    executor = 'local'

    input:
        val sbid
        val output_dir
        val ready

    output:
        val mosaic_files, emit: mosaic_files

    exec:
        def sbid_text = "${sbid}"
        def sb_num = sbid_text.minus("ASKAP-")
        mosaic_files = [file("${output_dir}/image*" + sb_num + "*cube*.fits")[0], file("${output_dir}/weight*" + sb_num + "*cube*.fits")[0]]
}

// Get footprints for a given SER
process get_footprints {
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

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

import groovy.json.JsonSlurper
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
        val footprints_json_map
        val SER

    output:
        val tile_files, emit: tile_files
        val tile_name, emit: tile_name
        val footprints_json_map, emit: footprints_map

    script:
        tile_files = "${params.WORKDIR}/regions/${SER}/${footprints_json_map.getKey()}/${footprints_json_map.getKey()}_files.json"
        tile_name = "${footprints_json_map.getKey()}"
        """
        #!/bin/bash

        python3 -u /app/casda_download.py \
            -s ${footprints_json_map.getValue().join(' ')} \
            -m ${params.WORKDIR}/regions/${SER}/${footprints_json_map.getKey()}/${footprints_json_map.getKey()}_files.json \
            -o ${params.WORKDIR}/regions/${SER}/${footprints_json_map.getKey()} \
            -c ${params.CASDA_CREDENTIALS_CONFIG} \
            -p WALLABY
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

// Download image and weights cube pair for a given SBID
// This download workflow can be used across multiple ASKAP projects
workflow casda_download {
    take:
        sbid
        output_dir
        ready
        project

    main:
        casda(sbid, output_dir, ready, project)
        get_image_and_weights_cube_files(sbid, output_dir, casda.out.ready)

    emit:
        mosaic_files = get_image_and_weights_cube_files.out.mosaic_files
}

// Download image and weights cubes for all SBIDs that contribute to a given SER
// This is a WALLABY specific workflow.
workflow download_ser_footprints {
    take:
        SER
        ready

    main:
        get_footprints(SER, ready)
        load_footprints(get_footprints.out.footprints_file)
        download_footprint(load_footprints.out.footprints_json_map.flatMap(), SER)

    emit:
        tile_name = download_footprint.out.tile_name
        tile_files = download_footprint.out.tile_files
        footprints_map = download_footprint.out.footprints_map
}

// ----------------------------------------------------------------------------------------
