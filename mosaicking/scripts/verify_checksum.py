#!/usr/bin/env python3
"""Calculate checksum for a CASDA image cube. Code adapted from:
https://github.com/csiro-rds/casda_data_access/blob/master/script/calc_checksum.sh

"""

import sys
import binascii
import hashlib


def main():
    crc = None
    sha1 = hashlib.sha1()
    fsize = 0x00000000

    chunksize = 65536

    with open(sys.argv[1], "rb") as fin:
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

    # Makes the assumption that a checksum file will be downloaded
    # automatically alongside an image cube from OPAL
    with open(f"{sys.argv[1]}.checksum", "r") as fin:
        compare_checksum = fin.read()
        equal = (compare_checksum == checksum)

        if equal:
            # return input file (for nextflow workflow composition)
            sys.stdout.write(sys.argv[1])
            return
        else:
            return


if __name__ == "__main__":
    main()
