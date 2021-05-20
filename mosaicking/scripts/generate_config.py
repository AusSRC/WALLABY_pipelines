#!/usr/bin/env python3
"""Create a linmos configuration file from the image cubes and
weights downloaded from CASDA.

"""

import sys
import argparse


CONFIG = """
linmos.names        = $CUBES
linmos.weights      = $WEIGHTS
linmos.imagetype    = fits
linmos.outname      = $OUTFILE
linmos.outweight    = weights.$OUTFILE
linmos.weighttype   = FromWeightImages
linmos.weightstate  = Corrected
linmos.psfref       = 0
""".strip()


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--input",
        type=str,
        required=True,
        help="Input file names for CASDA image cubes.",
    )
    parser.add_argument(
        "-f",
        "--filename",
        type=str,
        required=True,
        help="Output filename and directory for mosiacked image cubes.",
    )
    parser.add_argument(
        "-c",
        "--config",
        type=str,
        required=True,
        help="Filename and path for linmos configuration.",
    )
    parser.add_argument(
        "-t",
        "--config_template",
        type=str,
        required=False,
        help="Template configuration file content (string).",
        default=CONFIG
    )
    args = parser.parse_args(argv)
    return args


def write_file(filename, content):
    """Wrapping file writing in function for testing purposes.

    """
    with open(filename, 'w') as f:
        f.writelines(content)


def main(argv):
    args = parse_args(argv)

    cubes = args.input.replace('.fits', '')
    weights = cubes\
        .replace('image.restored', 'weights')\
        .replace('.contsub', '')

    content = args.config_template\
        .replace('$CUBES', cubes)\
        .replace('$WEIGHTS', weights)\
        .replace('$OUTFILE', args.filename)

    write_file(args.config, content)
    print(args.config, end='')


if __name__ == "__main__":
    main(sys.argv[1:])
