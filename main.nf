#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './modules/singularity'

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
            foot_map[r['tile_name']].append(int(r['sbid']))

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

process download_footprint {
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

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

process generate_linmos_config {
    debug true
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val tile_files
        val tile_name
        val SER

    output:
        val linmos_conf, emit: linmos_conf
        val linmos_log_conf, emit: linmos_log_conf
        val moasic_files, emit: moasic_files

    script:
        linmos_conf = "${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.conf"
        linmos_log_conf = "${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.log_cfg"
        moasic_files = ["${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_image",
                        "${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_weight"]
        """
        #!python3

        import json
        from jinja2 import Environment, FileSystemLoader
        from pathlib import Path

        with open('${tile_files}') as o:
            data = json.loads(o.read())

        images = [Path(image).with_suffix('') for image in data if 'image.' in image]
        weights = [Path(weight).with_suffix('') for weight in data if 'weights.' in weight]
        images.sort()
        weights.sort()
        image_out = Path('${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_image')
        weight_out = Path('${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_weight')
        log = Path('${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.log')

        j2_env = Environment(loader=FileSystemLoader('$baseDir/templates'), trim_blocks=True)
        result = j2_env.get_template('linmos.j2').render(images=images, weights=weights, \
        image_out=image_out, weight_out=weight_out)

        with open('${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.conf', 'w') as f:
            print(result, file=f)

        result = j2_env.get_template('log_template.j2').render(log=log)

        with open('${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.log_cfg', 'w') as f:
            print(result, file=f)
        """
}

process run_linmos {

    input:
        val linmos_conf
        val linmos_log_conf

    script:
        """
        #!/bin/bash

        export OMP_NUM_THREADS=4
	    srun -n 72 singularity exec \
             --bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT} \
             ${params.SINGULARITY_CACHEDIR}/${params.LINMOS_IMAGE_NAME}.img \
             linmos-mpi -c $linmos_conf -l $linmos_log_conf
        """
}


workflow wallaby_ser {
    take:
        SER

    main:
        download_containers()
        get_footprints(SER, download_containers.out.stdout)
        load_footprints(get_footprints.out.footprints_file)
        download_footprint(load_footprints.out.footprints_json_map.flatMap(), SER)
        generate_linmos_config(download_footprint.out.tile_files, download_footprint.out.tile_name, SER)
        run_linmos(generate_linmos_config.out.linmos_conf, generate_linmos_config.out.linmos_log_conf)
        //mosaicking(footprints, weights)
        //source_finding(mosaicking.out.image_cube, mosaicking.out.weights_cube)
}

workflow {
    main:
        wallaby_ser(params.SER)
}