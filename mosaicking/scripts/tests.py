#!/usr/bin/env python3
import sys
import io
import unittest
from unittest.mock import patch

import download
import generate_config


class Testing(unittest.TestCase):
    """Testing suite for WALLABY workflow scripts"""

    @patch("download.download", lambda *_: ["hello", "hello.checksum"])
    def test_download(self):
        """Ensure download.py process returns a single
        output that is the file that has been downloaded.

        """
        output = io.StringIO()
        sys.stdout = output

        download.main(["-i", "10809", "-o", "outputs", "-c", "../credentials.ini"])
        sys.stdout = sys.__stdout__

        self.assertEqual(
            output.getvalue(), "hello", f"Output was {repr(output.getvalue())}"
        )

    def test_generate_config(self):
        """Test that generate_config.py takes a list of arguments
        (sbids) and returns the correct config file.

        """
        files = "[image.restored.SB100.cube.contsub.fits,image.restored.SB200.cube.contsub.fits]"
        generate_config.main(['-i', files, '-o', 'output', '-f', 'filename.config'])


if __name__ == "__main__":
    unittest.main()