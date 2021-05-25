#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { mosaicking } from './mosaicking/main'
include { source_extraction } from './source_extraction/main'

/* Requires the following input parameters (minimum):

- SBIDS
- WORKDIR
- CASDA_USERNAME
- CASDA_PASSWORD
*/

workflow {
    sbids = Channel.of(params.SBIDS.split(','))

    main: 
        mosaicking(sbids)
        source_extraction(mosaicking.out.cube)  
}