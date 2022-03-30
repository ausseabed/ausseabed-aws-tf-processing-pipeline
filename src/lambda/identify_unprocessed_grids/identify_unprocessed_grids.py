import json
import logging
import re
import uuid
from datetime import datetime
from datetime import timedelta
from os.path import basename
from urllib.parse import urlparse

import boto3
from pythonjsonlogger import jsonlogger

from auth_broker import AuthBroker
from get_secrets import get_secret
from product_database import ProductDatabase
from src_dist_name import SrcDistName
from step_function_action import StepFunctionAction
from update_database_action import UpdateDatabaseAction

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
lambda handler is the entry point for functions of the L2/3 Processing Pipeline

A series of functions is bundled into one entry point to reduce the amount of 
terraform code that is necessary to orchestrate and manage the workflow.

The actions that are handled include:
- parse-arn (a small regex for turning a task-arn into link to a details tab)
- list - list all the products that are yet to be processed and create a map index
- select - select one product for processing from a map index
- save - save details about the processed product to the product catalogue
- zip - lists all the products that need a compilation zip created/updated

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

    if event["action"] == "list":
        output = listL3Action(event, product_database)
    elif event["action"] == "select":
        output = selectL3Action(event, product_database)
    elif event["action"] == "save":
        output = saveL3Action(event, product_database, token)
    elif event['action'] == 'zip':
        output = zip_compilations(event, product_database)
    else:
        raise Exception(f'Unknown action: ${event["action"]}')

    return {
        'statusCode': 200,
        'body': output
    }

def zip_compilations(event, product_database):
    s3 = boto3.resource('s3')

    logging.info('zip_compilations invoked')
    logging.info(event)

    files_bucket = event['files-bucket']
    files_prefix = event['files-prefix']

    output = {
        'zip-files': [],
        'proceed': event['proceed']
    }

    for survey in product_database.retrieve_surveys_with_products():
        needs_update = False

        zip_filename = f'{survey["name"].strip()} - {survey["year"].strip()}.zip'
        zip_filename = re.sub(r'[\\/:*?\"<>|]', '_', zip_filename)
        manifest_filename = f'{zip_filename}.manifest'

        cogs = []
        for product in survey['products']:
            cogs.append(product.bathymetry_location)

        if not cogs:
            logging.warning('Ignoring survey with no COGs: %s', survey['id'])
            continue

        manifest = get_manifest(s3, files_bucket, files_prefix, manifest_filename)
        if manifest:
            etags = dict(map(lambda x: (x['filename'], x['eTag']), manifest))

            # If there's a mismatch in the number of files an update is required
            if len(cogs) != len(etags):
                needs_update = True
            else:
                # If the manifest filenames don't match an update is required
                manifest_filenames = set(etags.keys())
                cog_filenames = set(list(map(lambda x: basename(x), cogs)))

                if manifest_filenames != cog_filenames:
                    logging.info('Filenames in the manifest no longer match, update required')
                    logging.debug(manifest_filenames)
                    logging.debug(cog_filenames)
                    needs_update = True
                else:
                    # If any eTags have changed an update is required
                    for cog in cogs:
                        filename = basename(cog)
                        etag = get_etag(s3, cog)

                        if not etag:
                            logging.error('Failed to find an eTag for %s, the file may no longer exist', cog)
                            continue

                        if etags[filename] != etag:
                            logging.info('Manifest eTag %s does not match COG eTag %s, update required', etags[filename], etag)
                            needs_update = True
                            break
        else:
            needs_update = True

        if needs_update:
            output['zip-files'].append({
                'surveyId': survey['id'],
                'filename': zip_filename,
                'cogs': cogs
            })

    return output

def get_manifest(s3, files_bucket, files_prefix, manifest_filename):
    try:
        manifest = s3.Object(files_bucket, files_prefix + manifest_filename).get()
        return json.loads(manifest['Body'].read())
    except s3.meta.client.exceptions.NoSuchKey:
        return None

def get_etag(s3, cog):
    (bucket, key) = get_bucket_and_key(cog)

    try:
        file = s3.Object(bucket, key).get()
        return file['ETag'].strip('"')
    except s3.meta.client.exceptions.NoSuchKey:
        return None

def get_bucket_and_key(s3uri):
    url = urlparse(s3uri)
    bucket = url.netloc
    key = url.path.lstrip('/')

    return (bucket, key)

def listL3Action(event, product_database):
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
                for product in unprocessed_products]
               ],
              "proceed": event["proceed"]
              }
    return output


def selectL3Action(event, product_database):
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
    return output


def saveL3Action(event, product_database, token):
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
    return output


# Main is only called when testing/debugging
if __name__ == "__main__":
    logging.info("Starting")
    event = {}
    context = {}
    event["action"] = "zip"
    event["proceed"] = True
    # event["action"] = "select"
    # event["action"] = "save"
    # event["product-id"] = 99
    event["cat-url"] = "https://catalogue.dev.ausseabed.gov.au/rest"
    # event["uuid"] = "123"
    event["bucket"] = "ausseabed-public-bathymetry-nonprod"
    lambda_handler(event, context)
