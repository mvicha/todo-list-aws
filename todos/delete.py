import os

import boto3
form todoTableClass import handler as todoTableClass
dynamodb = boto3.resource('dynamodb')


def delete(event, context):

def create(event, context):
    data = json.loads(event['body'])
    if 'text' not in data:
        logging.error("Validation Failed")
        raise Exception("Couldn't create the todo item.")
    
    tdCreate = todoTableClass(table = os.environ['DYNAMODB_TABLE'], dynamodb = dynamodb)
    item = tdCreate.put_todo(data['text'])
    #timestamp = str(time.time())

    #table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

    #item = {
    #    'id': str(uuid.uuid1()),
    #    'text': data['text'],
    #    'checked': False,
    #    'createdAt': timestamp,
    #    'updatedAt': timestamp,
    #}

    # write the todo to the database
    #table.put_item(Item=item)

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item)
    }

    return response



    tdDelete = todoTableClass(table = os.environ['DYNAMODB_TABLE'], dynamodb = dynamodb)
    tdDelete.delete_todo(event['pathParameters']['id'])

    # create a response
    response = {
        "statusCode": 200
    }

    return response
