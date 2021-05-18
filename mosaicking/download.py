#!/usr/bin/env python3

import argparse
import configparser
from astroquery.utils.tap.core import TapPlus
from astroquery.casda import Casda


def main():
    """Downloads image cubes from CASDA for the argument observing block.
    The TAP search query will replace instances of '$SBID' with the argument
    observing block IDs. Expect only one .fits cube as a result of search.

    """
    # NOTE(austin): Could also require users input the query instead of the
    # SBID
    QUERY = "SELECT * FROM ivoa.obscore where obs_collection like '%WALLABY%' \
            and filename like 'image.restored.%SB$SBID.cube.contsub.fits' \
            and dataproduct_type = 'cube' "
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--sbid', type=int, required=True,
                        help='Observing block number.')
    parser.add_argument('-o', '--output', type=str, required=True,
                        help='Output directory for downloaded files.')
    parser.add_argument('-c', '--credentials', type=str, required=True,
                        help='Credentials file for CASDA service.')
    parser.add_argument('-q', '--query', type=str, required=False,
                        help='CASDA TAP search query.',
                        default=QUERY)
    args = parser.parse_args()

    # Query and show results
    casdatap = TapPlus(url="https://casda.csiro.au/casda_vo_tools/tap")
    job = casdatap.launch_job_async(
        args.query.replace('$SBID', str(args.sbid))
    )
    subset = job.get_results()

    # TODO(austin): log subset from search

    # Parse credentials
    config = configparser.ConfigParser()
    config.read("credentials.ini")
    login = config['LOGIN']

    # Download files
    casda = Casda(login["username"], login["password"])
    url_list = casda.stage_data(subset)
    casda.download_files(url_list, savedir=args.output)

    # Output for checksum
    print("yEEt")


if __name__ == "__main__":
    main()
