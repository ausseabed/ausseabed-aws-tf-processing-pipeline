import json
import argparse
import re
import uuid
import logging
from time import sleep

from pythonjsonlogger import jsonlogger
from datetime import datetime, timezone
from datetime import timedelta

import boto3

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
lambda handler is the entry point for functions of the L2 Processing Pipeline

A series of functions is bundled into one entry point to reduce the amount of 
terraform code that is necessary to orchestrate and manage the workflow.

The actions that are handled include:
- start ec2 instance
- run script
- stop ec2 instance
"""

client = boto3.client(
    'ec2', region_name='ap-southeast-2')  # Add your region


def lambda_handler(event, context):
    logging.info("Running the envent handler")
    logging.debug(event)
    logging.debug(context)

    logging.info(event["action"])

    if (event["action"] == "start-ec2"):
        output = startEc2Action()
    elif (event["action"] == "run-script"):
        output = runScriptAction()

    elif (event["action"] == "stop-ec2"):
        output = stopEc2Action()

    return {
        'statusCode': 200,
        'body': output
    }


def startEc2Action():
    logging.info('Starting EC2 machine')
    instance_id = event["instance-id"]
    try:
        responses = client.start_instances(
            InstanceIds=[instance_id],
            DryRun=True  # Make it False to test
        )
    except Exception as e:
        logging.exception(e)

    logging.info(responses)
    output = "Success"
    return output


def runScriptAction():
    # event["bucket"], event["uuid"])
    output = "Success"
    return output


def stopEc2Action():
    # event["bucket"], event["uuid"])
    logging.info('Stopping EC2 machine')
    instance_id = event["instance-id"]
    try:
        response = client.stop_instances(
            InstanceIds=[instance_id],
            DryRun=True  # Make it False to test
        )
        logging.info(response)
    except Exception as e:
        logging.exception(e)

    output = "Success"
    return output


# Main is only called when testing/debugging
if __name__ == "__main__":
    logging.info("Starting")
    event = {}
    context = {}
    event["action"] = "start-ec2"
    event["bucket"] = "ausseabed-public-bathymetry-nonprod"
    lambda_handler(event, context)
