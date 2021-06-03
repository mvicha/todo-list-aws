import json
import os
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass

print(f'DyanmoDB Table es: {os.environ["DYNAMODB_TABLE"]}')

if os.environ['ENVIRONMENT'] == 'local':
    dynamodb = None
else:
    dynamodb = boto3.resource('dynamodb')


def list(event, context):
    tdList = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                            dynamodb=dynamodb)
    item = tdList.scan_todo()

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item, cls=decimalencoder.DecimalEncoder)
    }

    return response
