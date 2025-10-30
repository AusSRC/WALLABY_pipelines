#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process generate_linmos_config {
    debug true
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val tile_files
        val tile_name
        val run_mosaic
        val SER
        val ready

    output:
        val linmos_conf, emit: linmos_conf
        val linmos_log_conf, emit: linmos_log_conf
        val mosaic_files, emit: mosaic_files

    script:
        linmos_conf = "${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.conf"
        linmos_log_conf = "${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.log_cfg"
        mosaic_files = ["${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_image.fits",
                        "${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_weights.fits"]
        """
        #!python3

        import os
        import json
        from jinja2 import Environment, FileSystemLoader
        from pathlib import Path

        generate_file = ${run_mosaic}

        if generate_file == 1:
            with open('${tile_files}') as o:
                data = json.loads(o.read())

            images = [Path(image).with_suffix('') for image in data if 'image.' in image]
            weights = [Path(weight).with_suffix('') for weight in data if 'weights.' in weight]
            images.sort()
            weights.sort()
            image_out = Path('${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_image')
            weight_out = Path('${params.WORKDIR}/regions/${SER}/${tile_name}/${tile_name}_weights')
            log = Path('${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.log')

            image_history = [
                "AusSRC WALLABY pipeline START",
                "${workflow.repository} - ${workflow.revision} [${workflow.commitId}]",
                "${workflow.commandLine}",
                "${workflow.start}",
                "Austin Shen (austin.shen@csiro.au)",
                "AusSRC WALLABY pipeline END"
            ]

            j2_env = Environment(loader=FileSystemLoader('$baseDir/templates'), trim_blocks=True)
            result = j2_env.get_template('linmos.j2').render(images=images, weights=weights, \
            image_out=image_out, weight_out=weight_out, image_history=image_history,)

            try:
                os.makedirs('${params.WORKDIR}/regions/${SER}/${tile_name}')
            except:
                pass

            with open('${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.conf', 'w') as f:
                print(result, file=f)

            result = j2_env.get_template('log_template.j2').render(log=log)

            with open('${params.WORKDIR}/regions/${SER}/${tile_name}/linmos.log_cfg', 'w') as f:
                print(result, file=f)
        """
}

import groovy.json.JsonOutput
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

process run_linmos {
    input:
        val linmos_conf
        val linmos_log_conf
        val mosaic_files
        val run_linmos

    output:
        val mosaic_files, emit: mosaic_files

    script:
        def image_file = mosaic_files[0]
        """
        #!/bin/bash

        run=${run_linmos}

        if [ "\$run" -eq 1 ]; then
            if ! test -f $image_file; then
                unset SLURM_MEM_PER_CPU
                unset SLURM_MEM_PER_NODE
                export OMP_NUM_THREADS=4
                srun -n 72 singularity exec \
                    --bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT} \
                    ${params.SINGULARITY_CACHEDIR}/${params.LINMOS_IMAGE_NAME}.img \
                    linmos-mpi -c $linmos_conf -l $linmos_log_conf
            fi
        fi
        """
}