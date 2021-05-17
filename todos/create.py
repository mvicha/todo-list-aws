import json
import logging
import os

import boto3
from todoTableClass import handler as todoTableClass

dynamodb = None
if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
    dynamodb = boto3.resource('dynamodb')


def create(event, context):
    data = json.loads(event['body'])
    if 'text' not in data:
        logging.error("Validation Failed")
        raise Exception("Couldn't create the todo item.")

    tdCreate = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                              dynamodb=dynamodb)
    item = tdCreate.put_todo(data['text'])

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item)
    }

    return response
