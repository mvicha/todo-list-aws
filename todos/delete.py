import os

import boto3
from todoTableClass import handler as todoTableClass
dynamodb = boto3.resource('dynamodb')

def delete(event, context):
    tdDelete = todoTableClass(table = os.environ['DYNAMODB_TABLE'], dynamodb = dynamodb)
    tdDelete.delete_todo(event['pathParameters']['id'])

    # create a response
    response = {
        "statusCode": 200
    }

    return response
