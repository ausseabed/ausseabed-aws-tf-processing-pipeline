import re

from product_catalogue_py_rest_client.models import ProductL3Dist, ProductL3Src, RelationSummaryDto, Survey
from product_database import ProductDatabase
import logging


class SrcDistName():

    S3DIFFICULT_CHARS = """[`\\^><}{\][#%\"\'~|&@:,$=+?; ]"""

    def __init__(self, product_database: ProductDatabase, product_l3_src: ProductL3Src, bucket_name: str, identifier: str):
        self.product_l3_src = product_l3_src
        self.s3_src_tif = product_l3_src.product_tif_location

        simple_name = product_database.get_name_for_product_src(
            product_l3_src, "{0}")

        logging.info(product_l3_src.name)
        logging.info(simple_name)
        v_datum = product_l3_src.vertical_datum
        if (v_datum == 'WGS84'):
            v_datum_code = 'Ellipsoid'
        elif (v_datum == 'LMSL'):
            v_datum_code = 'MSL'
        else:
            v_datum_code = v_datum

        product_name = re.sub(str(self.S3DIFFICULT_CHARS),
                              "_", simple_name) + "_" + v_datum_code

        self.s3_dest_tif = "s3://" + bucket_name + "/L3/" + \
            identifier + "/" + product_name + "_cog.tif"
        self.s3_dest_shp = "s3://" + bucket_name + "/L3/" + \
            identifier + "/" + product_name + ".shp"
        self.s3_hillshade_dest_tif = "s3://" + bucket_name + \
            "/L3/" + identifier + "/" + product_name + "_hs.tif"
