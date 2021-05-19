#!/usr/bin/env python3
"""Downloads image cubes from CASDA for the argument observing block.
The TAP search query will replace instances of '$SBID' with the argument
observing block IDs. Expect only one .fits cube as a result of search.

"""

import os
import sys
import logging.config
import argparse
import configparser
from astroquery.utils.tap.core import TapPlus
from astroquery.casda import Casda


URL = "https://casda.csiro.au/casda_vo_tools/tap"
QUERY = "SELECT * FROM ivoa.obscore \
        where obs_collection like '%WALLABY%' \
        and filename like 'image.restored.%SB$SBID.cube.MilkyWay.contsub.fits' \
        and dataproduct_type = 'cube' "


# Remove all existing loggers (astroquery.utils.tap.core)
logging.config.dictConfig({
    'version': 1,
    'disable_existing_loggers': True
})


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i", "--input", type=int, required=True, help="Input observing block number."
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="Output directory for downloaded files.",
    )
    parser.add_argument(
        "-c",
        "--credentials",
        type=str,
        required=True,
        help="Credentials file for CASDA service.",
    )
    parser.add_argument(
        "-q",
        "--query",
        type=str,
        required=False,
        help="CASDA TAP search query.",
        default=QUERY,
    )
    args = parser.parse_args(argv)
    return args


def parse_config(credentials):
    config = configparser.ConfigParser()
    config.read(credentials)
    login = config["login"]
    return login


def tap_query(query):
    casdatap = TapPlus(url=URL, verbose=False)
    job = casdatap.launch_job_async(query)
    query_result = job.get_results()
    return query_result


def download(query_result, output, login):
    """Download CASDA data cubes from archive.
    TODO(austin): CASDA bug still causing issues - use this once fixed.
    download_files = casda.download_files(url_list, savedir=args.output)

    """
    casda = Casda(login["username"], login["password"])
    url_list = casda.stage_data(query_result)
    downloads = list(map(lambda x: f"{output}/{x.split('/')[-1]}", url_list))
    for (link, f) in zip(url_list, downloads):
        os.system(f"curl -o {f} {link}")
    return downloads


def main(argv):
    args = parse_args(argv)
    login = parse_config(args.credentials)
    result = tap_query(args.query.replace("$SBID", str(args.input)))
    files = download(result, args.output, login)

    # Output file (expecting only one)
    return_files = [f for f in files if "checksum" not in f]
    assert len(return_files) == 1, "Attempted to download more than one image cube."
    print(return_files[0], end="")


if __name__ == "__main__":
    main(sys.argv[1:])
