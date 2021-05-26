import json
import logging
import os

import boto3
from todoTableClass import handler as todoTableClass

dynamodb = None
print(f"We are here: {os.environ['DYNAMODB_TABLE']}")
if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
    dynamodb = boto3.resource('dynamodb')


def create(event, context):
    httpCode = 500
    data = json.loads(event['body'])
    if 'text' not in data:
        logging.error("Validation Failed")
        item = {
            'errorCode': 0x02,
            'errorMsg': 'No text provided'
        }
    else:
        if data['text']:
            tdCreate = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                                      dynamodb=dynamodb)
            item = tdCreate.put_todo(data['text'])
            httpCode = 200
        else:
            item = {
                'errorCode': 0x03,
                'errorMsg': 'Provided text is an empty string',
                'message': 'Error'
            }

    # create a response
    response = {
        "statusCode": httpCode,
        "body": json.dumps(item)
    }

    return response
