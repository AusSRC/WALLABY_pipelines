#!/usr/bin/env python3
"""Downloads image cubes from CASDA for the argument observing block.
The TAP search query will replace instances of '$SBID' with the argument
observing block IDs. Expect only one .fits cube as a result of search.

Makes an assumption about the filename prefix for the weight files
corresponding to each of the data cubes.

"""

import os
import sys
import logging.config
import argparse
from astroquery.utils.tap.core import TapPlus
from astroquery.casda import Casda


# TODO(austin): obs_collection as argument
URL = "https://casda.csiro.au/casda_vo_tools/tap"
QUERY = "SELECT * FROM ivoa.obscore \
        where obs_collection like '%WALLABY%' \
        and filename like '$FILENAME' \
        and dataproduct_type = '$TYPE'"
CUBE_TYPE = "cube"
CUBE_FILENAME = 'image.restored.%SB$SBID%.cube.MilkyWay.contsub.fits'
WEIGHTS_TYPE = "cube"
WEIGHTS_FILENAME = 'weights%SB$SBID%.cube.MilkyWay.fits'


# Remove all existing loggers (astroquery.utils.tap.core)
logging.config.dictConfig({
    'version': 1,
    'disable_existing_loggers': True
})


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--input",
        type=int,
        required=True,
        help="Input observing block number."
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="Output directory for downloaded files.",
    )
    parser.add_argument(
        "-u",
        "--username",
        type=str,
        required=False,
        help="Username for CASDA data portal.",
        default=None
    )
    parser.add_argument(
        "-p",
        "--password",
        type=str,
        required=False,
        help="Password for CASDA data portal.",
        default=None
    )
    parser.add_argument(
        "-ct",
        "--cube_type",
        type=str,
        required=False,
        help="CASDA TAP query cube data product type.",
        default=CUBE_TYPE,
    )
    parser.add_argument(
        "-wt",
        "--weights_type",
        type=str,
        required=False,
        help="CASDA TAP query weights data product type.",
        default=WEIGHTS_TYPE,
    )
    parser.add_argument(
        "-cf",
        "--cube_filename",
        type=str,
        required=False,
        help="CASDA TAP query cube filename.",
        default=CUBE_FILENAME,
    )
    parser.add_argument(
        "-wf",
        "--weights_filename",
        type=str,
        required=False,
        help="CASDA TAP query weights filename search.",
        default=WEIGHTS_FILENAME,
    )
    # TODO(austin): remove this if not necessary
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


def get_credentials(args):
    """Get credentials for CASDA. Look first for environment
    variables and if they do not exist use argument.

    """
    username = os.environ.get("CASDA_USERNAME")
    password = os.environ.get("CASDA_PASSWORD")

    if username is None and password is None:
        username = args.username
        password = args.password
        if username is None and password is None:
            raise ValueError("CASDA credentials required as environment variables or parameters.")  # noqa
    return username, password


def tap_query(query):
    casdatap = TapPlus(url=URL, verbose=False)
    job = casdatap.launch_job_async(query)
    query_result = job.get_results()
    return query_result


def download(query_result, output, username, password):
    """Download CASDA data cubes from archive.
    TODO(austin): CASDA bug still causing issues - use this once fixed.
    download_files = casda.download_files(url_list, savedir=args.output)

    """
    casda = Casda(username, password)
    url_list = casda.stage_data(query_result)
    downloads = list(map(lambda x: f"{output}/{x.split('/')[-1]}", url_list))
    for (link, f) in zip(url_list, downloads):
        os.system(f"curl -o {f} {link}")
    return downloads


def main(argv):
    args = parse_args(argv)
    username, password = get_credentials(args)

    # download cubes
    cube_query = args.query\
        .replace("$TYPE", args.cube_type)\
        .replace("$FILENAME", args.cube_filename)\
        .replace("$SBID", str(args.input))
    cube_result = tap_query(cube_query)
    cube_files = download(cube_result, args.output, username, password)

    # download weights
    weight_query = args.query\
        .replace("$TYPE", args.weights_type)\
        .replace("$FILENAME", args.weights_filename)\
        .replace("$SBID", str(args.input))
    weight_result = tap_query(weight_query)
    download(weight_result, args.output, username, password)

    # Output cube file to stdout
    return_files = [f for f in cube_files if "checksum" not in f]
    assert len(return_files) == 1,\
        "Attempted to download more than one image cube."
    print(return_files[0], end="")


if __name__ == "__main__":
    main(sys.argv[1:])
