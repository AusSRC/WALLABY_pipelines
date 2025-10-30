#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process apply_flags {
    executor = 'local'
    container = params.CASDA_DOWNLOAD_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val SER
        val footprint_map

    output:
        val true, emit: done

    script:
        def tile = footprint_map.getKey()
        def (sbid_A, sbid_B) = footprint_map.getValue()
        """
        #!python3

        import os
        import glob
        import pyvo as vo
        import numpy as np
        from astropy.io import fits
        from pyvo.auth import authsession, securitymethods
        from configparser import ConfigParser

        def parse_region_str(region_str):
            region_list = region_str.split(';')
            region_list = [eval(r) for r in region_list]
            return region_list

        def flag_image(filename, regions):
            with fits.open(filename, mode='update', memmap=True) as hdul:
                header = hdul[0].header
                data = hdul[0].data
                (zmax, _, ymax, xmax) = data.shape
                for region in regions:
                    x1, x2, y1, y2, z1, z2 = region
                    x1 = max(0, x1)
                    y1 = max(0, y1)
                    z1 = max(0, z1)
                    x2 = min(x2, xmax)
                    y2 = min(y2, ymax)
                    z2 = min(z2, zmax)
                    print('Flagging region: (%i,%i,%i,%i,%i,%i)' % (x1, x2, y1, y2, z1, z2))
                    data[z1:z2, :, y1:y2, x1:x2] = np.full((z2-z1, 1, y2-y1, x2-x1), np.nan)
                    header.set('HISTORY', 'Flagged region: (%i,%i,%i,%i,%i,%i) set NaN values in data' % (x1, x2, y1, y2, z1, z2))
                hdul.flush()

        parser = ConfigParser()
        parser.read('${params.TAP_CREDENTIALS}')
        username = parser['WALLABY']['username']
        password = parser['WALLABY']['password']

        tile = "$tile"
        sbids = ["$sbid_A", "$sbid_B"]
        workdir = f"${params.WORKDIR}/regions/$SER/{tile}"

        URL = 'https://wallaby.aussrc.org/tap'
        auth = vo.auth.AuthSession()
        auth.add_security_method_for_url(URL, vo.auth.securitymethods.BASIC)
        auth.credentials.set_password(username, password)
        service = vo.dal.TAPService(URL, session=auth)

        for sbid in sbids:
            query = f"SELECT * FROM wallaby.observation WHERE sbid='{sbid}'"
            result = service.search(query, maxrec=1)
            flag = result[0]['flags']
            if not flag or flag == '':
                print('No flagging required for sbid %s' % sbid)
                continue
            files = glob.glob(os.path.join(workdir, f'image*{sbid.strip("ASKAP-")}*.fits'))
            img_file = files[0]
            if len(files) > 1:
                raise Exception(f'More than 1 file found matching sbid {sbid} in {workdir}')
            print('Flagging image %s for sbid %s region %s' % (img_file, sbid, flag))

            regions = parse_region_str(flag)
            flag_image(img_file, regions)
        """
}