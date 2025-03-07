#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

// Get the centre coordinate '<ra> <dec>' [degrees] of the SER
process ser_centre {
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
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

// Create parameter files and config files for running SoFiA via SoFiAX
process s2p_setup {
    container = params.S2P_SETUP_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val mosaic_files
        val run_name
        val output_dir
        val product_dir
        val pixel_extent
        val centre_coord

    output:
        val output_dir, emit: output_dir

    script:
        def image_cube = mosaic_files[0]
        def weights_cube = mosaic_files[1]
        """
        #!/bin/bash

        pixel=${pixel_extent}
        centre_coord=${centre_coord}

        if [ -z "\$pixel" ]; then
            python3 -u /app/s2p_setup.py \
                --config ${params.S2P_TEMPLATE} \
                --image_cube $image_cube \
                --weights_cube $weights_cube \
                --run_name $run_name \
                --sofia_template ${params.SOFIA_PARAMETER_FILE} \
                --output_dir $output_dir \
                --products_dir $product_dir
        else
            python3 -u /app/s2p_setup.py \
                --config ${params.S2P_TEMPLATE} \
                --pixel_extent $pixel_extent \
                --centre_coord "$centre_coord" \
                --image_cube $image_cube \
                --weights_cube $weights_cube \
                --run_name $run_name \
                --sofia_template ${params.SOFIA_PARAMETER_FILE} \
                --output_dir $output_dir \
                --products_dir $product_dir
        fi
        """
}

// Update sofiax configuration file with run name
process update_sofiax_config {
    container = params.UPDATE_SOFIAX_CONFIG_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val run_name
        val output_file
        val s2p_setup

    output:
        val output_file, emit: output_file
        val s2p_setup, emit: output_dir

    script:
        """
        #!/bin/bash

        python3 -u /app/update_sofiax_config.py \
            --config ${params.SOFIAX_CONFIG_FILE} \
            --database ${params.DATABASE_ENV} \
            --output $output_file \
            --run_name $run_name
        """
}

// Fetch parameter files from the filesystem (dynamically)
process get_parameter_files {
    executor = 'local'

    input:
        val sofiax_config

    output:
        val parameter_files, emit: parameter_files

    exec:
        parameter_files = file("${sofiax_config}/sofia_*.par")
}

// Run source finding application (sofia)
process sofia {
    container = params.SOFIA_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val parameter_file

    output:
        val parameter_file, emit: parameter_file

    script:
        """
        #!/bin/bash

        OMP_NUM_THREADS=8 sofia $parameter_file
        """
}

// Write sofia output to database (sofiax)
process sofiax {
    container = params.SOFIAX_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val parameter_file
        val sofiax_config

    output:
        val true, emit: ready

    script:
        """
        #!/bin/bash

        python -m sofiax -c $sofiax_config -p ${parameter_file.join(' ')}
        """
}

// Add DSS images to product table
process summary_figure {
    container = params.PIPELINE_PLOTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val ready
        val run_name

    output:
        val true, emit: done

    script:
        """
        #!/bin/bash
        python3 /app/wallaby_extragalactic_summary.py -r $run_name -e ${params.DATABASE_ENV}
        """
}

// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow source_finding {
    take:
        mosaic_file
        run_name
        output_dir
        product_dir
        sofiax_out_file
        pixel_extent
        ready

    main:
        ser_centre(run_name, ready)
        s2p_setup(mosaic_file,
                  run_name,
                  output_dir,
                  product_dir,
                  pixel_extent,
                  ser_centre.out.centre_coord)
        update_sofiax_config(run_name,
                             sofiax_out_file,
                             s2p_setup.out.output_dir)
        get_parameter_files(update_sofiax_config.out.output_dir)
        sofia(get_parameter_files.out.parameter_files.flatten())
        sofiax(sofia.out.parameter_file.collect(), update_sofiax_config.out.output_file)
        summary_figure(sofiax.out.ready, run_name)

    emit:
        done = sofiax.out.ready
}

// Source finding run without sofiax
workflow source_finding_quality_check {
    take:
        mosaic_file
        run_name
        output_dir
        product_dir
        sofiax_out_file
        pixel_extent

    main:
        s2p_setup(mosaic_file,
                  run_name,
                  output_dir,
                  product_dir,
                  pixel_extent,
                  true)
        update_sofiax_config(run_name,
                             sofiax_out_file,
                             s2p_setup.out.output_dir)
        get_parameter_files(update_sofiax_config.out.output_dir)
        sofia(get_parameter_files.out.parameter_files.flatten())

    emit:
        done = sofia.out.parameter_file.collect()
}

// ----------------------------------------------------------------------------------------
