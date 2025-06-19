import boto3
import json

# Connect to EC2 resource using AWS credentials
ec2 = boto3.resource('ec2')
def get_instances_without_tag():
    # Define filter for instances without ansiblegrp tag
    instances_without_ansiblegrptag = []
    for instance in ec2.instances.all():
        if 'ansiblegrp' not in (tag['Key'] for tag in instance.tags):
            instances_without_ansiblegrptag.append(instance)
    return instances_without_ansiblegrptag

