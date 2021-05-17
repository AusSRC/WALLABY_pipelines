#!/usr/bin/env python3

import os
import sys
from astroquery.utils.tap.core import TapPlus
from astroquery.casda import Casda


def main():
    # SBID arguments
    search = sys.argv[1]

    # Query and show results
    casdatap = TapPlus(url="https://casda.csiro.au/casda_vo_tools/tap")
    job = casdatap.launch_job_async(
        f"SELECT * FROM ivoa.obscore where obs_collection like '%WALLABY%' \
            and filename like 'image.restored.%SB{search}.cube%.contsub.fits' \
            and dataproduct_type = 'cube' "
    )
    subset = job.get_results()
    print(subset)

    # Download files
    username = os.environ['OPAL_USERNAME']
    password = os.environ['OPAL_PASSWORD']
    casda = Casda(username, password)
    url_list = casda.stage_data(subset)
    casda.download_files(url_list, savedir='/Users/she393/Downloads/WALLABY/')


if __name__ == "__main__":
    main()
