#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process apply_flags {
    executor = 'local'
    container = params.AUSSRC_PIPELINE_COMPONENTS_IMAGE
    containerOptions = "--bind ${params.SCRATCH_ROOT}:${params.SCRATCH_ROOT}"

    input:
        val SER
        val footprint_map

    output:
        val "${footprint_map.getKey()}", emit: tile

    script:
        def tile = footprint_map.getKey()
        def (sbid_A, sbid_B) = footprint_map.getValue()
        """
        #!python3

        import os
        import glob
        import asyncio
        import asyncpg
        import numpy as np
        from astropy.io import fits
        from dotenv import dotenv_values

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

        # Flag regions for each sbid from the observation table in the WALLABY database
        def get_flags(sbids):
            env = dotenv_values('${params.DATABASE_ENV}')

            async def query():
                conn = await asyncpg.connect(
                    host=env['DATABASE_HOST'],
                    database=env['DATABASE_NAME'],
                    user=env['DATABASE_USER'],
                    password=env['DATABASE_PASSWORD'],
                    port=env.get('DATABASE_PORT', '5432'),
                )
                rows = await conn.fetch(
                    'SELECT sbid, flags FROM wallaby.observation WHERE sbid = ANY(\$1::text[])', sbids
                )
                await conn.close()
                return {r['sbid']: r['flags'] for r in rows}

            flags = asyncio.run(query())
            missing = set(sbids) - set(flags)
            if missing:
                raise Exception(f'Observations not found in the database: {missing}')
            return flags

        tile = "$tile"
        sbids = ["$sbid_A", "$sbid_B"]
        workdir = f"${params.WORKDIR}/regions/$SER/{tile}"

        for sbid, flag in get_flags(sbids).items():
            if not flag:
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