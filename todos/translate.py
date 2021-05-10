import os
import json

from todos import decimalencoder
import boto3

# Setup translate
client = boto3.client('translate')
dynamodb = boto3.resource('dynamodb')


def translate(event, context):
    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])
    # Automatically detect source language
    source_language = 'auto'

    if 'target_language' in event['pathParameters'] and 'id' in event['pathParameters']:
        # Create a variable with the URL id parameter
        todo_id = event['pathParameters']['id']
        # Create a variable with the URL target language
        target_language = event['pathParameters']['target_language']

        try:
            # fetch todo from the database
            text_result = table.get_item(
                Key={
                    'id': todo_id
                }
            )
        except Exception as e:
            raise Exception("[ErrorMessage]: ID not found - " + str(e))

        try:
            result = client.translate_text(Text=text_result['Item']['text'],
                                            SourceLanguageCode=source_language,
                                            TargetLanguageCode=target_language)
            # Replace text if original text differes to translated text
            if text_result['Item']['text'] != result['TranslatedText']:
              text_result['Item']['text'] = result['TranslatedText']
        except Exception as e:
            raise Exception("[ErrorMessage]: Not able to translate_text - " + str(e))

        # create a response
        response = {
            "statusCode": 200,
            "body": json.dumps(text_result['Item'],
                               cls=decimalencoder.DecimalEncoder)
        }

        return response
    else:
        raise Exception("[ErrorMessage]: Invalid input ")

