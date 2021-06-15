#!/usr/bin/env python3
"""Update database credentials in the config.ini file for SoFiAX execution

"""

import os
import sys
import argparse
import configparser


def parse_args(argv):
    """Accept database configuration as arguments.

    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--config",
        type=str,
        required=True,
        help="Path to SoFiAX configuration file"
    )
    parser.add_argument(
        "--host",
        type=str,
        required=True,
        help="Database host address"
    )
    parser.add_argument(
        "--name",
        type=str,
        required=True,
        help="Database name"
    )
    parser.add_argument(
        "--username",
        type=str,
        required=True,
        help="Database user"
    )
    parser.add_argument(
        "--password",
        type=str,
        required=True,
        help="Database password"
    )
    args = parser.parse_args(argv)
    return args


def main(argv):
    # get args
    args = parse_args(argv)

    # config file update
    config = configparser.RawConfigParser()
    config.optionxform = str
    config.read(args.config)
    config.set('SoFiAX', 'db_hostname', args.host)
    config.set('SoFiAX', 'db_name', args.name)
    config.set('SoFiAX', 'db_username', args.username)
    config.set('SoFiAX', 'db_password', args.password)

    # write
    with open(args.config, 'w') as f:
        config.write(f)


if __name__ == "__main__":
    main(sys.argv[1:])
