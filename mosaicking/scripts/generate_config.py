#!/usr/bin/env python3
"""Create a linmos configuration file from the image cubes and
weights downloaded from CASDA.

"""

CONFIG_FILE = "linmos.config"


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-l", "--list", type=int, required=True, help="Input observing block number."
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


def main(argv):
    args = parse_args(argv)


if __name__ == "__main__":
    main(sys.argv[1:])
