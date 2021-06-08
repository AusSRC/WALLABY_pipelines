#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { mosaicking } from './mosaicking/main'
include { source_finding } from './source_finding/main'

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
        source_finding(mosaicking.out.cube)  
}