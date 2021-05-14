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

// Arguments: 
// - SBIDs for data cubes
// - sofia parameter files

// 1. Download image cubes from CASDA
process casda_download {
    container = "aussrc/emucat_scripts:latest"
    containerOptions = "-v $launchDir:/app"

    input:
        val sbids

    output:
        stdout emit: output

    script:
        """
        #!/usr/bin/env python3
        from astroquery.utils.tap.core import TapPlus

        for sbid in list($sbids):
            casdatap = TapPlus(url="https://casda.csiro.au/casda_vo_tools/tap")
            job = casdatap.launch_job_async(
                f"SELECT * FROM ivoa.obscore where obs_collection like '%WALLABY%' \
                    and filename like 'image.restored.%SB{sbid}.cube%.contsub.fits' \
                    and dataproduct_type = 'cube' "
            )
            subset = job.get_results()
            print(subset) 
        """
}

// 2. Linear mosaicking
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

// 3. Source finding
process sofia {
    container = "astroaustin/sofia:latest"
    containerOptions = "-v $launchDir/test_case:/app/test_case"
    
    input:
        file params
        file conf 
    output:
        path params, emit: params
        path conf, emit: conf

    script:
        """
        #!/bin/bash
        sofia /app/test_case/$params
        """
}

// 4. Write to database
process sofiax {
    container = "astroaustin/sofiax:latest"
    containerOptions = "-v $launchDir/test_case:/app/test_case"

    input:
        path params
        path conf
    output:
        stdout emit: output
        val dependency = 'sofiax', emit: dependency

    script:
        """
        #!/bin/bash
        sofiax -c /app/test_case/$conf -p /app/test_case/$params
        """
}

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

