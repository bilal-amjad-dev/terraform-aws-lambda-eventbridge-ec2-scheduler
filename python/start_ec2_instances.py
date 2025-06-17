# python/start_ec2_instances.py

import boto3
import os

# Initialize the EC2 client.
# boto3 will automatically infer the region from the Lambda's configuration.
ec2 = boto3.client('ec2')

# Define the tag key and value that instances must have to be managed by this Lambda.
# These values can be overridden via Lambda environment variables in Terraform,
# but 'AutoSchedule' and 'True' are the defaults.
TAG_KEY = os.environ.get('TAG_KEY', 'AutoSchedule')
TAG_VALUE = os.environ.get('TAG_VALUE', 'True')

def lambda_handler(event, context):
    """
    AWS Lambda handler function to start EC2 instances.
    It identifies instances by a specific tag and state.
    """
    print("--- Starting EC2 instances process initiated ---")
    print(f"Looking for instances with tag '{TAG_KEY}':'{TAG_VALUE}'")

    # Define filters to find instances that are 'stopped' AND have the specific tag.
    filters = [
        {'Name': 'instance-state-name', 'Values': ['stopped']},
        {'Name': f'tag:{TAG_KEY}', 'Values': [TAG_VALUE]}
    ]

    instances_to_start = []
    try:
        # Describe instances based on the defined filters.
        response = ec2.describe_instances(Filters=filters)

        # Extract instance IDs from the response.
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances_to_start.append(instance['InstanceId'])

        if instances_to_start:
            print(f"Found {len(instances_to_start)} instances to start: {instances_to_start}")
            # Start the identified instances.
            ec2.start_instances(InstanceIds=instances_to_start)
            print("Successfully sent start command to EC2 instances.")
        else:
            print("No stopped instances found with the specified tag for starting.")

    except Exception as e:
        print(f"Error starting EC2 instances: {e}")
        # Log the error. In a production system, consider sending a notification (e.g., SNS, Slack).
        return {
            'statusCode': 500,
            'body': f"Error starting EC2 instances: {str(e)}"
        }

    print("--- EC2 instances start process completed ---")
    return {
        'statusCode': 200,
        'body': 'EC2 instance start process completed.'
    }

