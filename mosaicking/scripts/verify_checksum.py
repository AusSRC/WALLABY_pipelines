#!/usr/bin/env python3
"""Calculate checksum for a CASDA image cube. Code adapted from:
https://github.com/csiro-rds/casda_data_access/blob/master/script/calc_checksum.sh

Makes the assumption that a checksum file will be downloaded
automatically alongside an image cube from OPAL.
Will replace 'image.restored' with 'weights' and remove '.contsub' substring
to get the weights filename from the cube.

"""

import sys
import binascii
import hashlib


def calculate_checksum(filename):
    crc = None
    sha1 = hashlib.sha1()
    fsize = 0x00000000

    chunksize = 65536

    with open(filename, "rb") as fin:
        while True:
            chunk = fin.read(chunksize)
            if chunk:
                if crc is None:
                    crc = binascii.crc32(chunk)
                else:
                    crc = binascii.crc32(chunk, crc)
                sha1.update(chunk)
                fsize += len(chunk)
            else:
                break

    if crc is None:
        crc = 0

    fin.close()

    if crc < 0:
        crc = crc + (1 << 32)

    # Adapted code here to calculate the checksum and return input filename
    # if checksum comparison passes
    checksum = format(crc, '08x') + " " + sha1.hexdigest() + " " + format(fsize, 'x')  # noqa
    return checksum


def main():
    """Perform checksum comparison for image cube and weight
    files downloaded from CASDA.

    First checks weights checksum. If not equal then will exit (failure).
    Then check cube checksum. If not equal 

    """
    cube_filename = sys.argv[1]
    weights_filename = cube_filename\
        .replace('image.restored', 'weights')\
        .replace('.contsub', '')

    weights_checksum = calculate_checksum(weights_filename)
    with open(f"{weights_filename}.checksum", "r") as fin:
        compare_checksum = fin.read()
        equal = (compare_checksum == checksum)
        if not equal:
            raise ValueError("Checksum does not agree.")

    cube_checksum = calculate_checksum(cube_filename)
    with open(f"{cube_filename}.checksum", "r") as fin:
        compare_checksum = fin.read()
        equal = (compare_checksum == checksum)
        if equal:
            sys.stdout.write(cube_filename)
        else:
            raise ValueError("Checksum does not agree.")


if __name__ == '__main__':
    main()