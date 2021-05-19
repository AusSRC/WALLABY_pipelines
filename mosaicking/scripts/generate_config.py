#!/usr/bin/env python3
"""Create a linmos configuration file from the image cubes and
weights downloaded from CASDA.

"""

import sys
import argparse


CONFIG = """
linmos.names        = [$CUBES]\n
linmos.weights      = [$WEIGHTS]\n
linmos.imagetype    = fits\n
linmos.outname      = $OUTFILE\n
linmos.outweight    = weights.$OUTFILE\n
linmos.weighttype   = FromWeightImages\n
linmos.weightstate  = Corrected\n
linmos.psfref       = 0\n
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
        "-o",
        "--output",
        type=str,
        required=True,
        help="Output filename and directory for mosiacked image cubes.",
    )
    parser.add_argument(
        "-f",
        "--filename",
        type=str,
        required=True,
        help="Filename and directory for output config file.",
    )
    parser.add_argument(
        "-c",
        "--config_template",
        type=str,
        required=False,
        help="Template configuration file content (string).",
        default=CONFIG
    )
    args = parser.parse_args(argv)
    return args


def main(argv):
    args = parse_args(argv)

    cubes = args.input.replace('.fits', '')
    weights = cubes\
        .replace('image.restored', 'weights')\
        .replace('.contsub', '')

    content = args.config_template
    content.replace('$CUBES', cubes)\
        .replace('$WEIGHTS', weights)\
        .replace('$OUTFILE', args.output)

    # write to file
    with open(args.filename, 'w') as fout:
        fout.writelines(lines)


if __name__ == "__main__":
    main(sys.argv[1:])
