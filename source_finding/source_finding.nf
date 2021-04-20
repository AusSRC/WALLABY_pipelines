#!/usr/bin/env nextflow

nextflow.enable.dsl=2
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

    output:
        stdout emit: output

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
        file config
        file params

    output:
        stdout emit: output

    script:
        """
        #!/bin/bash
        sofiax -c /app/test_case/$config -p /app/test_case/$params
        """
}

process djangoDuplicateDetection {
    container = "astroaustin/wallaby-admin-jupyter:latest"
    containerOptions = "--env-file $launchDir/database.env"
    
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
// Workflows
// ----------------------------------------------------------------------------------------

workflow runSofia {
    take: params
    main:
        sofia(params)
        sofia.out.view()
    emit:
        sofia.out    
}

workflow runSofiax {
    take: sofia
    take: config
    take: params

    main:
        sofiax(config, params)
        sofiax.out.view()
    emit:
        sofiax.out
}

workflow duplicateDetection {
    take: sofiax

    main:
        djangoDuplicateDetection()
        djangoDuplicateDetection.out.view()
    emit:
        djangoDuplicateDetection.out
}

// ----------------------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------------------

workflow {
    params_ch = Channel.fromPath( './test_case/sofia.par' )
    config_ch = Channel.fromPath( './test_case/config.ini' )

    main:
        runSofia(params_ch)
        runSofiax(runSofia.out, config_ch, params_ch)
        duplicateDetection(runSofiax.out)
}

// ----------------------------------------------------------------------------------------