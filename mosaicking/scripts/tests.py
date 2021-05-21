#!/usr/bin/env python3

import os
import sys
import io
import configparser
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
linmos.outweight    = mosaicked.weights
linmos.weighttype   = FromWeightImages
linmos.weightstate  = Corrected
linmos.psfref       = 0
""".strip()  # noqa
EXPECTED_CONFIG_FILE_PATH = """
linmos.names        = [/mnt/shared/image.restored.SB100.cube.contsub,/mnt/shared/image.restored.SB200.cube.contsub]
linmos.weights      = [/mnt/shared/weights.SB100.cube,/mnt/shared/weights.SB200.cube]
linmos.imagetype    = fits
linmos.outname      = /mnt/shared/mosaicked
linmos.outweight    = /mnt/shared/mosaicked.weights
linmos.weighttype   = FromWeightImages
linmos.weightstate  = Corrected
linmos.psfref       = 0
""".strip()  # noqa


class Testing(unittest.TestCase):
    """Testing suite for WALLABY workflow scripts

    """
    def setUp(self):
        """Set credentials as environment variables for
        local and remote testing.

        """
        creds = "../credentials.ini"
        if os.path.isfile(creds):
            config = configparser.ConfigParser()
            config.read(creds)
            login = config["login"]
            os.environ["CASDA_USERNAME"] = login['username']
            os.environ["CASDA_PASSWORD"] = login['password']

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

        download.main(["-i", "10809", "-o", "mosaicked"])
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

    def test_generate_config_with_file_path(self):
        """Test that generate_config.py takes a list of arguments
        (sbids) and returns the correct config file. Ensure that when the file
        path is provided for the image cubes, the correct weight file is
        created.

        Asserts three things:
            1. Config file is generated
            2. Content of the configuration file is as expected
            3. Output (stdout) is the configuration filename.

        """
        output = io.StringIO()
        sys.stdout = output

        files = "[/mnt/shared/image.restored.SB100.cube.contsub.fits,/mnt/shared/image.restored.SB200.cube.contsub.fits]"  # noqa
        generate_config.main(["-i", files, "-f", "/mnt/shared/mosaicked", "-c", TMP_FILE])  # noqa

        # 1. Config generated
        self.assertTrue(os.path.isfile(TMP_FILE))

        # 2. Config content
        with open(TMP_FILE, 'r') as f:
            content = f.read().strip()
        self.assertEqual(content, EXPECTED_CONFIG_FILE_PATH)

        # 3. Stdout
        sys.stdout = sys.__stdout__
        self.assertEqual(
            output.getvalue(), TMP_FILE, f"Output was {repr(output.getvalue())}"  # noqa
        )


if __name__ == "__main__":
    unittest.main()
