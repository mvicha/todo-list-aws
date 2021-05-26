import os
import json

# from todos import decimalencoder
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass

dynamodb = None
if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
    dynamodb = boto3.resource('dynamodb')


def get(event, context):
    httpCode = 200
    tdGet = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                           dynamodb=dynamodb)
    item = tdGet.get_todo(event['pathParameters']['id'])

    if not item:
        httpCode = 500
        item = {
            'errorCode': 0x04,
            'errorMsg': 'Item not found',
            'message': 'Error'
        }

    # create a response
    response = {
        "statusCode": httpCode,
        "body": json.dumps(item, cls=decimalencoder.DecimalEncoder)
    }

    return response
