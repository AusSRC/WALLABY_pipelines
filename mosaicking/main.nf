#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
projectDir = projectDir
launchDir = launchDir
scratchRoot = '/mnt/shared/'

outputFilename = 'MilkyWay'
outputDir = '/mnt/shared/home/ashen/data/outputs/'

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// 1. Download image cubes from CASDA
process casda_download {
    container = "aussrc/emucat_scripts:latest"
    containerOptions = "-v $launchDir:/app"

    input:
        val sbids

    output:
        stdout emit: output

    // TODO(austin): decide how to pass credentials to CASDA
    script:
        """
        #!/usr/bin/env python3

        from astroquery.utils.tap.core import TapPlus
        from astroquery.casda import Casda

        for sbid in list($sbids):
            # Query and show results
            casdatap = TapPlus(url="https://casda.csiro.au/casda_vo_tools/tap")
            job = casdatap.launch_job_async(
                f"SELECT * FROM ivoa.obscore where obs_collection like '%WALLABY%' \
                    and filename like 'image.restored.%SB{sbid}.cube%.contsub.fits' \
                    and dataproduct_type = 'cube' "
            )
            subset = job.get_results()
            print(subset)

            # Download files
            username = ''
            password = ''
            casda = Casda(username, password)
            url_list = casda.stage_data(subset)
            casda.download_files(url_list, savedir='/Users/she393/Downloads/WALLABY/')
        """
}

// 2. Checksum comparison?

// 3. Generate configuration

// 4. Linear mosaicking
process linmos {
    container = "aussrc/yandasoft_devel_focal:latest"
    containerOptions = "--bind $scratchRoot:$scratchRoot"

    input:
        file linmos_config

    output:
        val "$outputDir/$outputFilename.fits", emit: image_out
        val "$outputDir/$outputFilename.weights.fits", emit: weight_out

    script:
        """
        #!/bin/bash
        if [ ! -f "$outputDir/$outputFilename.fits" ]; then
            mpirun linmos-mpi -c $linmos_config
        fi
        """
}

// TODO(austin):
// Introduce some step here to allow for inspecting of the
// mosaicked cube and enter it into the database

// ----------------------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------------------

workflow {
    params_ch = Channel.fromPath( './test_case/*.par' )
    conf = file( './test_case/config.ini' )
    sbids = ['10809', '10812']

    main:
        casda_download(sbids)
        casda_download.out.view()
}

// ----------------------------------------------------------------------------------------

