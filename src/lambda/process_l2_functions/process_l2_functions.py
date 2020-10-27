import json
import argparse
import re
import uuid
import logging
from time import sleep

from datetime import datetime, timezone
from datetime import timedelta

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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
        output = startEc2Action(event)
    elif (event["action"] == "run-script"):
        output = runScriptAction(event)

    elif (event["action"] == "stop-ec2"):
        output = stopEc2Action(event)

    return {
        'statusCode': 200,
        'body': output
    }


def startEc2Action(event):
    logging.info('Starting EC2 machine')
    instance_id = event["instance-id"]
    try:
        responses = client.start_instances(
            InstanceIds=[instance_id],
            DryRun=True  # Make it False to test
        )
        logging.info(responses)
    except Exception as e:
        logging.exception(e)

    output = "Success"
    return output


def runScriptAction(event):
    # event["bucket"], event["uuid"])
    output = "Success"
    return output


def stopEc2Action(event):
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
