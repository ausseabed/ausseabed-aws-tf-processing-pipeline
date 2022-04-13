import logging
import sys
import unittest

from identify_unprocessed_grids import extract_resolution_text

logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)


class IdentifyUnprocessedGridsTest(unittest.TestCase):
    def test_extract_resolution_text(self):
        self.assertEqual('20m', extract_resolution_text(['20m']))
        self.assertEqual('0.5m - 2m', extract_resolution_text(['0.5m', '2m']))
        self.assertEqual('5m - 8m', extract_resolution_text(['5m - 8m']))
        self.assertEqual('20m - 100m', extract_resolution_text(['20m', '30m', '50m', '100m']))
        self.assertEqual('0.5m - 50m', extract_resolution_text(['50m', '0.5m - 20m', '2m']))
