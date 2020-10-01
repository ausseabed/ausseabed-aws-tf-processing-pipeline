
import logging

from product_catalogue_py_rest_client.models import ProductL3Dist, ProductL3Src, RelationSummaryDto, Survey
from product_database import ProductDatabase

import json
import re
import uuid

from src_dist_name import SrcDistName


class StepFunctionAction():

    def __init__(self, product_l3_src: ProductL3Src, src_dist_name: SrcDistName, uuid_ref):
        self.product_l3_src = product_l3_src
        self.src_dist_name = src_dist_name
        self.srs_mapping = self.buildSrsMapping()
        self.uuid_ref = uuid_ref

    def buildSrsMapping(self):
        with open('reference-system.json') as f:
            d = json.load(f)
            return(d['Results'])

    def run_step_function(self):

        srs_matches = [match for match in self.srs_mapping if 'EPSG:' +
                       str(match['Code']) == self.product_l3_src.srs]

        if (len(srs_matches) == 0):
            multiplier = 1
            logging.info('No srs found for ' + self.product_l3_src.name)
        else:
            srs_match = srs_matches[0]
            srs_type = srs_match['Type']
            logging.info('SRS found (' + srs_type + ') for ' +
                         self.product_l3_src.name)
            if (srs_type.startswith('geog')):
                logging.info('Geographic type')
                multiplier = 111120
            else:
                logging.info('Projected type')
                multiplier = 1

        json_instruction = {'s3_src_tif': self.src_dist_name.s3_src_tif,
                            's3_dest_tif': self.src_dist_name.s3_dest_tif,
                            's3_dest_shp': self.src_dist_name.s3_dest_shp,
                            's3_hillshade_dest_tif': self.src_dist_name.s3_hillshade_dest_tif,
                            's3_scaling_factor': str(multiplier),
                            'uuid': self.uuid_ref
                            }
        return json_instruction
