#!/usr/bin/env python3
import sys
import io
import unittest
import download
from unittest.mock import patch


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
        pass


if __name__ == "__main__":
    unittest.main()
