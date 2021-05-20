#!/usr/bin/env python3

import os
import sys
import io
import unittest
from unittest.mock import patch

import download
import generate_config


TMP_FILE = "filename.config"
EXPECTED_CONFIG = """
linmos.names        = [image.restored.SB100.cube.contsub,image.restored.SB200.cube.contsub]
linmos.weights      = [weights.SB100.cube,weights.SB200.cube]
linmos.imagetype    = fits
linmos.outname      = mosaicked
linmos.outweight    = weights.mosaicked
linmos.weighttype   = FromWeightImages
linmos.weightstate  = Corrected
linmos.psfref       = 0
""".strip()  # noqa


class Testing(unittest.TestCase):
    """Testing suite for WALLABY workflow scripts"""
    def tearDown(self):
        if os.path.isfile(TMP_FILE):
            os.remove(TMP_FILE)

    @patch("download.download", lambda *_: ["hello", "hello.checksum"])
    def test_download(self):
        """Ensure download.py process returns a single
        output that is the file that has been downloaded.

        """
        output = io.StringIO()
        sys.stdout = output

        download.main(["-i", "10809", "-o", "mosaicked", "-c", "../credentials.ini"])  # noqa
        sys.stdout = sys.__stdout__

        self.assertEqual(
            output.getvalue(), "hello", f"Output was {repr(output.getvalue())}"
        )

    def test_generate_config(self):
        """Test that generate_config.py takes a list of arguments
        (sbids) and returns the correct config file.

        Asserts three things:
            1. Config file is generated
            2. Content of the configuration file is as expected
            3. Output (stdout) is the configuration filename.

        """
        output = io.StringIO()
        sys.stdout = output

        files = "[image.restored.SB100.cube.contsub.fits,image.restored.SB200.cube.contsub.fits]"  # noqa
        generate_config.main(["-i", files, "-f", "mosaicked", "-c", TMP_FILE])

        # 1. Config generated
        self.assertTrue(os.path.isfile(TMP_FILE))

        # 2. Config content
        with open(TMP_FILE, 'r') as f:
            content = f.read().strip()
        self.assertEqual(content, EXPECTED_CONFIG)

        # 3. Stdout
        sys.stdout = sys.__stdout__
        self.assertEqual(
            output.getvalue(), TMP_FILE, f"Output was {repr(output.getvalue())}"  # noqa
        )


if __name__ == "__main__":
    unittest.main()
