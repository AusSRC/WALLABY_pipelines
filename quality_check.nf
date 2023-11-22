#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { casda_download } from './modules/casda_download'
include { source_finding } from './modules/source_finding'
include { download_containers } from './modules/singularity'
include { moment0 } from './modules/moment0'


workflow {
    run_name = "${params.RUN_NAME}"
    sbid = "${params.SBID}"

    main:
        download_containers()

        casda_download(sbid, 
                       "${params.WORKDIR}/quality/${params.RUN_NAME}/", 
                       download_containers.out.ready)

        source_finding(casda_download.out.mosaic_files,
                       "${params.RUN_NAME}", 
                       "${params.WORKDIR}/quality/${params.RUN_NAME}/sofia/", 
                       "${params.WORKDIR}/quality/${params.RUN_NAME}/sofia/output", 
                       "${params.WORKDIR}/quality/${params.RUN_NAME}/sofia/sofiax.ini",
                       "")

        moment0(source_finding.out.done,
                "${params.WORKDIR}/quality/${params.RUN_NAME}/sofia/output",
                "${params.WORKDIR}/quality/${params.RUN_NAME}/sofia/output/mom0.fits"
}