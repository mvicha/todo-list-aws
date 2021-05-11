import json
import time
import logging
import os

#from todos import decimalencoder
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass

dynamodb = None
if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
    dynamodb = boto3.resource('dynamodb')

def update(event, context):
    data = json.loads(event['body'])
    if 'text' not in data or 'checked' not in data:
        logging.error("Validation Failed")
        raise Exception("Couldn't update the todo item.")
        return

    tdUpdate = todoTableClass(table = os.environ['DYNAMODB_TABLE'], dynamodb = dynamodb)

    # update the todo in the database
    item = tdUpdate.update_todo(id = event['pathParameters']['id'], text = data['text'], checked = data['checked'])

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item['Attributes'], cls=decimalencoder.DecimalEncoder)
    }

    return response
