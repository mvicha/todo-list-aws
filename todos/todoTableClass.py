import boto3
# from botocore.exceptions import ClientError
import time
import uuid
import json

# import json
# import logging
# import os
# import decimalencoder

# from botocore.vendored import requests
from urllib3 import request


class handler(object):
    def __init__(self, table, dynamodb=None, create=None):
        print(f"table: {table}")
        self.tableName = table
        validate_todo_table = False
        if not dynamodb:
            # In this case dynamodb is the name of the docker container
            # when all the containers are in the same network.
            dynamodb = boto3.resource(
                       'dynamodb', endpoint_url='http://dynamo:8000',
                       region_name='us-east-1')
            if not create:
                validate_todo_table = True
        self.dynamodb = dynamodb

        if validate_todo_table:
            print("Going to validate table existance")
            self.validate_todo_table()

    # Function to validate if table exists
    def validate_todo_table(self):
        client = boto3.client(
                 'dynamodb', endpoint_url='http://dynamo:8000',
                 region_name='us-east-1')

        try:
            response = client.describe_table(TableName=self.tableName)

            return response
        except client.exceptions.ResourceNotFoundException:
            print("Create table")
            try:
                awsURL = "http://169.254.169.254/latest/meta-data/local-ipv4"
                localIPAddressURL = awsURL
                with request.urlopen(localIPAddressURL) as x:
                    localIPAddress = x.read().decode('utf-8')
                print(localIPAddress)
                createTableURL = "http://"
                createTableURL += {localIPAddress}
                createTableURL += ":8080/todos/createTable/"
                response = request.urlopen(createTableURL)
                return response
            except Exception as e:
                print("Exception: {}".format(e))
                return e

    def create_todo_table(self):
        try:
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
        except Exception as e:
            print("Create exception: {}".format(e))

        # Wait until the table exists.
        table.meta.client.get_waiter(
            'table_exists').wait(TableName=self.tableName)
        if (table.table_status != 'ACTIVE'):
            raise AssertionError()

        return table.table_status

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

    def translate_todo(self, text, target_language,
                       source_language='auto'):
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
        try:
            table = self.dynamodb.Table(self.tableName)
        except Exception as e:
            result = {
                'Items': json.dumps({
                    'errorCode': 0x01,
                    'errorMsg': 'Unable to select table',
                    'errorException': e
                })
            }
            httpCode = 500

        if httpCode != 500:
            try:
                table.delete_item(
                    Key={
                        'id': id
                    }
                )
                httpCode = 200
                result = {
                    'Items': json.dumps({
                        'errorCode': 0x00,
                        'errorMsg': 'Todo item deleted successfully'
                    })
                }
            except Exception as e:
                httpCode = 500
                result = {
                    'Items': json.dumps({
                        'errorCode': 0x15,
                        'errorMsg': 'Unable to delete todo item',
                        'errorException': e
                    })
                }

        response = {
            "statusCode": httpCode,
            "body": json.dumps(result)
        }
        return response
