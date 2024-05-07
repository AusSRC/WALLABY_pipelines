#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { download_containers } from './modules/singularity'
include { casda_download as download_A; casda_download as download_B } from './modules/casda_download'
include { generate_linmos_config; run_linmos } from './modules/mosaicking'

process footprint_tile_map {
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val footprint_A_files
        val footprint_B_files

    output:
        val tile_files, emit: tile_files

    script:
        def img_A = footprint_A_files[0]
        def weights_A = footprint_A_files[1]
        def img_B = footprint_B_files[0]
        def weights_B = footprint_B_files[1]

        tile_files = "${params.WORKDIR}/quality/${params.RUN_NAME}/tile_files.json"

        """
        #!python3

        import json
        with open("$tile_files", 'w') as f:
            json.dump(["$img_A", "$img_B", "$weights_A", "$weights_B"], f)
        """
}

workflow milkyway {
    take:
        RUN_NAME
        SBID_FOOTPRINT_A
        SBID_FOOTPRINT_B

    main:
        download_containers()
        download_A(
            SBID_FOOTPRINT_A,
            "${params.WORKDIR}/quality/${RUN_NAME}/",
            download_containers.out.ready,
            'WALLABY_MILKYWAY'
        )
        download_B(
            SBID_FOOTPRINT_B,
            "${params.WORKDIR}/quality/${RUN_NAME}/",
            download_containers.out.ready,
            'WALLABY_MILKYWAY'
        )
        footprint_tile_map(download_A.out.mosaic_files, download_B.out.mosaic_files)
        generate_linmos_config(
            footprint_tile_map.out.tile_files,
            "${RUN_NAME}.${SBID_FOOTPRINT_A}.${SBID_FOOTPRINT_B}.MilkyWay",
            1,
            "MilkyWay"
        )
        run_linmos(
            generate_linmos_config.out.linmos_conf,
            generate_linmos_config.out.linmos_log_conf,
            generate_linmos_config.out.mosaic_files,
            1
        )
}

workflow {
    main:
        milkyway(params.RUN_NAME, params.SBID_FOOTPRINT_A, params.SBID_FOOTPRINT_B)
}
