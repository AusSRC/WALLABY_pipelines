#!/usr/bin/env python3
"""Create a SoFiA-2 configuration file based on key word arguments.
Mosaicked image cube and output configuration filename are passed in
as named arguments.
Parameter values are passed as keyword arguments.

"""

import sys
import argparse
import configparser
from jinja2 import Template


class ParseKwargs(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, dict())
        for value in values:
            key, value = value.split('=')
            getattr(namespace, self.dest)[key] = value


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--input",
        type=str,
        required=True,
        help="Input file for mosaicked image cube.",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        required=True,
        help="Output filename and path for sofia parameter file.",
    )
    parser.add_argument(
        "-t",
        "--template",
        type=str,
        required=True,
        help="SoFiA parameter file template",
        default="sofia.j2"
    )
    parser.add_argument(
        "-d",
        "--defaults",
        type=str,
        required=True,
        help="SoFiA parameter file default values",
    )
    parser.add_argument(
        '-p',
        '--params',
        nargs='*',
        help="Values for SoFiA parameters",
        required=False,
        action=ParseKwargs,
        default=None
    )
    args = parser.parse_args(argv)
    return args


def read_defaults(f):
    """Read default values from a config parser.

    """
    config = configparser.RawConfigParser()
    config.optionxform = str
    config.read(f)
    return dict(config.items("DEFAULT"))


def main(argv):
    # Get arguments
    args = parse_args(argv)
    output = args.output.rsplit('/', 1)
    if len(output) == 1:
        io = {
            'SOFIA_INPUT_DATA': args.input,
            'SOFIA_OUTPUT_FILENAME': output[0],
        }
    else:
        io = {
            'SOFIA_INPUT_DATA': args.input,
            'SOFIA_OUTPUT_DIRECTORY': output[0],
            'SOFIA_OUTPUT_FILENAME': output[1],
        }

    # Get sofia parameter file template
    with open(args.template, 'r') as f:
        template = Template(f.read())

    # Get default values
    defaults = read_defaults(args.defaults)

    # Update template with parameters
    if args.params is not None:
        params = {**defaults, **args.params}
        params = {**params, **io}
    else:
        params = {**defaults, **io}
    config = template.render(params)

    # Write output and print file
    with open(args.output, 'w') as f:
        f.writelines(config)
    print(args.output, end="")


if __name__ == "__main__":
    main(sys.argv[1:])
