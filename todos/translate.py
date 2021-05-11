import os
import json

#from todos import decimalencoder
import decimalencoder
import boto3
from todoTableClass import handler as todoTableClass

dynamodb = boto3.resource('dynamodb')

def translate(event, context):
    tdTranslate = todoTableClass(table = os.environ['DYNAMODB_TABLE'], dynamodb = dynamodb)
    item = tdTranslate.get_todo(event['pathParameters']['id'])

    # Automatically detect source language
    source_language = 'auto'

    result_translate = tdTranslate.translate_todo(text = item['text'], source_language = source_language, target_language = event['pathParameters']['target_language'])
    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(result_translate, cls=decimalencoder.DecimalEncoder)
    }

    return response

