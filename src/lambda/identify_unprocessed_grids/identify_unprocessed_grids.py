import json
import argparse
import re
import uuid
import logging
from get_secrets import get_secret
from auth_broker import AuthBroker
from product_database import ProductDatabase
from product_catalogue_py_rest_client.models import ProductL3Dist, ProductL3Src, SurveyL3Relation, Survey
from time import sleep
from update_database_action import UpdateDatabaseAction

from src_dist_name import SrcDistName
from pythonjsonlogger import jsonlogger
from step_function_action import StepFunctionAction
from datetime import datetime, timezone
from datetime import timedelta
logger = logging.getLogger()

# Testing showed lambda sets up one default handler. If there are more,
# something has changed and we want to fail so an operator can investigate.
assert len(logger.handlers) == 1

logger.setLevel(logging.INFO)
json_handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter(
    fmt='%(asctime)s %(levelname)s %(name)s %(message)s'
)
json_handler.setFormatter(formatter)
logger.addHandler(json_handler)
logger.removeHandler(logger.handlers[0])

"""
lambda handler is the entry point for functions of the L3 Processing Pipeline

A series of functions is bundled into one entry point to reduce the amount of 
terraform code that is necessary to orchestrate and manage the workflow.

The actions that are handled include:
- parse-arn (a small regex for turning a task-arn into link to a details tab)
- list - list all the products that are yet to be processed and create a map index
- select - select one product for processing from a map index
- save - save details about the processed product to the product catalogue

"""


def lambda_handler(event, context):
    logging.info("Running the envent handler")
    logging.debug(event)
    logging.debug(context)

    logging.info(event["action"])

    if (event["action"] == "parse-arn"):
        task_id = re.sub(".*\/", "", event["task-arn"])
        return {
            'statusCode': 200,
            'body': {
                'task-arn': event["task-arn"],
                'ecs-describe-page': event["parse-string"].format(task_id)
            }
        }

    logging.info(event["cat-url"])
    warehouse_connection_json = json.loads(get_secret("wh-infra.auto.tfvars"))

    auth = AuthBroker(warehouse_connection_json)
    token = auth.get_auth_token()

    product_database = ProductDatabase(token, event["cat-url"])
    product_database.download_from_rest()

    # connect to database
    # download stuff
    # return pointers to stuff
    if (event["action"] == "list"):
        logging.info("Found {} source products".format(len(
            [product.id for product in product_database.l3_src_products])))

        logging.info("Found {} products that have been processed".format(len(
            [product.source_product.id for product in product_database.l3_dist_products])))

        processed_product_ids = [product.source_product.id
                                 for product in product_database.l3_dist_products]

        unprocessed_products = [
            product for product in product_database.l3_src_products if product.id not in processed_product_ids
        ]

        logging.info("Planning on processing {} products".format(
            len(unprocessed_products)))

        logging.info("Planning on processing: {}".format(" \n".join(
            [product.name for product in unprocessed_products])))

        output = {"product-ids":
                  [{"product-id": product.id,
                    "uuid": product_uuid,
                    "cat-url": event["cat-url"],
                    "bucket": event["bucket"],
                    "build-name": re.sub("[^a-zA-Z0-9]", "_", product.name)[0:39] + "_" + product_uuid,
                    "est": (datetime.utcnow() +
                            timedelta(
                        seconds=unprocessed_products.index(product)*10)
                    ).isoformat('T', timespec='seconds') + 'Z'}
                   for (product, product_uuid) in
                   [(product, str(uuid.uuid4()))
                    for product in unprocessed_products
                    ]
                   ],
                  "proceed": event["proceed"]
                  }
    elif (event["action"] == "select"):
        selected_products = [
            product for product in product_database.l3_src_products if product.id == event["product-id"]]

        if (len(selected_products) == 0):
            msg = "No product for id " + str(event["product-id"])
            logging.error(msg)
            return {
                'statusCode': 400,
                'body': msg
            }

        selected_product = selected_products[0]
        logging.info("Planning on processing: {}".format(
            selected_product.name))

        names = SrcDistName(product_database, selected_product,
                            event["bucket"], event["uuid"])
        step_function_action = StepFunctionAction(
            selected_product, names, event["uuid"])
        json_output = step_function_action.run_step_function()

        output = {**event, **json_output}

    elif (event["action"] == "save"):
        selected_products = [
            product for product in product_database.l3_src_products if product.id == event["product-id"]]

        if (len(selected_products) == 0):
            msg = "No product for id " + str(event["product-id"])
            logging.error(msg)
            return {
                'statusCode': 400,
                'body': msg
            }

        selected_product = selected_products[0]
        logging.info("Planning on processing: {}".format(
            selected_product.name))

        names = SrcDistName(product_database, selected_product,
                            event["bucket"], event["uuid"])
        update_database_action = UpdateDatabaseAction(
            selected_product, event["cat-url"], token, names)
        update_database_action.update()
        output = "Success"

    return {
        'statusCode': 200,
        'body': output
    }


# Main is only called when testing/debugging
if __name__ == "__main__":
    logging.info("Starting")
    event = {}
    context = {}
    # event["action"] = "list"
    # event["action"] = "select"
    event["action"] = "save"
    event["product-id"] = 99
    event["cat-url"] = "https://catalogue.dev.ausseabed.gov.au/rest"
    event["uuid"] = "123"
    event["bucket"] = "ausseabed-public-bathymetry-nonprod"
    lambda_handler(event, context)
