#!/usr/bin/env python3

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

    # Attempt to download
    username = 'austin.shen@csiro.au'
    password = 'Y*Q2wQb_C4w9s-b37D'
    casda = Casda(username, password)
    url_list = casda.stage_data(subset)
    casda.download_files(url_list, savedir='./tmp')


if __name__ == "__main__":
    main()
