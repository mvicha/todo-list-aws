import os
import json

#from todos import decimalencoder
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass
dynamodb = boto3.resource('dynamodb')


def get(event, context):
    tdGet = todoTableClass(table = os.environ['DYNAMODB_TABLE'], dynamodb = dynamodb)
    item = tdGet.get_todo(event['pathParameters']['id'])

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item, cls=decimalencoder.DecimalEncoder)
    }

    return response

