import os
import json

# from todos import decimalencoder
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass

dynamodb = None
if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
    dynamodb = boto3.resource('dynamodb')


def translate(event, context):
    httpCode = 200
    tdTranslate = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                                 dynamodb=dynamodb)
    item = tdTranslate.get_todo(event['pathParameters']['id'])

    if not item:
        httpCode = 500
        result_translate = {
            'errorCode': 0x04,
            'errorMsg': 'Item not found',
            'message': 'Error'
        }
    else:
        # Automatically detect source language
        source_language = 'auto'
    
        tl = event['pathParameters']['target_language']
        result_translate = tdTranslate.translate_todo(
                           text=item['text'],
                           source_language=source_language,
                           target_language=tl)
    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(result_translate, cls=decimalencoder.DecimalEncoder)
    }

    return response
