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
        output = start_ec2_action(event)

    elif (event["action"] == "run-script"):
        output = run_script_action(event)

    elif (event["action"] == "continue"):
        output = continue_pipeline(event)

    elif (event["action"] == "stop-ec2"):
        output = stop_ec2_action(event)

    return {
        'statusCode': 200,
        'body': output
    }


def chunks(l, n):
    """Yield n number of sequential chunks from l."""
    d, r = divmod(len(l), n)
    for i in range(n):
        si = (d+1)*(i if i < r else r) + d*(0 if i < r else i - r)
        yield l[si:si+(d+1 if i < r else d)]


def set_caris_machine_tag(instance_id, continue_token):

    reservations = client.describe_instances(
        Filters=[
            {
                'Name': 'instance-id',
                'Values': [
                    instance_id
                ]
            }
        ]
    )["Reservations"]

    # tokens can be up to 1024 chars
    # tags are limited to 256 chars...
    chunked_token = list(chunks(continue_token, 4))

    for reservation in reservations:
        for each_instance in reservation["Instances"]:
            client.create_tags(
                Resources=[each_instance["InstanceId"]],
                Tags=[
                    {"Key": "Token_Part_1", "Value": chunked_token[0]},
                    {"Key": "Token_Part_2", "Value": chunked_token[1]},
                    {"Key": "Token_Part_3", "Value": chunked_token[2]},
                    {"Key": "Token_Part_4", "Value": chunked_token[3]}
                ]
            )


def step_function_continue(token, result):
    try:
        sf_client = boto3.client('stepfunctions', 'ap-southeast-2')
        sf_client.send_task_success(taskToken=token, output=json.dumps(result))
        logging.info("sending success back to step function")
    except Exception as e:
        logging.error(
            "did not send success to step function: {0}".format(str(e)))


def start_ec2_action(event):
    logging.info('Starting EC2 machine')
    instance_id = event["instance-id"]
    try:
        responses = client.start_instances(
            InstanceIds=[instance_id],
            DryRun=False  # Make it True to get authentication errors
        )
        logging.info(responses)

        token = event['token']

        if (responses['StartingInstances'][0]['CurrentState']['Name'] == 'running'):
            logging.info('currently running')
            step_function_continue(token, {"result": "Success"})
        else:
            logging.info('machine starting')
            logging.info("Once the machine has started. Continue the workflow by running the lambda function \
ga_sb_default-process-l2-functions with: \n{\naction='continue',\ntoken=" + token + "\n}")

            set_caris_machine_tag(instance_id, token)

    except Exception as e:
        logging.exception(e)

    output = {"result": "Success"}
    return output


def continue_pipeline(event):
    logging.info('Testing to see if we can  signals to continue pipeline')

    token = event['token']
    try:
        logging.info('currently running')
        step_function_continue(token, {"result": "Success"})

    except Exception as e:
        logging.exception(e)

    output = {"result": "Success"}
    return output


def run_script_action(event):
    # event["bucket"], event["uuid"])
    output = {"result": "Success"}
    return output


def stop_ec2_action(event):
    # event["bucket"], event["uuid"])
    logging.info('Stopping EC2 machine')
    instance_id = event["instance-id"]
    try:
        response = client.stop_instances(
            InstanceIds=[instance_id],
            DryRun=False  # Make it True to get authentication errors
        )
        logging.info(response)
    except Exception as e:
        logging.exception(e)

    output = {"result": "Success"}
    return output


# Main is only called when testing/debugging
if __name__ == "__main__":
    logging.info("Starting")
    event = {}
    context = {}
    event["action"] = "start-ec2"
    event["bucket"] = "ausseabed-public-bathymetry-nonprod"
    lambda_handler(event, context)
