#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

process download_singularity {
    executor = 'local'
    debug true

    input:


    output:
        stdout emit: stdout

    shell:
        '''
        #!/bin/bash

        lock_acquire() {
            # Open a file descriptor to lock file
            exec {LOCKFD}>!{params.SINGULARITY_CACHEDIR}/container.lock || return 1

            # Block until an exclusive lock can be obtained on the file descriptor
            flock -x $LOCKFD
        }

        lock_release() {
            test "$LOCKFD" || return 1

            # Close lock file descriptor, thereby releasing exclusive lock
            exec {LOCKFD}>&- && unset LOCKFD
        }

        lock_acquire || { echo >&2 "Error: failed to acquire lock"; exit 1; }

        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.CASDA_DOWNLOAD_IMAGE_NAME}.img docker://!{params.CASDA_DOWNLOAD_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.OBSERVATION_METADATA_IMAGE_NAME}.img docker://!{params.OBSERVATION_METADATA_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.METADATA_IMAGE_NAME}.img docker://!{params.METADATA_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.WALLABY_COMPONENTS_IMAGE_NAME}.img docker://!{params.WALLABY_COMPONENTS_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.UPDATE_LINMOS_CONFIG_IMAGE_NAME}.img docker://!{params.UPDATE_LINMOS_CONFIG_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.LINMOS_IMAGE_NAME}.img docker://!{params.LINMOS_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.S2P_SETUP_IMAGE_NAME}.img docker://!{params.S2P_SETUP_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.UPDATE_SOFIAX_CONFIG_IMAGE_NAME}.img docker://!{params.UPDATE_SOFIAX_CONFIG_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.SOFIA_IMAGE_NAME}.img docker://!{params.SOFIA_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.SOFIAX_IMAGE_NAME}.img docker://!{params.SOFIAX_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.GET_DSS_IMAGE_NAME}.img docker://!{params.GET_DSS_IMAGE}
        singularity pull !{params.SINGULARITY_CACHEDIR}/!{params.WALLMERGE_IMAGE_NAME}.img docker://!{params.WALLMERGE_IMAGE}

        lock_release
        '''
}


// ----------------------------------------------------------------------------------------
// Workflow
// ----------------------------------------------------------------------------------------

workflow download_containers {
    take:

    main:
        download_singularity()
    
    emit:
        stdout = download_singularity.out.stdout
}