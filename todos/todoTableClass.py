import boto3
from botocore.exceptions import ClientError
import time
import uuid

import json
import logging
import os
import decimalencoder



#def lambda_handler(event, context):
#    """Sample pure Lambda function
#
#    Parameters
#    ----------
#    event: dict, required
#        API Gateway Lambda Proxy Input Format
#
#        Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
#
#    context: object, required
#        Lambda Context runtime methods and attributes
#
#        Context doc: https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html
#
#    Returns
#    ------
#    API Gateway Lambda Proxy Output Format: dict
#
#        Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
#    """
#
#    if event['httpMethod'] == 'GET':
#        if event['resource'] == '/':
#            result = "LIST"
#        if event['resource'] == '/{id}':
#            result = "GET ID"
#        if event['resource'] == '/{id}/{target_language}':
#            result = "TRANSLATE ID"
#    else:
#        result = event
#    # try:
#    #     ip = requests.get("http://checkip.amazonaws.com/")
#    # except requests.RequestException as e:
#    #     # Send some context about this error to Lambda Logs
#    #     print(e)
#
#    #     raise e
#
#    return {
#        "statusCode": 200,
#        #"body": json.dumps({
#        #    "message": "hello world",
#        #    # "location": ip.text.replace("\n", "")
#        #}),
#        "body": json.dumps(result),
#    }


class handler(object):
    def __init__(self, table, dynamodb=None):
        self.tableName = table
        if not dynamodb:
            # In this case dynamodb is the name of the docker container
            # when all the containers are in the same network.
            dynamodb = boto3.resource(
                'dynamodb', endpoint_url='http://dynamodb:8000') 
        self.dynamodb = dynamodb

    def create_todo_table(self):
        table = self.dynamodb.create_table(
            TableName=self.tableName,
            KeySchema=[
                {
                    'AttributeName': 'id',
                    'KeyType': 'HASH'
                }
            ],
            AttributeDefinitions=[
                {
                    'AttributeName': 'id',
                    'AttributeType': 'S'
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 1,
                'WriteCapacityUnits': 1
            }
        )

        # Wait until the table exists.
        table.meta.client.get_waiter(
            'table_exists').wait(TableName=self.tableName)
        if (table.table_status != 'ACTIVE'):
            raise AssertionError()

        return table

    def delete_todo_table(self):
        table = self.dynamodb.Table(self.tableName)
        table.delete()

    def put_todo(self, text, id=None):
        timestamp = str(time.time())

        table = self.dynamodb.Table(self.tableName)

        item = {
            'id': str(uuid.uuid1()),
            'text': text,
            'checked': False,
            'createdAt': timestamp,
            'updatedAt': timestamp,
        }

        # write the todo to the database
        table.put_item(Item=item)

        return item

    def scan_todo(self):
        table = self.dynamodb.Table(self.tableName)

        # fetch all todos from the database
        result = table.scan()

        return result['Items']

    def get_todo(self, id):
        table = self.dynamodb.Table(self.tableName)

        result = table.get_item(
            Key={
                'id': id
            }
        )

        return result['Item']

    def translate_todo(self, text, target_language, source_language = 'auto'):
        client = boto3.client('translate')

        result = client.translate_text(Text=text,
                                        SourceLanguageCode=source_language,
                                        TargetLanguageCode=target_language)
        return result

    def update_todo(self, text, id, checked):
        timestamp = str(time.time())

        table = self.dynamodb.Table(self.tableName)

        result = table.update_item(
            Key={
                'id': id
            },
            ExpressionAttributeNames={
              '#todo_text': 'text',
            },
            ExpressionAttributeValues={
              ':text': text,
              ':checked': checked,
              ':updatedAt': timestamp,
            },
            UpdateExpression='SET #todo_text = :text, '
                             'checked = :checked, '
                             'updatedAt = :updatedAt',
            ReturnValues='ALL_NEW',
        )

        return result
    
    def delete_todo(self, id):
        table = self.dynamodb.Table(self.tableName)
        table.delete_item(
            Key={
                'id': event['pathParameters']['id']
            }
        )
