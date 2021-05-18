#!/usr/bin/env python3

import os
import logging
import argparse
import configparser
from astroquery.utils.tap.core import TapPlus
from astroquery.casda import Casda


logging.basicConfig(level=logging.WARNING)


def main():
    """Downloads image cubes from CASDA for the argument observing block.
    The TAP search query will replace instances of '$SBID' with the argument
    observing block IDs. Expect only one .fits cube as a result of search.

    """
    # NOTE(austin): Could also require users input the query instead of the
    # SBID
    URL = "https://casda.csiro.au/casda_vo_tools/tap"
    QUERY = "SELECT * FROM ivoa.obscore where obs_collection like '%WALLABY%' \
            and filename like 'image.restored.%SB$SBID.cube.MilkyWay.contsub.fits' \
            and dataproduct_type = 'cube' "

    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', type=int, required=True,
                        help='Input observing block number.')
    parser.add_argument('-o', '--output', type=str, required=True,
                        help='Output directory for downloaded files.')
    parser.add_argument('-c', '--credentials', type=str, required=True,
                        help='Credentials file for CASDA service.')
    parser.add_argument('-q', '--query', type=str, required=False,
                        help='CASDA TAP search query.',
                        default=QUERY)
    args = parser.parse_args()

    # Run query for cubes
    casdatap = TapPlus(url=URL, verbose=False)
    job = casdatap.launch_job_async(
        args.query.replace('$SBID', str(args.input))
    )
    subset = job.get_results()

    # TODO(austin): log subset from search

    # Parse credentials
    config = configparser.ConfigParser()
    config.read(args.credentials)
    login = config["login"]

    # Download files
    casda = Casda(login["username"], login["password"])
    url_list = casda.stage_data(subset)
    download_files = list(map(
        lambda x: f"{args.output}/{x.split('/')[-1]}",
        url_list
    ))
    for (link, f) in zip(url_list, download_files):
        os.system(f"curl -o {f} {link}")

    # TODO(austin): CASDA bug still causing issues - use this once fixed.
    # download_files = casda.download_files(url_list, savedir=args.output)

    # Output file (expecting only one)
    files = [f for f in download_files if "checksum" not in f]
    assert len(files) == 1, "Attempted to download more than one image cube."
    print(files[0], end='')


if __name__ == "__main__":
    main()
