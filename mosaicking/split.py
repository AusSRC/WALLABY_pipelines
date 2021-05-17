#!/usr/bin/env python3

import sys
from astropy.io import fits


def main():
    filename = str(sys.argv[1])
    # nChannels = int(sys.argv[2])

    with fits.open(filename, memmap=True) as hdul:
        hdul.info()
        print(hdul[0].data)


if __name__ == '__main__':
    main()
