# python/stop_ec2_instances.py

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
    AWS Lambda handler function to stop EC2 instances.
    It identifies instances by a specific tag and state.
    """
    print("--- Stopping EC2 instances process initiated ---")
    print(f"Looking for instances with tag '{TAG_KEY}':'{TAG_VALUE}'")

    # Define filters to find instances that are 'running' AND have the specific tag.
    filters = [
        {'Name': 'instance-state-name', 'Values': ['running']},
        {'Name': f'tag:{TAG_KEY}', 'Values': [TAG_VALUE]}
    ]

    instances_to_stop = []
    try:
        # Describe instances based on the defined filters.
        response = ec2.describe_instances(Filters=filters)

        # Extract instance IDs from the response.
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                # IMPORTANT: In a real-world scenario, you might add more sophisticated
                # checks here, e.g., to exclude instances part of an Auto Scaling Group,
                # or instances with specific 'DoNotStop' tags. For this lab, we'll
                # stop any running instance with the 'AutoSchedule: True' tag.
                instances_to_stop.append(instance['InstanceId'])

        if instances_to_stop:
            print(f"Found {len(instances_to_stop)} instances to stop: {instances_to_stop}")
            # Stop the identified instances.
            ec2.stop_instances(InstanceIds=instances_to_stop)
            print("Successfully sent stop command to EC2 instances.")
        else:
            print("No running instances found with the specified tag for stopping.")

    except Exception as e:
        print(f"Error stopping EC2 instances: {e}")
        # Log the error. In a production system, consider sending a notification.
        return {
            'statusCode': 500,
            'body': f"Error stopping EC2 instance: {str(e)}"
        }

    print("--- EC2 instances stop process completed ---")
    return {
        'statusCode': 200,
        'body': 'EC2 instance stop process completed.'
    }

