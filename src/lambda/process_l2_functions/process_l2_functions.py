import json
import argparse
import re
import uuid
import logging
from time import sleep
from urllib.parse import urlparse

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
    client = boto3.client(
        'ec2', region_name='ap-southeast-2')  # Add your region

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
    client = boto3.client(
        'ec2', region_name='ap-southeast-2')  # Add your region
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
    target_script_name = event["target-location"] + \
        event["uuid"] + "/" + "process_L2_recipe.ps1"

    local_script_name = event["working-directory-root"] + \
        event["uuid"] + "\\" + "process_L2_recipe.ps1"

    local_script_caller_name = event["working-directory-root"] + \
        event["uuid"] + "\\" + "process_L2_recipe_caller.ps1"

    copy_recipe(event, target_script_name)
    logging.info('Running script using SSM')
    ssm = boto3.client(
        'ssm', region_name='ap-southeast-2')  # Add your region
    instance_id = event["instance-id"]

    # args = {
    #     "L2_GSF_Location": 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/transit/FK200930/EM320_L2/',
    #     "UUID": '125d8c3b-1e07-4652-a01a-cb3d3aef880a',
    #     "Product_Name": 'Great_Barrier_Reef_Cape_York_2020',
    #     "Vessel_File": 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/Vessel Files/RV_Falkor_EM302.hvf',
    #     "Target_Location": 's3://ausseabed-public-warehouse-bathymetry/L2/',
    #     "License_Server": '172.31.23.28',
    #     "Depth_Ranges_File": 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/depth_ranges.txt',
    #     "Cube_Config_File": 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/CUBEParams_AusSeabed_2019.xml',
    #     "Completion_Token": 'xxyy',
    #     "S3_Account_Canonical_Id": '4442572c4082cf5ca3abf21157b0db95bab63d0b312e6cf82f3d58a95405762e',
    #     "MSL_Reference": 's3://ausseabed-public-bathymetry/Clearing House/Geoscience Australia/s45e135inv.asc',
    #     "Resolution": '64m',
    #     "Working_Directory_Root": 'D:\\'
    # }

    args = {
        "L2_GSF_Location": event['l2-gsf-location'],
        "UUID": event['uuid'],
        "Product_Name": event['product-name'],
        "Vessel_File": event['vessel-file'],
        "Target_Location": event['target-location'],
        "License_Server": event['license-server'],
        "Depth_Ranges_File": event['depth-ranges-file'],
        "Cube_Config_File": event['cube-config-file'],
        "Completion_Token": event['token'],
        "S3_Account_Canonical_Id": event['s3_account_canonical_id'],
        "MSL_Reference": event['MSL-reference'],
        "Resolution": event['resolution'],
        "Working_Directory_Root": event['working-directory-root']
    }

    execute_command = 'echo "& `"' + local_script_name + '`" ' + \
        " ".join(['-{0} `"{1}`"'.format(key, value)
                  for (key, value) in args.items()]) + '" | Out-File "' + local_script_caller_name + '"'

    # Can't pass long strings through to powershell...
    # https://stackoverflow.com/questions/40521809/what-is-the-maximum-length-of-the-argumentlist-parameter-of-the-start-process-c
    # command_string = 'Start-Process powershell.exe -Credential $credential -ArgumentList "`"' + local_script_name + '`" ' + \
    #     " ".join(['`"-{0}`" `"\'{1}\'`"'.format(key, value)
    #               for (key, value) in args.items()]) + '"'

    command_string = 'Invoke-Command -Session $session -File "' + \
        local_script_caller_name + '"'

    with open('switch_user.ps1', 'r') as content_file:
        switch_user_cmds = content_file.read()

    logging.info(execute_command)
    logging.info(command_string)
    try:
        responses = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunPowerShellScript",
            Parameters={'commands': ['echo starting script',
                                     switch_user_cmds,
                                     "aws s3 cp '" + target_script_name + "' '" + local_script_name + "'",
                                     execute_command,
                                     command_string]},
            CloudWatchOutputConfig={
                'CloudWatchLogGroupName': event["log-stream"],
                'CloudWatchOutputEnabled': True
            }
        )
        logging.info(responses)

    except Exception as e:
        logging.exception(e)

    output = {"result": "Success"}
    return output


def copy_recipe(event, target_name):
    logging.info('Copying recipe to S3')
    # aws s3 cp process_L2_recipe.ps1 event["target-location"] + event["uuid"] + "/"  --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers full=id="$S3_Account_Canonical_Id"

    s3 = boto3.resource('s3')
    target_url = urlparse(target_name)

    bucket = target_url.netloc
    key = target_url.path.lstrip('/')
    logging.info('Bucket = ' + bucket)
    logging.info('Key = ' + key)

    s3.Bucket(bucket).upload_file("process_L2_recipe.ps1", key,
                                  ExtraArgs={
                                      'GrantRead': 'uri="http://acs.amazonaws.com/groups/global/AllUsers"',
                                      'GrantFullControl': 'id="' + event["s3_account_canonical_id"] + '"'
                                  })


def stop_ec2_action(event):
    # event["bucket"], event["uuid"])
    logging.info('Stopping EC2 machine')
    client = boto3.client(
        'ec2', region_name='ap-southeast-2')  # Add your region
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
    event["action"] = "run-script"
    event["instance-id"] = "i-0d155b389909dd45d"
    event["target-location"] = 's3://ausseabed-public-warehouse-bathymetry/L2/'
    event["uuid"] = '125d8c3b-1e07-4652-a01a-cb3d3aef880b'
    event["s3_account_canonical_id"] = "4442572c4082cf5ca3abf21157b0db95bab63d0b312e6cf82f3d58a95405762e"

    lambda_handler(event, context)
