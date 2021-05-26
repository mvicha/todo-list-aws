import json
# import time
import logging
import os

# from todos import decimalencoder
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass

dynamodb = None
if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
    dynamodb = boto3.resource('dynamodb')


def update(event, context):
    httpCode = 200

    data = json.loads(event['body'])

    if 'text' not in data or 'checked' not in data:
        logging.error("Validation Failed")
        httpCode = 500
        returnItem = {
            'errorCode': 0x05,
            'errorMsg': 'No text or no checked provided',
            'message': 'Error'
        }
    else:
        if not data['text']:
            httpCode = 500
            returnItem = {
                'errorCode': 0x06,
                'errorMsg': 'Text is empty',
                'message': 'Error'
            }
        else:
            tdUpdate = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                                      dynamodb=dynamodb)
            item = tdUpdate.get_todo(event['pathParameters']['id'])

            if not item:
                httpCode = 500
                returnItem = {
                    'errorCode': 0x04,
                    'errorMsg': 'Item not found',
                    'message': 'Error'
                }
            else:
                # update the todo in the database
                item = tdUpdate.update_todo(
                       id=event['pathParameters']['id'],
                       text=data['text'],
                       checked=data['checked'])
                httpCode = 200
                returnItem = item['Attributes']

    # create a response
    response = {
        "statusCode": httpCode,
        "body": json.dumps(returnItem,
                           cls=decimalencoder.DecimalEncoder)
    }

    return response
