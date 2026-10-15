#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { run_sofia; run_sofiax } from '../pipeline_components/nextflow/modules/sofia'

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Get the centre coordinate '<ra> <dec>' [degrees] of the SER
process ser_centre {
    executor = 'local'
    container = params.AUSSRC_PIPELINE_COMPONENTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val SER
        val ready

    output:
        stdout emit: centre_coord

    script:
        """
        #!python3

        import os
        import pyvo as vo
        from pyvo.auth import authsession, securitymethods
        from configparser import ConfigParser

        parser = ConfigParser()
        parser.read('${params.TAP_CREDENTIALS}')
        username = parser['WALLABY']['username']
        password = parser['WALLABY']['password']

        ser = '${SER}'
        if not ser:
            raise ValueError('SER is empty')

        URL = 'https://wallaby.aussrc.org/tap'
        auth = vo.auth.AuthSession()
        auth.add_security_method_for_url(URL, vo.auth.securitymethods.BASIC)
        auth.credentials.set_password(username, password)
        service = vo.dal.TAPService(URL, session=auth)
        query = f"SELECT * FROM wallaby.source_extraction_region WHERE name='{ser}'"
        res = service.search(query)
        ser_res = res[0]
        print(f'{ser_res["ra_deg"]} {ser_res["dec_deg"]}', end='')
        """
}

// Add DSS images to product table
process summary_figure {
    executor = 'local'
    container = params.AUSSRC_PIPELINE_COMPONENTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ready
        val run_name

    output:
        val true, emit: done

    script:
        """
        #!/bin/bash

        python3 -m aussrc_pipeline_components.plots.wallaby_extragalactic_summary \
            -r $run_name -e ${params.DATABASE_ENV}
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

// Source finding for a SER mosaic. Runs sofia on the region 1170 pixels either side of the
// centre of the SER, writes the detections to the database (sofiax) and adds the summary
// figures. Output directories
//      <WORKDIR>/regions/<run_name>/sofia              parameter and config files
//      <WORKDIR>/regions/<run_name>/sofia/output       sofia products
workflow source_finding_ser {
    take:
        mosaic_files
        ser
        run_name
        ready

    main:
        output_dir = "${params.WORKDIR}/regions/${run_name}/sofia"

        ser_centre(ser, ready)
        s2p_options = ser_centre.out.centre_coord.map {
            "--pixel_extent \"1170, 1170\" --centre_coord \"${it}\""
        }

        run_sofia(
            mosaic_files.map { it[0] },
            mosaic_files.map { it[1] },
            run_name,
            output_dir,
            "${output_dir}/output",
            s2p_options
        )
        run_sofiax(
            run_name,
            run_sofia.out.parameter_files,
            "${output_dir}/sofiax.ini"
        )
        summary_figure(run_sofiax.out.ready, run_name)

    emit:
        done = run_sofiax.out.ready
}

// ----------------------------------------------------------------------------------------
