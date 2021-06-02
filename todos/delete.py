import os

import boto3
from todoTableClass import handler as todoTableClass

if os.environ['ENVIRONMENT'] == 'local':
    dynamodb = None
else:
    dynamodb = boto3.resource('dynamodb')


def delete(event, context):
    tdDelete = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                              dynamodb=dynamodb)

    item = tdDelete.get_todo(event['pathParameters']['id'])

    if not item:
        item = {
            "statusCode": 500,
        }
    else:
        item = tdDelete.delete_todo(event['pathParameters']['id'])

    # create a response
    return item
