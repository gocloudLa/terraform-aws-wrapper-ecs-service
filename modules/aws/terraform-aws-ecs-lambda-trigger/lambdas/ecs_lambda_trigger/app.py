import os
import json
import boto3
import subprocess

# Recover from context the name of the EventBridge
event_name = os.environ['EVENTBRIDGE_NAME']

def handler(event, context):
    
    # Create a Boto3 EventBridge client
    client_event = boto3.client('events')

    # Execute the AWS CLI command
    try:
        aws_response = client_event.list_targets_by_rule(Rule=event_name)
    except subprocess.CalledProcessError as e:
        return {
            "statusCode": 500,
            "body": f"Error executing AWS CLI command: {e.output.decode()}"
        }

    # Parse the JSON response
    try:
        response_json = json.dumps(aws_response, indent=2)
        aws_data      = json.loads(response_json)
    except json.JSONDecodeError as e:
        return {
            "statusCode": 500,
            "body": f"Error parsing JSON response: {str(e)}"
        }

    # Extract information from the AWS response
    task_definition_arn = aws_data['Targets'][0]['EcsParameters']['TaskDefinitionArn']
    ecs_cluster_arn     = aws_data['Targets'][0]['Arn']
    subnet_ids          = aws_data['Targets'][0]['EcsParameters']['NetworkConfiguration']['awsvpcConfiguration']['Subnets']
    security_group_ids  = aws_data['Targets'][0]['EcsParameters']['NetworkConfiguration']['awsvpcConfiguration']['SecurityGroups']
    task_count          = aws_data['Targets'][0]['EcsParameters']['TaskCount']
    managed_tags        = aws_data['Targets'][0]['EcsParameters']['EnableECSManagedTags']
    execute_command     = aws_data['Targets'][0]['EcsParameters']['EnableExecuteCommand']
    
    # Trasnform multiple items in a list
    subnet_result = [subnet for subnet in subnet_ids]
    sg_result = [security_group for security_group in security_group_ids]

    # Create the skeleton for the ecs run task command 
    network_configuration = {
        'awsvpcConfiguration': {
            'subnets'       : subnet_result,
            'securityGroups': sg_result,
            'assignPublicIp': 'DISABLED'
        }
    }
    run_task_params = {
        'taskDefinition'      : task_definition_arn,
        'cluster'             : ecs_cluster_arn,
        'networkConfiguration': network_configuration,
        'launchType'          : 'FARGATE',
        'enableECSManagedTags': managed_tags,
        'enableExecuteCommand': execute_command,
        'count'               : task_count
    }

    # Create a Boto3 ECS client
    client_ecs = boto3.client('ecs')
    
    # Execute the S3 CLI command (modify as needed)
    try:
        aws_response  = client_ecs.run_task(**run_task_params)
        response_json = json.dumps(aws_response, indent=4, sort_keys=True, default=str)
        aws_data      = json.loads(response_json)
    except subprocess.CalledProcessError as e:
        return {
            "statusCode": 500,
            "body": f"Error executing ECS CLI command: {e.output.decode()}"
        }

    # Return a response with the results (modify as needed)
    return {
        "statusCode": 200,
        "body": f"Executed ECS run task with task ID:{task_definition_arn}. ECS response: {aws_data['ResponseMetadata']['HTTPStatusCode']}"
    }