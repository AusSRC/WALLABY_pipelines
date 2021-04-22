#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
projectDir = projectDir
launchDir = launchDir

// ----------------------------------------------------------------------------------------
// Processes
// ----------------------------------------------------------------------------------------

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

process duplicateDetection {
    container = "astroaustin/wallaby-admin-jupyter:latest"
    containerOptions = "--env-file $launchDir/database.env"
    
    input:
        val dependency
    output:
        stdout emit: output
    
    script:
        """
        #!python3

        import os
        import sys
        import django
        import numpy as np

        # Django model setup  
        sys.path.append('/app/SoFiAX_services/api/')
        django.setup()
        from detection.models import Detection

        # Duplicate identification algorithm to apply
        def identify_duplicate(d1, d2):
            # Threshold values
            pos_threshold = 10
            flux_threshold = 5
            kin_pa_threshold = 5
            
            # Compute differences between detections
            pos_diff = np.linalg.norm(
                np.array([d1.x, d1.y, d1.z]) - np.array([d2.x, d2.y, d2.z])
            )
            flux_diff = np.abs(d1.f_sum - d2.f_sum)
            kin_pa_diff = np.abs(d1.kin_pa - d2.kin_pa)
            
            # Duplicate logic
            if (pos_diff <= pos_threshold) & (flux_diff <= flux_threshold) & (kin_pa_diff <= kin_pa_threshold):
                return True
            return False
        
        # Apply algorithm on all detection objects.
        detections = Detection.objects.all()
        N_detections = len(detections)
        detection_pair_ids = []

        for i in range(N_detections):
            for j in range(i + 1, N_detections):
                d1 = detections[i]
                d2 = detections[j]
                if identify_duplicate(d1, d2):
                    pair = (d1.id, d2.id)
                    detection_pair_ids.append(pair)
                    print(pair)
        """
}

// ----------------------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------------------

workflow {
    params_ch = Channel.fromPath( './test_case/*.par' )
    conf = file( './test_case/config.ini' )

    main:
        sofia(params_ch, conf)
        sofiax(sofia.out.params, sofia.out.conf)
        duplicateDetection(sofiax.out.dependency.collect())
}

// ----------------------------------------------------------------------------------------

